local utils = require('blink.cmp.utils')
local buffer_events = {}

function buffer_events.new(trigger)
  local self = setmetatable({}, { __index = buffer_events })
  self.trigger = trigger
  self.ignore_next_text_changed = false
  self.ignore_next_cursor_moved = false
  return self
end

function buffer_events:activate()
  local trigger = self.trigger
  local config = require('blink.cmp.config').trigger.completion
  local sources = require('blink.cmp.sources.lib')

  self:listen_buffer_changed({
    on_char_added = function(char, is_ignored)
      -- we were told to ignore the event, so we update the context
      -- but don't send an on_show event upstream
      if is_ignored then
        if trigger.context ~= nil then trigger.show({ send_upstream = false }) end
        return

      -- ignore if in a special buffer
      elseif utils.is_blocked_buffer() then
        trigger.hide()

      -- character forces a trigger according to the sources, create a fresh context
      elseif vim.tbl_contains(sources.get_trigger_characters(), char) then
        trigger.context = nil
        trigger.show({ trigger_character = char })

      -- character is part of the current context OR in an existing context
      elseif char:match(config.keyword_regex) ~= nil then
        trigger.show()

      -- nothing matches so hide
      else
        trigger.hide()
      end
    end,

    on_cursor_moved = function(event, is_ignored)
      -- we were told to ignore the cursor moved event, so we update the context
      -- but don't send an on_show event upstream
      if is_ignored then
        if trigger.context ~= nil then trigger.show({ send_upstream = false }) end
        return
      end

      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
      local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)
      local is_on_trigger_for_show_on_insert = is_on_trigger
        and not vim.tbl_contains(config.show_on_x_blocked_trigger_characters, char_under_cursor)
      local is_on_context_char = char_under_cursor:match(config.keyword_regex) ~= nil

      local insert_enter_on_trigger_character = config.show_on_insert_on_trigger_character
        and is_on_trigger_for_show_on_insert
        and event == 'InsertEnter'

      -- check if we're still within the bounds of the query used for the context
      if trigger.context and trigger.context:is_within_bounds(vim.api.nvim_win_get_cursor(0)) then
        trigger.show()

        -- check if we've entered insert mode on a trigger character
        -- or if we've moved onto a trigger character
      elseif insert_enter_on_trigger_character or (is_on_trigger and trigger.context ~= nil) then
        trigger.context = nil
        trigger.show({ trigger_character = char_under_cursor })

        -- show if we currently have a context, and we've moved outside of it's bounds by 1 char
      elseif is_on_context_char and trigger.context ~= nil and cursor_col == trigger.context.bounds.start_col - 1 then
        trigger.context = nil
        trigger.show()

        -- otherwise hide
      else
        trigger.hide()
      end
    end,

    on_insert_leave = function() trigger.hide() end,
  })
end

--- Normalizes the autocmds + ctrl+c into a common api and handles ignored events
--- @param opts { on_char_added: fun(char: string, is_ignored: boolean), on_cursor_moved: fun(event: 'CursorMovedI' | 'InsertEnter', is_ignored: boolean), on_insert_leave: fun() }
function buffer_events:listen_buffer_changed(opts)
  local show_in_snippet = require('blink.cmp.config').trigger.completion.show_in_snippet

  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function()
      if vim.snippet.active() and not show_in_snippet and not self.trigger.context then return end
      last_char = vim.v.char
    end,
  })

  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      if utils.is_blocked_buffer() then return end
      if vim.snippet.active() and not show_in_snippet and not self.trigger.context then return end

      -- no characters added so let cursormoved handle it
      if last_char == '' then return end

      opts.on_char_added(last_char, self.ignore_next_text_changed)
      self.ignore_next_text_changed = false

      last_char = ''
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'InsertEnter' }, {
    callback = function(ev)
      -- characters added so let textchanged handle it
      if last_char ~= '' then return end

      if utils.is_blocked_buffer() then return end
      if vim.snippet.active() and not show_in_snippet and not self.trigger.context then return end

      opts.on_cursor_moved(ev.event, ev.event == 'CursorMovedI' and self.ignore_next_cursor_moved)
      if ev.event == 'CursorMovedI' then self.ignore_next_cursor_moved = false end
    end,
  })

  -- definitely leaving the context
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, {
    callback = function()
      last_char = ''
      opts.on_insert_leave()
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

--- Triggers the show if the cursor is on a trigger character
--- @param opts { is_accept?: boolean } | nil
function buffer_events:show_if_on_trigger_character(opts)
  local config = require('blink.cmp.config').trigger.completion
  local sources = require('blink.cmp.sources.lib')

  if opts and opts.is_accept and not config.show_on_accept_on_trigger_character then return end

  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
  local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)
    and not vim.tbl_contains(config.show_on_x_blocked_trigger_characters, char_under_cursor)

  if is_on_trigger then trigger.show({ trigger_character = char_under_cursor }) end
  return is_on_trigger
end

return buffer_events
