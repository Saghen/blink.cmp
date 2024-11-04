---@class blink.cmp.Scrollbar
---@field target? number
---@field thumb? number
---@field gutter? number
local scrollbar = {}

function scrollbar.new(target)
  local o = {}

  o.target = target

  return setmetatable(o, { __index = scrollbar })
end

local function update_win_config(winid, ...)
  local config = vim.api.nvim_win_get_config(winid)

  vim.api.nvim_win_set_config(winid, vim.tbl_deep_extend('force', config, ...))
end

function scrollbar:update()
  if self.target == nil or not vim.api.nvim_win_is_valid(self.target) then
    self:unmount()
    return
  end

  local geo, gutter_geo, hide = self:_geometry()

  if hide then
    self:unmount()
    return
  elseif not self:is_mounted() then
    self:mount()
  end

  update_win_config(self.thumb, geo)
  update_win_config(self.gutter, gutter_geo)
end

function scrollbar:is_mounted() return self.thumb ~= nil and vim.api.nvim_win_is_valid(self.thumb) end

function scrollbar:mount()
  if self.target == nil or not vim.api.nvim_win_is_valid(self.target) then
    self:unmount()
    return
  end

  if self:is_mounted() then return end

  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then self.buf = vim.api.nvim_create_buf(false, true) end

  local geo, gutter_geo = self:_geometry()

  local config = vim.tbl_deep_extend('force', geo, {
    style = 'minimal',
    focusable = false,
    noautocmd = true,
  })
  self.thumb = vim.api.nvim_open_win(self.buf, false, config)

  local gutter_config = vim.tbl_deep_extend('force', gutter_geo, {
    style = 'minimal',
    focusable = false,
    noautocmd = true,
  })
  self.gutter = vim.api.nvim_open_win(self.buf, false, gutter_config)

  vim.api.nvim_set_option_value('winhighlight', 'Normal:' .. 'BlinkCmpMenuSelection', { win = self.thumb })

  self.autocmd = vim.api.nvim_create_autocmd({ 'WinScrolled', 'WinClosed', 'CursorMoved', 'CursorMovedI' }, {
    callback = function() self:update() end,
  })
end

function scrollbar:unmount()
  if self.thumb and vim.api.nvim_win_is_valid(self.thumb) then vim.api.nvim_win_close(self.thumb, true) end
  if self.gutter and vim.api.nvim_win_is_valid(self.gutter) then vim.api.nvim_win_close(self.gutter, true) end

  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then vim.api.nvim_buf_delete(self.buf, { force = true }) end

  if self.autocmd then vim.api.nvim_del_autocmd(self.autocmd) end

  self.thumb = nil
  self.buf = nil
  self.autocmd = nil
end

function scrollbar:_win_buf_height()
  local buf = vim.api.nvim_win_get_buf(self.target)

  if not vim.wo[self.target].wrap then return vim.api.nvim_buf_line_count(buf) end

  local width = vim.api.nvim_win_get_width(self.target)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, (math.ceil(vim.fn.strwidth(l) / width)))
  end
  return height
end

function scrollbar:_geometry()
  local width = vim.api.nvim_win_get_width(self.target)
  local height = vim.api.nvim_win_get_height(self.target)

  local buf_height = self:_win_buf_height()

  local zindex = vim.api.nvim_win_get_config(self.target).zindex or 1

  local thumb_height = math.max(1, math.floor(height * height / buf_height + 0.5) - 1)

  local pct = vim.api.nvim_win_get_cursor(self.target)[1] / buf_height

  local thumb_offset = math.floor(pct * (height - thumb_height) + 0.5)

  return {
    width = 1,
    height = thumb_height,
    row = thumb_offset,
    col = width,
    zindex = zindex + 2,
    relative = 'win',
    win = self.target,
  },
    {
      width = 1,
      height = height,
      row = 0,
      col = width,
      zindex = zindex + 1,
      relative = 'win',
      win = self.target,
    },
    thumb_height >= buf_height
end

return scrollbar
