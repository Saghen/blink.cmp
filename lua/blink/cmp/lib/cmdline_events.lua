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
  -- TextChanged
  local on_changed = function(key) opts.on_char_added(key, false) end

  local is_change_queued = false
  vim.on_key(function(_, escaped_key)
    if vim.api.nvim_get_mode().mode ~= 'c' then return end

    -- ignore if it's a special key
    local key = vim.fn.keytrans(escaped_key)
    if vim.regex([[<.*>]]):match_str(key) and not '<Space>' == key then return end

    if not is_change_queued then
      is_change_queued = true
      vim.schedule(function()
        on_changed(key)
        is_change_queued = false
      end)
    end
  end)

  -- CursorMoved
  local previous_cmdline = ''
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function() previous_cmdline = '' end,
  })

  if vim.fn.has('nvim-0.11.0') == 1 then
    vim.api.nvim_create_autocmd('CursorMovedC', {
      callback = function()
        local is_ignored = self.ignore_next_cursor_moved
        self.ignore_next_cursor_moved = false

        opts.on_cursor_moved('CursorMovedI', is_ignored)
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

      local cmdline_equal = vim.fn.getcmdline() == previous_cmdline
      local cursor_equal = vim.fn.getcmdpos() == previous_cursor

      previous_cmdline = vim.fn.getcmdline()
      previous_cursor = vim.fn.getcmdpos()

      if cursor_equal or not cmdline_equal then return end

      local is_ignored = self.ignore_next_cursor_moved
      self.ignore_next_cursor_moved = false

      opts.on_cursor_moved('CursorMovedI', is_ignored)
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

  cb()

  if not vim.api.nvim_get_mode().mode == 'c' then return end

  local cursor_after = vim.fn.getcmdpos()
  -- TODO: does this guarantee that the CmdlineChanged event will fire?
  self.ignore_next_cursor_moved = self.ignore_next_cursor_moved or cursor_after ~= cursor_before
end

return cmdline_events
