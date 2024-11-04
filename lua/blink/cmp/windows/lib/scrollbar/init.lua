--- @class blink.cmp.ScrollbarConfig
--- @field enable_gutter boolean

--- @class blink.cmp.Scrollbar
--- @field target_win? number
--- @field win? blink.cmp.ScrollbarWin
--- @field autocmd? number
---
--- @field new fun(opts: blink.cmp.ScrollbarConfig): blink.cmp.Scrollbar
--- @field is_mounted fun(self: blink.cmp.Scrollbar): boolean
--- @field mount fun(self: blink.cmp.Scrollbar, target_win: number)
--- @field unmount fun(self: blink.cmp.Scrollbar)

--- @type blink.cmp.Scrollbar
--- @diagnostic disable-next-line: missing-fields
local scrollbar = {}

function scrollbar.new(opts)
  local self = setmetatable({}, { __index = scrollbar })
  self.win = require('blink.cmp.windows.lib.scrollbar.win').new(opts)
  return self
end

function scrollbar:is_mounted() return self.autocmd ~= nil end

function scrollbar:mount(target_win)
  -- unmount existing scrollbar if the target window changed
  if self.target_win ~= target_win then
    if not vim.api.nvim_win_is_valid(target_win) then return end
    self:unmount()
  end
  -- ignore if already mounted
  if self:is_mounted() then return end

  local geometry = require('blink.cmp.windows.lib.scrollbar.geometry').get_geometry(target_win)
  self.win:show_thumb(geometry.thumb)
  self.win:show_gutter(geometry.gutter)

  local function update()
    if not vim.api.nvim_win_is_valid(target_win) then return self:unmount() end

    local updated_geometry = require('blink.cmp.windows.lib.scrollbar.geometry').get_geometry(target_win)
    self.win:show_gutter(updated_geometry.gutter)
    if updated_geometry.should_hide_thumb then
      self.win:hide_thumb()
    else
      self.win:show_thumb(updated_geometry.thumb)
    end
  end
  -- HACK: for some reason, the autocmds don't fire on the initial mount
  -- so we apply after on the next event loop iteration after the windows are definitely setup
  vim.schedule(update)

  self.autocmd = vim.api.nvim_create_autocmd(
    { 'WinScrolled', 'WinClosed', 'WinResized', 'CursorMoved', 'CursorMovedI' },
    { callback = update }
  )
end

function scrollbar:unmount()
  self.win:hide()

  if self.autocmd then vim.api.nvim_del_autocmd(self.autocmd) end
  self.autocmd = nil
end

return scrollbar
