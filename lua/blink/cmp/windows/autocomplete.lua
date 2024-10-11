--- @class blink.cmp.CompletionRenderContext
--- @field item blink.cmp.CompletionItem
--- @field kind string
--- @field kind_icon string
--- @field icon_gap string
--- @field deprecated boolean

local config = require('blink.cmp.config')
local renderer = require('blink.cmp.windows.lib.render')
local text_edits_lib = require('blink.cmp.accept.text-edits')
local autocmp_config = config.windows.autocomplete
local autocomplete = {
  ---@type blink.cmp.CompletionItem[]
  items = {},
  has_selected = nil,
  ---@type blink.cmp.Context?
  context = nil,
  event_targets = {
    on_position_update = {},
    --- @type fun(item: blink.cmp.CompletionItem?, context: blink.cmp.Context)
    on_select = function() end,
    --- @type table<fun()>
    on_close = {},
    --- @type table<fun()>
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
      if autocomplete.context == nil then return end
      autocomplete.update_position(autocomplete.context)
    end,
  })

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

  autocomplete.win:open()

  autocomplete.context = context
  autocomplete.update_position(context)
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item(), context)
end

function autocomplete.open()
  if autocomplete.win:is_open() then return end
  vim.iter(autocomplete.event_targets.on_open):each(function(callback) callback() end)
  autocomplete.win:open()
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')
end

function autocomplete.close()
  if not autocomplete.win:is_open() then return end
  autocomplete.win:close()
  autocomplete.set_has_selected(autocmp_config.selection == 'preselect')

  vim.iter(autocomplete.event_targets.on_close):each(function(callback) callback() end)
end

--- Add a listener for when the autocomplete window closes
--- @param callback fun()
function autocomplete.listen_on_close(callback) table.insert(autocomplete.event_targets.on_close, callback) end

--- Add a listener for when the autocomplete window opens
--- This is useful for hiding GitHub Copilot ghost text and similar functionality.
---
--- @param callback fun()
function autocomplete.listen_on_open(callback) table.insert(autocomplete.event_targets.on_open, callback) end

--- @param context blink.cmp.Context
--- TODO: Don't switch directions if the context is the same
function autocomplete.update_position(context)
  local win = autocomplete.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local height = win:get_height()
  local screen_height = vim.api.nvim_win_get_height(0)
  local screen_scroll_range = win.get_screen_scroll_range()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1]
  local cursor_col = cursor[2]

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local col = context.bounds.start_col - cursor_col - (context.bounds.start_col == 0 and 0 or 1)

  -- detect if there's space above/below the cursor
  -- todo: should pick the largest space if both are false and limit height of the window
  local is_space_below = screen_height - (cursor_row - screen_scroll_range.start_line) > height
  local is_space_above = cursor_row - screen_scroll_range.start_line > height

  -- default to the user's preference but attempt to use the other options
  local row = autocmp_config.direction_priority[1] == 's' and 1 or -height
  for _, direction in ipairs(autocmp_config.direction_priority) do
    if direction == 's' and is_space_below then
      row = 1
      break
    elseif direction == 'n' and is_space_above then
      row = -height
      break
    end
  end

  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col })

  for _, callback in ipairs(autocomplete.event_targets.on_position_update) do
    callback()
  end
end

function autocomplete.listen_on_position_update(callback)
  table.insert(autocomplete.event_targets.on_position_update, callback)
end

---------- Selection ----------

--- @param line number
local function select(line)
  local prev_selected_item = autocomplete.get_selected_item()

  autocomplete.set_has_selected(true)
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { line, 0 })

  local selected_item = autocomplete.get_selected_item()

  -- when auto_insert is enabled, we immediately apply the text edit
  -- todo: move this to the accept module
  if config.windows.autocomplete.selection == 'auto_insert' and selected_item ~= nil then
    require('blink.cmp.trigger.completion').suppress_events_for_callback(function()
      local text_edit = text_edits_lib.get_from_item(selected_item)

      if selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
        text_edit.newText = selected_item.label
      end

      if
        prev_selected_item ~= nil and prev_selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet
      then
        local current_col = vim.api.nvim_win_get_cursor(0)[2]
        text_edit.range.start.character = current_col - #prev_selected_item.label
      end

      text_edits_lib.apply_text_edits(selected_item.client_id, { text_edit })
      vim.api.nvim_win_set_cursor(0, {
        text_edit.range.start.line + 1,
        text_edit.range.start.character + #text_edit.newText,
      })
    end)
  end

  autocomplete.event_targets.on_select(selected_item, autocomplete.context)
end

function autocomplete.select_next()
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

  select(line)
end

function autocomplete.select_prev()
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

  select(line)
end

function autocomplete.listen_on_select(callback) autocomplete.event_targets.on_select = callback end

---------- Rendering ----------

function autocomplete.set_has_selected(selected)
  if not autocomplete.win:is_open() then return end
  autocomplete.has_selected = selected
  autocomplete.win:set_option_values('cursorline', selected)
end

function autocomplete.draw()
  local draw_fn = autocomplete.get_draw_fn()
  local icon_gap = config.nerd_font_variant == 'mono' and ' ' or '  '
  local components_list = {}
  for _, item in ipairs(autocomplete.items) do
    local kind = require('blink.cmp.types').CompletionItemKind[item.kind] or 'Unknown'
    local kind_icon = config.kind_icons[kind] or config.kind_icons.Field

    table.insert(
      components_list,
      draw_fn({
        item = item,
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
    return autocomplete.render_item_simple
  elseif autocmp_config.draw == 'reversed' then
    return autocomplete.render_item_reversed
  elseif autocmp_config.draw == 'minimal' then
    return autocomplete.render_item_minimal
  end
  error('Invalid autocomplete window draw config')
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.render_item_simple(ctx)
  return {
    ' ',
    { ctx.kind_icon, ctx.icon_gap, hl_group = 'BlinkCmpKind' .. ctx.kind },
    {
      ctx.item.label,
      ctx.kind == 'Snippet' and '~' or nil,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 50,
    },
    ' ',
  }
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.render_item_reversed(ctx)
  return {
    ' ',
    {
      ctx.item.label,
      ctx.kind == 'Snippet' and '~' or nil,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 50,
    },
    ' ',
    { ctx.kind_icon, ctx.icon_gap, ctx.kind, hl_group = 'BlinkCmpKind' .. ctx.kind },
    ' ',
  }
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.render_item_minimal(ctx)
  return {
    ' ',
    {
      ctx.item.label,
      ctx.kind == 'Snippet' and '~' or nil,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 50,
    },
    ' ',
    { ctx.kind, hl_group = 'BlinkCmpKind' .. ctx.kind },
    ' ',
  }
end

---@return blink.cmp.CompletionItem?
function autocomplete.get_selected_item()
  if not autocomplete.win:is_open() then return end
  if not autocomplete.has_selected then return end
  local line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  return autocomplete.items[line]
end

return autocomplete
