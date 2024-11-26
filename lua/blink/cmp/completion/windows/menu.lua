--- @class blink.cmp.CompletionMenu
--- @field win blink.cmp.Window
--- @field items blink.cmp.CompletionItem[]
--- @field renderer blink.cmp.Renderer
--- @field selected_item_idx? number
--- @field context blink.cmp.Context?
---
--- @field open_with_items fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[])
--- @field open fun()
--- @field close fun()
--- @field set_selected_item_idx fun(idx?: number)
--- @field update_position fun()

local config = require('blink.cmp.config').completion.window

--- @type blink.cmp.CompletionMenu
--- @diagnostic disable-next-line: missing-fields
local autocomplete = {
  items = {},
  context = nil,
  position_update_emitter = require('blink.cmp.lib.event_emitter').new(
    'completion_window_position_update',
    'BlinkCmpCompletionWindowPositionUpdate'
  ),
  close_emitter = require('blink.cmp.lib.event_emitter').new(
    'completion_window_close',
    'BlinkCmpCompletionWindowClose'
  ),
  open_emitter = require('blink.cmp.lib.event_emitter').new('completion_window_open', 'BlinkCmpCompletionWindowOpen'),
  win = require('blink.cmp.lib.window').new({
    min_width = config.min_width,
    max_height = config.max_height,
    border = config.border,
    winblend = config.winblend,
    winhighlight = config.winhighlight,
    cursorline = false,
    scrolloff = config.scrolloff,
    scrollbar = config.scrollbar,
  }),
}

vim.api.nvim_create_autocmd({ 'CursorMovedI', 'WinScrolled', 'WinResized' }, {
  callback = function() autocomplete.update_position() end,
})

---------- Visibility ----------

--- @param context blink.cmp.Context
--- @param items blink.cmp.CompletionItem[]
function autocomplete.open_with_items(context, items)
  autocomplete.context = context
  autocomplete.items = items

  if not autocomplete.renderer then
    autocomplete.renderer = require('blink.cmp.completion.windows.render').new(config.draw)
  end
  autocomplete.renderer:draw(autocomplete.win:get_buf(), items)

  autocomplete.open()
  autocomplete.update_position()

  -- it's possible for the window to close after updating the position
  -- if there was nowhere to place the window
  if not autocomplete.win:is_open() then return end

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
end

function autocomplete.open()
  if autocomplete.win:is_open() then return end

  autocomplete.win:open()
  if autocomplete.selected_item_idx ~= nil then
    vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { autocomplete.selected_item_idx, 0 })
  end

  autocomplete.open_emitter:emit()
end

function autocomplete.close()
  if not autocomplete.win:is_open() then return end

  autocomplete.win:close()
  autocomplete.close_emitter:emit()
end

function autocomplete.set_selected_item_idx(idx)
  if idx == nil then autocomplete.win:set_option_value('cursorline', false) end
  autocomplete.win:set_option_value('cursorline', true)

  autocomplete.selected_item_idx = idx
  if autocomplete.win:is_open() then vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { idx, 0 }) end
end

--- TODO: Don't switch directions if the context is the same
function autocomplete.update_position()
  local context = autocomplete.context
  if context == nil then return end

  local win = autocomplete.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local border_size = win:get_border_size()
  local pos = win:get_vertical_direction_and_height(config.direction_priority)

  -- couldn't find anywhere to place the window
  if not pos then
    win:close()
    return
  end

  local start_col = autocomplete.renderer:get_alignment_start_col()

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local col = context.bounds.start_col - cursor_col - (context.bounds.length == 0 and 0 or 1) - border_size.left
  local row = pos.direction == 's' and 1 or -pos.height - border_size.vertical
  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col - start_col })
  vim.api.nvim_win_set_height(winnr, pos.height)

  autocomplete.position_update_emitter:emit()
end

return autocomplete
