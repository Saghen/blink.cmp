--- @class blink.cmp.CompletionRenderContext
--- @field item blink.cmp.CompletionItem
--- @field label string
--- @field kind string
--- @field kind_icon string
--- @field icon_gap string
--- @field deprecated boolean
--- @field match string

--- @alias blink.cmp.CompletionDrawFn fun(ctx: blink.cmp.CompletionRenderContext): blink.cmp.Component[]

--- @class blink.cmp.CompletionWindowEventTargets
--- @field on_open table<fun()>
--- @field on_close table<fun()>
--- @field on_position_update table<fun()>
--- @field on_select table<fun(item: blink.cmp.CompletionItem?, context: blink.cmp.Context)>

--- @class blink.cmp.CompletionWindow
--- @field win blink.cmp.Window
--- @field items blink.cmp.CompletionItem[]
--- @field rendered_items? blink.cmp.RenderedComponentTree[]
--- @field has_selected? boolean
--- @field auto_show boolean
--- @field context blink.cmp.Context?
--- @field event_targets blink.cmp.CompletionWindowEventTargets
---
--- @field setup fun(): blink.cmp.CompletionWindow
---
--- @field open_with_items fun(context: blink.cmp.CompletionRenderContext, items: blink.cmp.CompletionItem[])
--- @field open fun()
--- @field close fun()
--- @field listen_on_open fun(callback: fun())
--- @field listen_on_close fun(callback: fun())
---
--- @field update_position fun(context: blink.cmp.Context)
--- @field listen_on_position_update fun(callback: fun())
---
--- @field accept fun(): boolean?
---
--- @field select fun(line: number, skip_auto_insert?: boolean)
--- @field select_next fun(opts?: { skip_auto_insert?: boolean })
--- @field select_prev fun(opts?: { skip_auto_insert?: boolean })
--- @field get_selected_item fun(): blink.cmp.CompletionItem?
--- @field set_has_selected fun(selected: boolean)
--- @field listen_on_select fun(callback: fun(item: blink.cmp.CompletionItem?, context: blink.cmp.Context))
--- @field emit_on_select fun(item: blink.cmp.CompletionItem?, context: blink.cmp.Context)
---
--- @field draw fun()
--- @field get_draw_fn fun(): blink.cmp.CompletionDrawFn
--- @field draw_item_simple blink.cmp.CompletionDrawFn
--- @field draw_item_reversed blink.cmp.CompletionDrawFn
--- @field draw_item_minimal blink.cmp.CompletionDrawFn

local config = require('blink.cmp.config')
local utils = require('blink.cmp.utils')
local renderer = require('blink.cmp.windows.lib.render')
local text_edits_lib = require('blink.cmp.accept.text-edits')
local autocmp_config = config.windows.autocomplete

--- @type blink.cmp.CompletionWindow
--- @diagnostic disable-next-line: missing-fields
local autocomplete = {
  items = {},
  has_selected = nil,
  -- hack: ideally this doesn't get mutated by the public API
  auto_show = autocmp_config.auto_show,
  context = nil,
  event_targets = {
    on_position_update = {},
    on_select = {},
    on_close = {},
    on_open = {},
  },
}

function autocomplete.setup()
  autocomplete.win = require('blink.cmp.windows.lib').new({
    min_width = autocmp_config.min_width,
    max_height = autocmp_config.max_height,
    border = autocmp_config.border,
    winhighlight = autocmp_config.winhighlight,
    cursorline = false,
    scrolloff = autocmp_config.scrolloff,
  })

  -- Setting highlights is slow and we update on every keystroke so we instead use a decoration provider
  -- which will only render highlights of the visible lines. This also avoids having to do virtual scroll
  -- like nvim-cmp does, which breaks on UIs like neovide
  vim.api.nvim_set_decoration_provider(config.highlight.ns, {
    on_win = function(_, winnr, bufnr)
      return autocomplete.win:get_win() == winnr and bufnr == autocomplete.win:get_buf()
    end,
    on_line = function(_, _, bufnr, line_number)
      local rendered_item = autocomplete.rendered_items[line_number + 1]
      if rendered_item == nil then return end
      renderer.draw_highlights(rendered_item, bufnr, config.highlight.ns, line_number)
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'WinScrolled', 'WinResized' }, {
    callback = function()
      if autocomplete.context ~= nil then autocomplete.update_position(autocomplete.context) end
    end,
  })

  -- prefetch the resolved item
  local last_context_id = nil
  local last_request = nil
  local timer = vim.uv.new_timer()
  autocomplete.listen_on_select(function(item, context)
    if not item then return end

    local resolve = vim.schedule_wrap(function()
      if last_request ~= nil then last_request:cancel() end
      last_request = require('blink.cmp.sources.lib').resolve(item)
    end)

    -- immediately resolve if the context has changed
    if last_context_id ~= context.id then
      last_context_id = context.id
      resolve()
    end

    -- otherwise, wait for the debounce period
    timer:stop()
    timer:start(50, 0, resolve)
  end)

  return autocomplete
end

---------- Visibility ----------

--- @param context blink.cmp.Context
--- @param items blink.cmp.CompletionItem[]
function autocomplete.open_with_items(context, items)
  autocomplete.context = context
  autocomplete.items = items
  autocomplete.draw()

  vim.iter(autocomplete.event_targets.on_open):each(function(callback) callback() end)

  if not autocomplete.auto_show then return end
  autocomplete.win:open()

  autocomplete.update_position(context)
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })

  autocomplete.emit_on_select(autocomplete.get_selected_item(), context)
end

function autocomplete.open()
  if autocomplete.win:is_open() then return end
  vim.iter(autocomplete.event_targets.on_open):each(function(callback) callback() end)
  autocomplete.win:open()
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')
end

function autocomplete.close()
  if not autocomplete.win:is_open() then return end
  autocomplete.auto_show = autocmp_config.auto_show
  autocomplete.win:close()
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')

  vim.iter(autocomplete.event_targets.on_close):each(function(callback) callback() end)
end

--- Add a listener for when the autocomplete window opens
--- This is useful for hiding GitHub Copilot ghost text and similar functionality.
function autocomplete.listen_on_open(callback) table.insert(autocomplete.event_targets.on_open, callback) end

--- Add a listener for when the autocomplete window closes
function autocomplete.listen_on_close(callback) table.insert(autocomplete.event_targets.on_close, callback) end

--- TODO: Don't switch directions if the context is the same
function autocomplete.update_position(context)
  local win = autocomplete.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local border_size = win:get_border_size()
  local pos = win:get_vertical_direction_and_height(autocmp_config.direction_priority)

  -- couldn't find anywhere to place the window
  if not pos then
    win:close()
    return
  end

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local col = context.bounds.start_col - cursor_col - (context.bounds.length == 0 and 0 or 1)
  local row = pos.direction == 's' and 1 or -pos.height - border_size.vertical
  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col - 1 })
  vim.api.nvim_win_set_height(winnr, pos.height)

  for _, callback in ipairs(autocomplete.event_targets.on_position_update) do
    callback()
  end
end

function autocomplete.listen_on_position_update(callback)
  table.insert(autocomplete.event_targets.on_position_update, callback)
end

---------- Selection/Accept ----------

function autocomplete.accept()
  local selected_item = autocomplete.get_selected_item()
  if selected_item == nil then return end

  -- undo the preview if it exists
  if autocomplete.preview_text_edit ~= nil and autocomplete.preview_context_id == autocomplete.context.id then
    text_edits_lib.undo_text_edit(autocomplete.preview_text_edit)
  end

  -- apply
  require('blink.cmp.accept')(selected_item)
  return true
end

function autocomplete.select(line, skip_auto_insert)
  autocomplete.set_has_selected(true)
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { line, 0 })

  local selected_item = autocomplete.get_selected_item()

  -- when auto_insert is enabled, we immediately apply the text edit
  if config.windows.autocomplete.selection == 'auto_insert' and selected_item ~= nil and not skip_auto_insert then
    require('blink.cmp.trigger.completion').suppress_events_for_callback(function()
      if autocomplete.preview_context_id ~= autocomplete.context.id then autocomplete.preview_text_edit = nil end
      autocomplete.preview_text_edit =
        require('blink.cmp.accept.preview')(selected_item, autocomplete.preview_text_edit)
      autocomplete.preview_context_id = autocomplete.context.id
    end)
  end

  autocomplete.emit_on_select(selected_item, autocomplete.context)
end

function autocomplete.select_next(opts)
  if not autocomplete.win:is_open() then return end

  local cycle_from_bottom = config.windows.autocomplete.cycle.from_bottom
  local l = #autocomplete.items
  local line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  -- We need to ajust the disconnect between the line position
  -- on the window and the selected item
  if not autocomplete.has_selected then line = line - 1 end
  if autocomplete.has_selected and l == 1 then return end
  if line == l then
    -- at the end of completion list and the config is not enabled: do nothing
    if not cycle_from_bottom then return end
    line = 1
  else
    line = line + 1
  end

  autocomplete.select(line, opts and opts.skip_auto_insert)
end

function autocomplete.select_prev(opts)
  if not autocomplete.win:is_open() then return end

  local cycle_from_top = config.windows.autocomplete.cycle.from_top
  local l = #autocomplete.items
  local line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  if autocomplete.has_selected and l == 1 then return end
  if line <= 1 then
    if not cycle_from_top then return end
    line = l
  else
    line = line - 1
  end

  autocomplete.select(line, opts and opts.skip_auto_insert)
end

function autocomplete.get_selected_item()
  if not autocomplete.win:is_open() then return end
  if not autocomplete.has_selected then return end
  local line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  return autocomplete.items[line]
end

function autocomplete.set_has_selected(selected)
  if not autocomplete.win:is_open() then return end
  autocomplete.has_selected = selected
  autocomplete.win:set_option_value('cursorline', selected)
end

function autocomplete.listen_on_select(callback) table.insert(autocomplete.event_targets.on_select, callback) end

function autocomplete.emit_on_select(item, context)
  for _, callback in ipairs(autocomplete.event_targets.on_select) do
    callback(item, context)
  end
end

---------- Rendering ----------

function autocomplete.draw()
  local draw_fn = autocomplete.get_draw_fn()
  local icon_gap = config.nerd_font_variant == 'mono' and ' ' or '  '
  local components_list = {}
  local match =
    autocomplete.context.line:sub(autocomplete.context.bounds.start_col, autocomplete.context.bounds.end_col)
  for _, item in ipairs(autocomplete.items) do
    local kind = require('blink.cmp.types').CompletionItemKind[item.kind] or 'Unknown'
    local kind_icon = config.kind_icons[kind] or config.kind_icons.Field
    -- Some LSPs can return labels with newlines.
    -- Escape them to avoid errors in nvim_buf_set_lines when rendering the autocomplete menu.
    local label = item.label:gsub('\n', '\\n')
    if config.nerd_font_variant == 'normal' then label = label:gsub('…', '… ') end

    table.insert(
      components_list,
      draw_fn({
        item = item,
        match = label:find(match, 1, true) and match or '',
        label = label,
        kind = kind,
        kind_icon = kind_icon,
        icon_gap = icon_gap,
        deprecated = item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) or false,
      })
    )
  end

  local max_lengths = renderer.get_max_lengths(components_list, autocmp_config.min_width)
  autocomplete.rendered_items = vim.tbl_map(
    function(component) return renderer.render(component, max_lengths) end,
    components_list
  )

  local lines = vim.tbl_map(function(rendered) return rendered.text end, autocomplete.rendered_items)
  local bufnr = autocomplete.win:get_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
end

function autocomplete.get_draw_fn()
  if type(autocmp_config.draw) == 'function' then
    return autocmp_config.draw
  elseif autocmp_config.draw == 'simple' then
    return autocomplete.draw_item_simple
  elseif autocmp_config.draw == 'reversed' then
    return autocomplete.draw_item_reversed
  elseif autocmp_config.draw == 'minimal' then
    return autocomplete.draw_item_minimal
  end
  error('Invalid autocomplete window draw config')
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.draw_item_simple(ctx)
  return {
    ' ',
    {
      ctx.kind_icon,
      ctx.icon_gap,
      hl_group = utils.try_get_tailwind_hl(ctx) or ('BlinkCmpKind' .. ctx.kind),
    },
    {
      ctx.label,
      ctx.kind == 'Snippet' and '~' or '',
      (ctx.item.labelDetails and ctx.item.labelDetails.detail) and ctx.item.labelDetails.detail or '',
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 80,
      highlights = {
        { start = 0, stop = #ctx.match, group = 'BlinkCmpLabelMatch' },
      },
    },
    ' ',
  }
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.draw_item_reversed(ctx)
  return {
    ' ',
    {
      ctx.label,
      ctx.kind == 'Snippet' and '~' or nil,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 50,
      highlights = {
        { start = 0, stop = #ctx.match, group = 'BlinkCmpLabelMatch' },
      },
    },
    ' ',
    {
      ctx.kind_icon,
      ctx.icon_gap,
      ctx.kind,
      hl_group = utils.try_get_tailwind_hl(ctx) or ('BlinkCmpKind' .. ctx.kind),
    },
    ' ',
  }
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.draw_item_minimal(ctx)
  return {
    ' ',
    {
      ctx.label,
      ctx.kind == 'Snippet' and '~' or nil,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 50,
      highlights = {
        { start = 0, stop = #ctx.match, group = 'BlinkCmpLabelMatch' },
      },
    },
    ' ',
    {
      ctx.kind,
      hl_group = utils.try_get_tailwind_hl(ctx) or ('BlinkCmpKind' .. ctx.kind),
    },
    ' ',
  }
end

return autocomplete
