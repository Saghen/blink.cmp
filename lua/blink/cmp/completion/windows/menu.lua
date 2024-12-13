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
--- @field redraw_if_needed fun()

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
    filetype = 'blink-cmp-menu',
  }),
  items = {},
  context = nil,
  auto_show = config.auto_show,
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

function menu.open_with_items(context, items)
  menu.context = context
  menu.items = items
  menu.selected_item_idx = menu.selected_item_idx ~= nil and math.min(menu.selected_item_idx, #items) or nil

  if not menu.renderer then menu.renderer = require('blink.cmp.completion.windows.render').new(config.draw) end
  menu.renderer:draw(context, menu.win:get_buf(), items)

  if menu.auto_show then
    menu.open()
    menu.update_position()
  end
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
  menu.auto_show = config.auto_show
  if not menu.win:is_open() then return end

  menu.win:close()
  menu.close_emitter:emit()
  menu.redraw_if_needed()
end

function menu.set_selected_item_idx(idx)
  menu.win:set_option_value('cursorline', idx ~= nil)
  menu.selected_item_idx = idx
  if menu.win:is_open() then
    vim.api.nvim_win_set_cursor(menu.win:get_win(), { idx or 1, 0 })
    menu.redraw_if_needed()
  end
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
  local row = pos.direction == 's' and 1 or -pos.height - border_size.vertical

  if vim.api.nvim_get_mode().mode == 'c' then
    local cmdline_position = config.cmdline_position()
    vim.api.nvim_win_set_config(winnr, {
      relative = 'editor',
      row = cmdline_position[1] + row,
      col = math.max(cmdline_position[2] + context.bounds.start_col - start_col, 0),
    })
  else
    local cursor_col = context.get_cursor()[2]
    local col = context.bounds.start_col - cursor_col - (context.bounds.length == 0 and 0 or 1) - border_size.left
    vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col - start_col })
  end

  vim.api.nvim_win_set_height(winnr, pos.height)
  if win.scrollbar then win.scrollbar:update(winnr) end

  menu.position_update_emitter:emit()
  menu.redraw_if_needed()
end

local redraw_queued = false
--- In cmdline mode, the window won't be redrawn automatically so we redraw ourselves on schedule
function menu.redraw_if_needed()
  if vim.api.nvim_get_mode().mode ~= 'c' or menu.win:get_win() == nil then return end
  if redraw_queued then return end

  -- We redraw on schedule to avoid the cmdline disappearing during redraw
  -- and to batch multiple redraws together
  redraw_queued = true
  vim.schedule(function()
    redraw_queued = false
    vim.api.nvim__redraw({ win = menu.win:get_win(), flush = true })
  end)
end

return menu
