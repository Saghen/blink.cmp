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
  open_emitter = require('blink.cmp.lib.event_emitter').new('completion_menu_open', 'BlinkCmpMenuOpen'),
  close_emitter = require('blink.cmp.lib.event_emitter').new('completion_menu_close', 'BlinkCmpMenuClose'),
  position_update_emitter = require('blink.cmp.lib.event_emitter').new(
    'completion_menu_position_update',
    'BlinkCmpMenuPositionUpdate'
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
  menu.renderer:draw(context, menu.win:get_buf(), items, config.draw)

  local auto_show = menu.auto_show
  if type(auto_show) == 'function' then auto_show = auto_show(context, items) end
  if auto_show then
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
end

function menu.set_selected_item_idx(idx)
  menu.win:set_option_value('cursorline', idx ~= nil)
  menu.selected_item_idx = idx
  if menu.win:is_open() then menu.win:set_cursor({ idx or 1, 0 }) end
end

--- TODO: Don't switch directions if the context is the same
function menu.update_position()
  local context = menu.context
  if context == nil then return end

  local win = menu.win
  if not win:is_open() then return end

  win:update_size()

  local border_size = win:get_border_size()
  local pos = win:get_vertical_direction_and_height(config.direction_priority)

  -- couldn't find anywhere to place the window
  if not pos then
    win:close()
    return
  end

  local alignment_start_col = menu.renderer:get_alignment_start_col()

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local row = pos.direction == 's' and 1 or -pos.height - border_size.vertical

  if vim.api.nvim_get_mode().mode == 'c' then
    local cmdline_position = config.cmdline_position()
    win:set_win_config({
      relative = 'editor',
      row = cmdline_position[1] + row,
      col = math.max(cmdline_position[2] + context.bounds.start_col - alignment_start_col, 0),
    })
  else
    local cursor_col = context.get_cursor()[2]

    local col = context.bounds.start_col - alignment_start_col - cursor_col - 1 - border_size.left
    if config.draw.align_to == 'cursor' then col = 0 end

    win:set_win_config({ relative = 'cursor', row = row, col = col })
  end

  win:set_height(pos.height)

  menu.position_update_emitter:emit()
end

return menu
