--- @class blink.cmp.CompletionRenderContext
--- @field item blink.cmp.CompletionItem
--- @field label string
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
  -- hack: ideally this doesn't get mutated by the public API
  auto_show = autocmp_config.auto_show,
  ---@type blink.cmp.Context?
  context = nil,
  event_targets = {
    on_position_update = {},
    --- @type table<fun(item: blink.cmp.CompletionItem?, context: blink.cmp.Context)>
    on_select = {},
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
    on_win = function(_, win, buf, top, bot)
      if autocomplete.win:get_win() == nil or buf == autocomplete.win:get_buf() == nil then return false end
      if autocomplete.win:get_win() ~= win or buf ~= autocomplete.win:get_buf() then return false end

      for i = top, bot do
        local input = vim.api.nvim_get_current_line()

        local current_buf = vim.api.nvim_win_get_buf(autocomplete.win:get_win())
        local buf_content = vim.api.nvim_buf_get_lines(current_buf, 0, vim.api.nvim_buf_line_count(current_buf), false)
        local input_start_col = autocomplete.context.bounds.start_col

        local current_buf_content = buf_content[i + 1]:lower()
        local inputMatchIndex = string.find(current_buf_content, string.sub(input, input_start_col):lower())

        if inputMatchIndex == nil then
          inputMatchIndex = string.find(current_buf_content, input:lower():gsub('%s+', ''))
        end

        local inputNonWord = string.match(input, '%.(.*)')

        -- Making sure that symbols like dot, comma and space doesn't break it
        if inputNonWord == nil then inputNonWord = string.match(input, '%:(.*)') end
        if inputNonWord == nil then inputNonWord = string.match(input, '[^%s+]+(.*)') end
        if inputMatchIndex == nil then
          if inputNonWord == nil or inputNonWord == '' then return false end
        end

        -- skip to next section of the label e.g. if input is "net.buddy", it will match "buddy" instead
        if inputMatchIndex == nil and inputNonWord ~= nil then
          if string.match(inputNonWord, '.') then
            input = inputNonWord
            inputMatchIndex = string.find(current_buf_content, inputNonWord:lower())
          end
        end

        -- only highlight if we have a match
        if inputMatchIndex then
          vim.api.nvim_buf_set_extmark(buf, config.highlight.ns, i, inputMatchIndex - 1, {
            end_row = i,
            end_col = string.len(string.sub(input, autocomplete.context.bounds.start_col)) + inputMatchIndex - 1,
            hl_group = 'BlinkCmpLabelMatch',
            hl_mode = 'combine',
            ephemeral = true,
          })
        end
      end
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

  autocomplete.on_select_callbacks(autocomplete.get_selected_item(), context)
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
  local cursor_screen_position = win.get_cursor_screen_position()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_col = cursor[2]

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local col = context.bounds.start_col - cursor_col - (context.bounds.start_col == 0 and 0 or 1)

  -- detect if there's space above/below the cursor
  -- todo: should pick the largest space if both are false and limit height of the window
  local is_space_below = cursor_screen_position.distance_from_bottom > height
  local is_space_above = cursor_screen_position.distance_from_top > height

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

--- @param line number
--- @param skip_auto_insert? boolean
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

  autocomplete.on_select_callbacks(selected_item, autocomplete.context)
end

--- @params opts? { skip_auto_insert?: boolean }
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

--- @params opts? { skip_auto_insert?: boolean }
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

function autocomplete.listen_on_select(callback) table.insert(autocomplete.event_targets.on_select, callback) end

--- @param item? blink.cmp.CompletionItem
--- @param context blink.cmp.Context
function autocomplete.on_select_callbacks(item, context)
  for _, callback in ipairs(autocomplete.event_targets.on_select) do
    callback(item, context)
  end
end

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
    -- Some LSPs can return labels with newlines.
    -- Escape them to avoid errors in nvim_buf_set_lines when rendering the autocomplete menu.
    local label = item.label:gsub('\n', '\\n')
    if config.nerd_font_variant == 'normal' then label = label:gsub('…', '… ') end

    table.insert(
      components_list,
      draw_fn({
        item = item,
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
      ctx.label,
      ctx.kind == 'Snippet' and '~' or '',
      (ctx.item.labelDetails and ctx.item.labelDetails.detail) and ctx.item.labelDetails.detail or '',
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
      max_width = 80,
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
      ctx.label,
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
      ctx.label,
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
