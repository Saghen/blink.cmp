--- @class blink.cmp.CmdlineEvents
--- @field has_context fun(): boolean
--- @field ignore_next_text_changed boolean
--- @field ignore_next_cursor_moved boolean
---
--- @field new fun(): blink.cmp.CmdlineEvents
--- @field listen fun(self: blink.cmp.CmdlineEvents, opts: blink.cmp.CmdlineEventsListener)
--- @field suppress_events_for_callback fun(self: blink.cmp.CmdlineEvents, cb: fun())

--- @class blink.cmp.CmdlineEventsListener
--- @field on_char_added fun(char: string, is_ignored: boolean)
--- @field on_cursor_moved fun(event: 'CursorMovedI' | 'InsertEnter', is_ignored: boolean)
--- @field on_leave fun()

--- @type blink.cmp.CmdlineEvents
--- @diagnostic disable-next-line: missing-fields
local cmdline_events = {}

function cmdline_events.new()
  return setmetatable({
    ignore_next_text_changed = false,
    ignore_next_cursor_moved = false,
  }, { __index = cmdline_events })
end

function cmdline_events:listen(opts)
  local previous_cmdline = ''

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function() previous_cmdline = '' end,
  })

  vim.api.nvim_create_autocmd('CmdlineChanged', {
    callback = function()
      local cmdline = vim.fn.getcmdline()
      local cursor_col = vim.fn.getcmdpos()

      local is_text_changed_ignored = self.ignore_next_text_changed
      self.ignore_next_text_changed = false

      -- added a character
      if #cmdline > #previous_cmdline then
        local new_char = cmdline:sub(cursor_col - 1, cursor_col - 1)
        opts.on_char_added(new_char, is_text_changed_ignored)
      end
      previous_cmdline = cmdline
    end,
  })

  if vim.fn.has('nvim-0.11.0') == 1 then
    vim.api.nvim_create_autocmd('CursorMovedC', {
      callback = function()
        local is_cursor_moved_ignored = self.ignore_next_cursor_moved
        self.ignore_next_cursor_moved = false

        opts.on_cursor_moved('CursorMovedI', is_cursor_moved_ignored)
      end,
    })
  else
    -- HACK: check every 16ms (60 times/second) to see if the cursor moved
    -- for neovim < 0.11
    local timer = vim.uv.new_timer()
    local previous_cursor
    local callback
    callback = vim.schedule_wrap(function()
      timer:start(16, 0, callback)
      if vim.api.nvim_get_mode().mode ~= 'c' then return end

      local cursor = vim.fn.getcmdpos()
      if cursor == previous_cursor then return end
      previous_cursor = cursor

      local is_cursor_moved_ignored = self.ignore_next_cursor_moved
      self.ignore_next_cursor_moved = false

      opts.on_cursor_moved('CursorMovedI', is_cursor_moved_ignored)
    end)
    timer:start(16, 0, callback)
  end

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function() opts.on_leave() end,
  })
end

--- Suppresses autocmd events for the duration of the callback
--- HACK: there's likely edge cases with this
function cmdline_events:suppress_events_for_callback(cb)
  local cursor_before = vim.fn.getcmdpos()
  local text_before = vim.fn.getcmdline()

  cb()

  local cursor_after = vim.fn.getcmdpos()
  local text_after = vim.fn.getcmdline()

  if not vim.api.nvim_get_mode().mode == 'c' then return end

  self.ignore_next_text_changed = text_after ~= text_before
  -- TODO: does this guarantee that the CmdlineChanged event will fire?
  self.ignore_next_cursor_moved = cursor_after ~= cursor_before
end

return cmdline_events
