-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `keyword_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.

--- @class blink.cmp.ContextBounds
--- @field line string
--- @field line_number number
--- @field start_col number
--- @field end_col number
--- @field length number

--- @class blink.cmp.Context
--- @field id number
--- @field bufnr number
--- @field cursor number[]
--- @field line string
--- @field bounds blink.cmp.ContextBounds
--- @field trigger { kind: number, character: string | nil }

--- @class blink.cmp.CompletionTrigger
--- @field current_context_id number
--- @field context? blink.cmp.Context
--- @field show_emitter blink.cmp.EventEmitter<blink.cmp.Context>
--- @field hide_emitter blink.cmp.EventEmitter<{}>
---
--- @field activate fun()
--- @field is_trigger_character fun(char: string, is_retrigger?: boolean): boolean
--- @field show_if_on_trigger_character fun(opts?: { is_accept?: boolean }): boolean
--- @field show fun(opts?: { trigger_character?: string })
--- @field hide fun()

local keyword_config = require('blink.cmp.config').completion.keyword
local config = require('blink.cmp.config').completion.trigger
local sources = require('blink.cmp.sources.lib')
local utils = require('blink.cmp.lib.utils')

--- @type blink.cmp.CompletionTrigger
--- @diagnostic disable-next-line: missing-fields
local trigger = {
  current_context_id = -1,
  --- @type blink.cmp.Context | nil
  context = nil,
  show_emitter = require('blink.cmp.lib.event_emitter').new('show'),
  hide_emitter = require('blink.cmp.lib.event_emitter').new('hide'),
}

--- TODO: sweet mother of mary, massive refactor needed
function trigger.activate()
  require('blink.cmp.lib.buffer_events'):listen_buffer_changed({
    on_char_added = function(char, is_ignored)
      if vim.snippet.active() and not config.show_in_snippet and not trigger.context then
        return

      -- we were told to ignore the text changed event, so we update the context
      -- but don't send an on_show event upstream
      elseif trigger.ignore_next_text_changed then
        if trigger.context ~= nil then trigger.show({ send_upstream = false }) end
        trigger.ignore_next_text_changed = false

      -- ignore if in a special buffer
      elseif utils.is_blocked_buffer() then
        trigger.hide()

      -- character forces a trigger according to the sources, create a fresh context
      elseif
        vim.tbl_contains(sources.get_trigger_characters(), char)
        and not vim.tbl_contains(config.show_on_blocked_trigger_characters, char)
      then
        trigger.context = nil
        trigger.show({ trigger_character = char })

      -- character is part of the current context OR in an existing context
      elseif char:match(keyword_config.regex) ~= nil then
        trigger.show()

      -- nothing matches so hide
      else
        trigger.hide()
      end
    end,
    on_cursor_moved = function(event, is_ignored)
      if vim.snippet.active() and not config.show_in_snippet and not trigger.context then return end

      -- we were told to ignore the cursor moved event, so we update the context
      -- but don't send an on_show event upstream
      if trigger.ignore_next_cursor_moved and ev.event == 'CursorMovedI' then
        if trigger.context ~= nil then trigger.show({ send_upstream = false }) end
        trigger.ignore_next_cursor_moved = false
        return
      end

      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
      local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)
      local is_on_trigger_for_show = is_on_trigger
        and not vim.tbl_contains(config.show_on_blocked_trigger_characters, char_under_cursor)
      local is_on_trigger_for_show_on_insert = is_on_trigger
        and not vim.tbl_contains(config.show_on_x_blocked_trigger_characters, char_under_cursor)
      local is_on_context_char = char_under_cursor:match(keyword_config.regex) ~= nil

      local insert_enter_on_trigger_character = config.show_on_insert_on_trigger_character
        and is_on_trigger_for_show_on_insert
        and event == 'InsertEnter'

      -- check if we're still within the bounds of the query used for the context
      if trigger.within_query_bounds(vim.api.nvim_win_get_cursor(0)) then
        trigger.show()

      -- check if we've entered insert mode on a trigger character
      -- or if we've moved onto a trigger character
      elseif insert_enter_on_trigger_character or (is_on_trigger_for_show and trigger.context ~= nil) then
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

--- Suppresses on_hide and on_show events for the duration of the callback
--- TODO: extract into an autocmd module
--- HACK: there's likely edge cases with this since we can't know for sure
--- if the autocmds will fire for cursor_moved afaik
function trigger.suppress_events_for_callback(cb)
  local cursor_before = vim.api.nvim_win_get_cursor(0)
  local changed_tick_before = vim.api.nvim_buf_get_changedtick(0)

  cb()

  local cursor_after = vim.api.nvim_win_get_cursor(0)
  local changed_tick_after = vim.api.nvim_buf_get_changedtick(0)

  local is_insert_mode = vim.api.nvim_get_mode().mode == 'i'
  trigger.ignore_next_text_changed = changed_tick_after ~= changed_tick_before and is_insert_mode
  -- TODO: does this guarantee that the CursorMovedI event will fire?
  trigger.ignore_next_cursor_moved = (cursor_after[1] ~= cursor_before[1] or cursor_after[2] ~= cursor_before[2])
    and is_insert_mode
end

--- @param opts { is_accept?: boolean } | nil
function trigger.show_if_on_trigger_character(opts)
  if opts and opts.is_accept and not config.show_on_accept_on_trigger_character then return end

  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
  local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)
    and not vim.tbl_contains(config.show_on_x_blocked_trigger_characters, char_under_cursor)

  if is_on_trigger then trigger.show({ trigger_character = char_under_cursor }) end
  return is_on_trigger
end

--- @param opts { trigger_character?: string, send_upstream?: boolean, force?: boolean } | nil
function trigger.show(opts)
  opts = opts or {}

  local cursor = vim.api.nvim_win_get_cursor(0)
  -- already triggered at this position, ignore
  if
    not opts.force
    and trigger.context ~= nil
    and cursor[1] == trigger.context.cursor[1]
    and cursor[2] == trigger.context.cursor[2]
  then
    return
  end

  -- update context
  if trigger.context == nil then trigger.current_context_id = trigger.current_context_id + 1 end
  trigger.context = {
    id = trigger.current_context_id,
    bufnr = vim.api.nvim_get_current_buf(),
    cursor = cursor,
    line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1],
    bounds = trigger.get_context_bounds(keyword_config.regex),
    trigger = {
      kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
      character = opts.trigger_character,
    },
  }

  if opts.send_upstream ~= false then trigger.show_emitter:emit({ context = trigger.context }) end
end

function trigger.hide()
  if not trigger.context then return end
  trigger.context = nil
  trigger.hide_emitter:emit()
end

--- @param cursor number[]
--- @return boolean
function trigger.within_query_bounds(cursor)
  if not trigger.context then return false end

  local row, col = cursor[1], cursor[2]
  local bounds = trigger.context.bounds
  return row == bounds.line_number and col >= bounds.start_col and col <= bounds.end_col
end

--- Moves forward and backwards around the cursor looking for word boundaries
--- @param regex string
--- @return blink.cmp.ContextBounds
function trigger.get_context_bounds(regex)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

  local line = vim.api.nvim_buf_get_lines(0, cursor_line - 1, cursor_line, false)[1]
  local start_col = cursor_col
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match(regex) == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end

  local end_col = cursor_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match(regex) == nil then break end
    end_col = end_col + 1
  end

  -- hack: why do we have to math.min here?
  start_col = math.min(start_col, end_col)

  local length = end_col - start_col + 1
  -- Since sub(1, 1) returns a single char string, we need to check if that single char matches
  -- and otherwise mark the length as 0
  if start_col == end_col and line:sub(start_col, end_col):match(regex) == nil then length = 0 end

  return { line_number = cursor_line, start_col = start_col, end_col = end_col, length = length }
end

return trigger
