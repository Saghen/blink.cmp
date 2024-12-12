--- Manages creating/updating scrollbar gutter and thumb windows

--- @class blink.cmp.ScrollbarWin
--- @field enable_gutter boolean
--- @field thumb_win? number
--- @field gutter_win? number
--- @field buf? number
---
--- @field new fun(opts: blink.cmp.ScrollbarConfig): blink.cmp.ScrollbarWin
--- @field is_visible fun(self: blink.cmp.ScrollbarWin): boolean
--- @field show_thumb fun(self: blink.cmp.ScrollbarWin, geometry: blink.cmp.ScrollbarGeometry)
--- @field show_gutter fun(self: blink.cmp.ScrollbarWin, geometry: blink.cmp.ScrollbarGeometry)
--- @field hide_thumb fun(self: blink.cmp.ScrollbarWin)
--- @field hide_gutter fun(self: blink.cmp.ScrollbarWin)
--- @field hide fun(self: blink.cmp.ScrollbarWin)
--- @field _make_win fun(self: blink.cmp.ScrollbarWin, geometry: blink.cmp.ScrollbarGeometry, hl_group: string): number

local scrollbar_win = {}

function scrollbar_win.new(opts) return setmetatable(opts, { __index = scrollbar_win }) end

function scrollbar_win:is_visible() return self.thumb_win ~= nil and vim.api.nvim_win_is_valid(self.thumb_win) end

function scrollbar_win:show_thumb(geometry)
  -- create window if it doesn't exist
  if self.thumb_win == nil or not vim.api.nvim_win_is_valid(self.thumb_win) then
    self.thumb_win = self:_make_win(geometry, 'BlinkCmpScrollBarThumb')
  else
    -- update with the geometry
    local thumb_existing_config = vim.api.nvim_win_get_config(self.thumb_win)
    local thumb_config = vim.tbl_deep_extend('force', thumb_existing_config, geometry)
    vim.api.nvim_win_set_config(self.thumb_win, thumb_config)
  end

  if vim.api.nvim_get_mode().mode == 'c' then vim.api.nvim__redraw({ win = self.thumb_win, flush = true }) end
end

function scrollbar_win:show_gutter(geometry)
  if not self.enable_gutter then return end

  -- create window if it doesn't exist
  if self.gutter_win == nil or not vim.api.nvim_win_is_valid(self.gutter_win) then
    self.gutter_win = self:_make_win(geometry, 'BlinkCmpScrollBarGutter')
  else
    -- update with the geometry
    local gutter_existing_config = vim.api.nvim_win_get_config(self.gutter_win)
    local gutter_config = vim.tbl_deep_extend('force', gutter_existing_config, geometry)
    vim.api.nvim_win_set_config(self.gutter_win, gutter_config)
  end

  if vim.api.nvim_get_mode().mode == 'c' then vim.api.nvim__redraw({ win = self.gutter_win, flush = true }) end
end

function scrollbar_win:hide_thumb()
  if self.thumb_win and vim.api.nvim_win_is_valid(self.thumb_win) then
    vim.api.nvim_win_close(self.thumb_win, true)
    if vim.api.nvim_get_mode().mode == 'c' then vim.api.nvim__redraw({ flush = true }) end
  end
end

function scrollbar_win:hide_gutter()
  if self.gutter_win and vim.api.nvim_win_is_valid(self.gutter_win) then
    vim.api.nvim_win_close(self.gutter_win, true)
    if vim.api.nvim_get_mode().mode == 'c' then vim.api.nvim__redraw({ flush = true }) end
  end
end

function scrollbar_win:hide()
  self:hide_thumb()
  self:hide_gutter()
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then vim.api.nvim_buf_delete(self.buf, { force = true }) end
end

function scrollbar_win:_make_win(geometry, hl_group)
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then self.buf = vim.api.nvim_create_buf(false, true) end

  local win_config = vim.tbl_deep_extend('force', geometry, {
    style = 'minimal',
    focusable = false,
    noautocmd = true,
  })
  local win = vim.api.nvim_open_win(self.buf, false, win_config)
  vim.api.nvim_set_option_value('winhighlight', 'Normal:' .. hl_group .. ',EndOfBuffer:' .. hl_group, { win = win })
  return win
end

return scrollbar_win
