--- @class blink.cmp.CompletionMenu
--- @field win blink.cmp.Window
--- @field items blink.cmp.CompletionItem[]
--- @field renderer blink.cmp.Renderer
--- @field selected_item_idx? number
--- @field context blink.cmp.Context?
--- @field open_emitter blink.cmp.EventEmitter<{}>
--- @field close_emitter blink.cmp.EventEmitter<{}>
--- @field position_update_emitter blink.cmp.EventEmitter<{}>
---
--- @field open_with_items fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[])
--- @field open fun()
--- @field close fun()
--- @field set_selected_item_idx fun(idx?: number)
--- @field update_position fun()

local config = require('blink.cmp.config').completion.menu

--- @type blink.cmp.CompletionMenu
--- @diagnostic disable-next-line: missing-fields
local menu = {
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
  items = {},
  context = nil,
  open_emitter = require('blink.cmp.lib.event_emitter').new('completion_menu_open', 'BlinkCmpCompletionMenuOpen'),
  close_emitter = require('blink.cmp.lib.event_emitter').new('completion_menu_close', 'BlinkCmpCompletionMenuClose'),
  position_update_emitter = require('blink.cmp.lib.event_emitter').new(
    'completion_menu_position_update',
    'BlinkCmpCompletionMenuPositionUpdate'
  ),
}

vim.api.nvim_create_autocmd({ 'CursorMovedI', 'WinScrolled', 'WinResized' }, {
  callback = function() menu.update_position() end,
})

--- @param context blink.cmp.Context
--- @param items blink.cmp.CompletionItem[]
function menu.open_with_items(context, items)
  menu.context = context
  menu.items = items

  if not menu.renderer then menu.renderer = require('blink.cmp.completion.windows.render').new(config.draw) end
  menu.renderer:draw(menu.win:get_buf(), items)

  menu.open()
  menu.update_position()

  -- it's possible for the window to close after updating the position
  -- if there was nowhere to place the window
  if not menu.win:is_open() then return end

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(menu.win:get_win(), { 1, 0 })
end

function menu.open()
  if menu.win:is_open() then return end

  menu.win:open()
  if menu.selected_item_idx ~= nil then
    vim.api.nvim_win_set_cursor(menu.win:get_win(), { menu.selected_item_idx, 0 })
  end

  menu.open_emitter:emit()
end

function menu.close()
  if not menu.win:is_open() then return end

  menu.win:close()
  menu.close_emitter:emit()
end

function menu.set_selected_item_idx(idx)
  if idx == nil then menu.win:set_option_value('cursorline', false) end
  menu.win:set_option_value('cursorline', true)

  menu.selected_item_idx = idx
  if menu.win:is_open() then vim.api.nvim_win_set_cursor(menu.win:get_win(), { idx, 0 }) end
end

--- TODO: Don't switch directions if the context is the same
function menu.update_position()
  local context = menu.context
  if context == nil then return end

  local win = menu.win
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

  local start_col = menu.renderer:get_alignment_start_col()

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local col = context.bounds.start_col - cursor_col - (context.bounds.length == 0 and 0 or 1) - border_size.left
  local row = pos.direction == 's' and 1 or -pos.height - border_size.vertical
  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col - start_col })
  vim.api.nvim_win_set_height(winnr, pos.height)

  menu.position_update_emitter:emit()
end

return menu
