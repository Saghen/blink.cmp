--- Exposes three events (cursor moved, char added, insert leave) for triggers to use.
--- Notably, when "char added" is fired, the "cursor moved" event will not be fired.
--- Unlike in regular neovim, ctrl + c and buffer switching will trigger "insert leave"

--- @class blink.cmp.BufferEvents
--- @field has_context fun(): boolean
--- @field show_in_snippet boolean
--- @field ignore_next_text_changed boolean
--- @field ignore_next_cursor_moved boolean
---
--- @field new fun(opts: blink.cmp.BufferEventsOptions): blink.cmp.BufferEvents
--- @field listen fun(self: blink.cmp.BufferEvents, opts: blink.cmp.BufferEventsListener)
--- @field suppress_events_for_callback fun(self: blink.cmp.BufferEvents, cb: fun())

--- @class blink.cmp.BufferEventsOptions
--- @field has_context fun(): boolean
--- @field show_in_snippet boolean

--- @class blink.cmp.BufferEventsListener
--- @field on_char_added fun(char: string, is_ignored: boolean)
--- @field on_cursor_moved fun(event: 'CursorMoved' | 'InsertEnter', is_ignored: boolean)
--- @field on_insert_leave fun()

--- @type blink.cmp.BufferEvents
--- @diagnostic disable-next-line: missing-fields
local buffer_events = {}

function buffer_events.new(opts)
  return setmetatable({
    has_context = opts.has_context,
    show_in_snippet = opts.show_in_snippet,
    ignore_next_text_changed = false,
    ignore_next_cursor_moved = false,
  }, { __index = buffer_events })
end

--- Normalizes the autocmds + ctrl+c into a common api and handles ignored events
function buffer_events:listen(opts)
  local snippet = require('blink.cmp.config').snippets

  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function()
      if snippet.active() and not self.show_in_snippet and not self.has_context() then return end
      last_char = vim.v.char
    end,
  })

  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      if not require('blink.cmp.config').enabled() then return end
      if snippet.active() and not self.show_in_snippet and not self.has_context() then return end

      local is_ignored = self.ignore_next_text_changed
      self.ignore_next_text_changed = false

      -- no characters added so let cursormoved handle it
      if last_char == '' then return end

      opts.on_char_added(last_char, is_ignored)

      last_char = ''
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter' }, {
    callback = function(ev)
      -- only fire a CursorMoved event (notable not CursorMovedI)
      -- when jumping between tab stops in a snippet while showing the menu
      if
        ev.event == 'CursorMoved'
        and (vim.api.nvim_get_mode().mode ~= 'v' or not self.has_context() or not snippet.active())
      then
        return
      end

      local is_cursor_moved = ev.event == 'CursorMoved' or ev.event == 'CursorMovedI'

      local is_ignored = is_cursor_moved and self.ignore_next_cursor_moved
      if is_cursor_moved then self.ignore_next_cursor_moved = false end

      -- characters added so let textchanged handle it
      if last_char ~= '' then return end

      if not require('blink.cmp.config').enabled() then return end
      if not self.show_in_snippet and not self.has_context() and snippet.active() then return end

      opts.on_cursor_moved(is_cursor_moved and 'CursorMoved' or ev.event, is_ignored)
    end,
  })

  -- definitely leaving the context
  vim.api.nvim_create_autocmd({ 'ModeChanged', 'BufLeave' }, {
    callback = function()
      last_char = ''
      -- HACK: when using vim.snippet.expand, the mode switches from insert -> normal -> visual -> select
      -- so we schedule to ignore the intermediary modes
      -- TODO: deduplicate requests
      vim.schedule(function()
        if not vim.tbl_contains({ 'i', 's' }, vim.api.nvim_get_mode().mode) then opts.on_insert_leave() end
      end)
    end,
  })

  -- ctrl+c doesn't trigger InsertLeave so handle it separately
  local ctrl_c = vim.api.nvim_replace_termcodes('<C-c>', true, true, true)
  vim.on_key(function(key)
    if key == ctrl_c then
      vim.schedule(function()
        local mode = vim.api.nvim_get_mode().mode
        if mode ~= 'i' then
          last_char = ''
          opts.on_insert_leave()
        end
      end)
    end
  end)
end

--- Suppresses autocmd events for the duration of the callback
--- HACK: there's likely edge cases with this since we can't know for sure
--- if the autocmds will fire for cursor_moved afaik
function buffer_events:suppress_events_for_callback(cb)
  local cursor_before = vim.api.nvim_win_get_cursor(0)
  local changed_tick_before = vim.api.nvim_buf_get_changedtick(0)

  cb()

  local cursor_after = vim.api.nvim_win_get_cursor(0)
  local changed_tick_after = vim.api.nvim_buf_get_changedtick(0)

  local is_insert_mode = vim.api.nvim_get_mode().mode == 'i'
  self.ignore_next_text_changed = changed_tick_after ~= changed_tick_before and is_insert_mode
  -- TODO: does this guarantee that the CursorMovedI event will fire?
  self.ignore_next_cursor_moved = (cursor_after[1] ~= cursor_before[1] or cursor_after[2] ~= cursor_before[2])
    and is_insert_mode
end

return buffer_events
