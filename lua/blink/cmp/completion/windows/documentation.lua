--- @class blink.cmp.CompletionDocumentationWindow
--- @field win blink.cmp.Window
--- @field last_context_id? number
--- @field auto_show_timer uv_timer_t
--- @field shown_item? blink.cmp.CompletionItem
---
--- @field auto_show_item fun(item: blink.cmp.CompletionItem)
--- @field show_item fun(item: blink.cmp.CompletionItem)
--- @field update_position fun()
--- @field scroll_up fun(amount: number)
--- @field scroll_down fun(amount: number)
--- @field close fun()

local config = require('blink.cmp.config').completion.documentation
local win_config = config.window

local sources = require('blink.cmp.sources.lib')
local menu = require('blink.cmp.completion.windows.menu')

--- @type blink.cmp.CompletionDocumentationWindow
--- @diagnostic disable-next-line: missing-fields
local docs = {
  win = require('blink.cmp.lib.window').new({
    min_width = win_config.min_width,
    max_width = win_config.max_width,
    max_height = win_config.max_height,
    border = win_config.border,
    winblend = win_config.winblend,
    winhighlight = win_config.winhighlight,
    scrollbar = win_config.scrollbar,
    wrap = true,
    filetype = 'blink-cmp-documentation',
  }),
  last_context_id = nil,
  auto_show_timer = vim.uv.new_timer(),
}

menu.position_update_emitter:on(docs.update_position)
menu.close_emitter:on(function()
  docs.win:close()
  docs.auto_show_timer:stop()
end)

function docs.auto_show_item(item)
  docs.auto_show_timer:stop()
  if docs.win:is_open() then
    docs.auto_show_timer:start(config.update_delay_ms, 0, function()
      vim.schedule(function() docs.show_item(item) end)
    end)
  elseif config.auto_show then
    docs.auto_show_timer:start(config.auto_show_delay_ms, 0, function()
      vim.schedule(function() docs.show_item(item) end)
    end)
  end
end

function docs.show_item(item)
  docs.auto_show_timer:stop()
  if item == nil or not menu.win:is_open() then return docs.win:close() end

  -- TODO: cancellation
  -- TODO: only resolve if documentation does not exist
  sources
    .resolve(item)
    :map(function(item)
      if item.documentation == nil and item.detail == nil then
        docs.win:close()
        return
      end

      if docs.shown_item ~= item then
        require('blink.cmp.lib.window.docs').render_detail_and_documentation(
          docs.win:get_buf(),
          item.detail,
          item.documentation,
          docs.win.config.max_width,
          config.treesitter_highlighting
        )
      end
      docs.shown_item = item

      if menu.win:get_win() then
        docs.win:open()
        vim.api.nvim_win_set_cursor(docs.win:get_win(), { 1, 0 }) -- reset scroll
        docs.update_position()
      end
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR) end)
end

function docs.scroll_up(amount)
  local winnr = docs.win:get_win()
  local top_line = math.max(1, vim.fn.line('w0', winnr) - 1)
  local desired_line = math.max(1, top_line - amount)

  vim.api.nvim_win_set_cursor(docs.win:get_win(), { desired_line, 0 })
end

function docs.scroll_down(amount)
  local winnr = docs.win:get_win()
  local line_count = vim.api.nvim_buf_line_count(docs.win:get_buf())
  local bottom_line = math.max(1, vim.fn.line('w$', winnr) + 1)
  local desired_line = math.min(line_count, bottom_line + amount)

  vim.api.nvim_win_set_cursor(docs.win:get_win(), { desired_line, 0 })
end

function docs.update_position()
  if not docs.win:is_open() or not menu.win:is_open() then return end
  local winnr = docs.win:get_win()

  docs.win:update_size()

  local menu_winnr = menu.win:get_win()
  if not menu_winnr then return end
  local menu_win_config = vim.api.nvim_win_get_config(menu_winnr)
  local menu_win_height = menu.win:get_height()
  local menu_border_size = menu.win:get_border_size()

  local cursor_win_row = vim.fn.winline()

  -- decide direction priority based on the menu window's position
  local menu_win_is_up = menu_win_config.row - cursor_win_row < 0
  local direction_priority = menu_win_is_up and win_config.direction_priority.menu_north
    or win_config.direction_priority.menu_south

  -- remove the direction priority of the signature window if it's open
  local signature = require('blink.cmp.signature.window')
  if signature.win and signature.win:is_open() then
    direction_priority = vim.tbl_filter(
      function(dir) return dir ~= (menu_win_is_up and 's' or 'n') end,
      direction_priority
    )
  end

  -- decide direction, width and height of window
  local win_width = docs.win:get_width()
  local win_height = docs.win:get_height()
  local pos = docs.win:get_direction_with_window_constraints(menu.win, direction_priority, {
    width = math.min(win_width, win_config.desired_min_width),
    height = math.min(win_height, win_config.desired_min_height),
  })

  -- couldn't find anywhere to place the window
  if not pos then
    docs.win:close()
    return
  end

  -- set width and height based on available space
  vim.api.nvim_win_set_height(docs.win:get_win(), pos.height)
  vim.api.nvim_win_set_width(docs.win:get_win(), pos.width)

  -- set position based on provided direction

  local height = docs.win:get_height()
  local width = docs.win:get_width()

  local function set_config(opts)
    vim.api.nvim_win_set_config(winnr, { relative = 'win', win = menu_winnr, row = opts.row, col = opts.col })
  end
  if pos.direction == 'n' then
    if menu_win_is_up then
      set_config({ row = -height - menu_border_size.top, col = -menu_border_size.left })
    else
      set_config({ row = -1 - height - menu_border_size.top, col = -menu_border_size.left })
    end
  elseif pos.direction == 's' then
    if menu_win_is_up then
      set_config({
        row = 1 + menu_win_height - menu_border_size.top,
        col = -menu_border_size.left,
      })
    else
      set_config({
        row = menu_win_height - menu_border_size.top,
        col = -menu_border_size.left,
      })
    end
  elseif pos.direction == 'e' then
    if menu_win_is_up and menu_win_height < height then
      set_config({
        row = menu_win_height - menu_border_size.top - height,
        col = menu_win_config.width + menu_border_size.right,
      })
    else
      set_config({
        row = -menu_border_size.top,
        col = menu_win_config.width + menu_border_size.right,
      })
    end
  elseif pos.direction == 'w' then
    if menu_win_is_up and menu_win_height < height then
      set_config({
        row = menu_win_height - menu_border_size.top - height,
        col = -width - menu_border_size.left,
      })
    else
      set_config({ row = -menu_border_size.top, col = -width - menu_border_size.left })
    end
  end
end

return docs
