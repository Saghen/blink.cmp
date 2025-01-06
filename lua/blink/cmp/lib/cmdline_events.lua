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
--- @field on_cursor_moved fun(event: 'CursorMoved' | 'InsertEnter', is_ignored: boolean)
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

  -- We handle backspace as a special case, because the text will have changed
  -- but we still want to fire the CursorMoved event, and not the TextChanged event
  local did_backspace = false
  local is_change_queued = false
  vim.on_key(function(raw_key, escaped_key)
    if vim.api.nvim_get_mode().mode ~= 'c' then return end

    -- ignore if it's a special key
    -- FIXME: odd behavior when escaped_key has multiple keycodes, i.e. by pressing <C-p> and then "t"
    local key = vim.fn.keytrans(escaped_key)
    if key == '<BS>' and not is_change_queued then did_backspace = true end
    if key:sub(1, 1) == '<' and key:sub(#key, #key) == '>' and raw_key ~= ' ' then return end
    if key == '' then return end

    if not is_change_queued then
      is_change_queued = true
      did_backspace = false
      vim.schedule(function()
        on_changed(raw_key)
        is_change_queued = false
      end)
    end
  end)

  -- CursorMoved
  local previous_cmdline = ''
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function() previous_cmdline = '' end,
  })

  -- TODO: switch to CursorMovedC when nvim 0.11 is released
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

    if cursor_equal or (not cmdline_equal and not did_backspace) then return end
    did_backspace = false

    local is_ignored = self.ignore_next_cursor_moved
    self.ignore_next_cursor_moved = false

    opts.on_cursor_moved('CursorMoved', is_ignored)
  end)
  timer:start(16, 0, callback)

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
  self.ignore_next_cursor_moved = self.ignore_next_cursor_moved or cursor_after ~= cursor_before
end

return cmdline_events
