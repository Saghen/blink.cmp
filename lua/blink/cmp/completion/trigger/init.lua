-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `keyword_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.

--- @class blink.cmp.CompletionTrigger
--- @field buffer_events blink.cmp.BufferEvents
--- @field cmdline_events blink.cmp.CmdlineEvents
--- @field current_context_id number
--- @field context? blink.cmp.Context
--- @field prefetch? boolean
--- @field show_emitter blink.cmp.EventEmitter<{ context: blink.cmp.Context }>
--- @field hide_emitter blink.cmp.EventEmitter<{}>
---
--- @field activate fun()
--- @field is_trigger_character fun(char: string, is_retrigger?: boolean): boolean
--- @field suppress_events_for_callback fun(cb: fun())
--- @field show_if_on_trigger_character fun(opts?: { is_accept?: boolean })
--- @field show fun(opts?: { trigger_character?: string, force?: boolean, send_upstream?: boolean, providers?: string[], prefetch?: boolean })
--- @field hide fun()
--- @field within_query_bounds fun(cursor: number[]): boolean
--- @field get_context_bounds fun(regex: vim.regex, line: string, cursor: number[]): blink.cmp.ContextBounds

local keyword_config = require('blink.cmp.config').completion.keyword
local config = require('blink.cmp.config').completion.trigger
local context = require('blink.cmp.completion.trigger.context')

local keyword_regex = vim.regex(keyword_config.regex)

--- @type blink.cmp.CompletionTrigger
--- @diagnostic disable-next-line: missing-fields
local trigger = {
  current_context_id = -1,
  show_emitter = require('blink.cmp.lib.event_emitter').new('show'),
  hide_emitter = require('blink.cmp.lib.event_emitter').new('hide'),
}

function trigger.activate()
  trigger.buffer_events = require('blink.cmp.lib.buffer_events').new({
    has_context = function() return trigger.context ~= nil end,
    show_in_snippet = config.show_in_snippet,
  })
  trigger.cmdline_events = require('blink.cmp.lib.cmdline_events').new()

  local function on_char_added(char, is_ignored)
    -- we were told to ignore the text changed event, so we update the context
    -- but don't send an on_show event upstream
    if is_ignored then
      if trigger.context ~= nil then trigger.show({ send_upstream = false }) end

      -- character forces a trigger according to the sources, create a fresh context
    elseif trigger.is_trigger_character(char) and (config.show_on_trigger_character or trigger.context ~= nil) then
      trigger.context = nil
      trigger.show({ trigger_character = char })

      -- character is part of a keyword
    elseif keyword_regex:match_str(char) ~= nil and (config.show_on_keyword or trigger.context ~= nil) then
      trigger.show()

      -- nothing matches so hide
    else
      trigger.hide()
    end
  end

  local function on_cursor_moved(event, is_ignored)
    -- we were told to ignore the cursor moved event, so we update the context
    -- but don't send an on_show event upstream
    if is_ignored and event == 'CursorMovedI' then
      if trigger.context ~= nil then trigger.show({ send_upstream = false }) end
      return
    end

    local cursor = context.get_cursor()
    local cursor_col = cursor[2]
    local char_under_cursor = context.get_line():sub(cursor_col, cursor_col)
    local is_on_trigger_for_show = trigger.is_trigger_character(char_under_cursor)
    local is_on_trigger_for_show_on_insert = trigger.is_trigger_character(char_under_cursor, true)
    local is_on_keyword_char = keyword_regex:match_str(char_under_cursor) ~= nil

    local insert_enter_on_trigger_character = config.show_on_trigger_character
      and config.show_on_insert_on_trigger_character
      and is_on_trigger_for_show_on_insert
      and event == 'InsertEnter'

    -- check if we're still within the bounds of the query used for the context
    if trigger.context ~= nil and trigger.context:within_query_bounds(cursor) then
      trigger.show()

    -- check if we've entered insert mode on a trigger character
    -- or if we've moved onto a trigger character (by accepting for example)
    elseif insert_enter_on_trigger_character or (is_on_trigger_for_show and trigger.context ~= nil) then
      trigger.context = nil
      trigger.show({ trigger_character = char_under_cursor })

    -- show if we currently have a context, and we've moved outside of it's bounds by 1 char
    elseif is_on_keyword_char and trigger.context ~= nil and cursor_col == trigger.context.bounds.start_col - 1 then
      trigger.context = nil
      trigger.show()

    -- prefetch completions without opening window on InsertEnter
    elseif event == 'InsertEnter' then
      trigger.show({ prefetch = true })

    -- otherwise hide
    else
      trigger.hide()
    end
  end

  trigger.buffer_events:listen({
    on_char_added = on_char_added,
    on_cursor_moved = on_cursor_moved,
    on_insert_leave = function() trigger.hide() end,
  })
  trigger.cmdline_events:listen({
    on_char_added = on_char_added,
    on_cursor_moved = on_cursor_moved,
    on_leave = function() trigger.hide() end,
  })
end

function trigger.is_trigger_character(char, is_show_on_x)
  local sources = require('blink.cmp.sources.lib')
  local is_trigger = vim.tbl_contains(sources.get_trigger_characters(context.get_mode()), char)

  local show_on_blocked_trigger_characters = type(config.show_on_blocked_trigger_characters) == 'function'
      and config.show_on_blocked_trigger_characters()
    or config.show_on_blocked_trigger_characters
  --- @cast show_on_blocked_trigger_characters string[]
  local show_on_x_blocked_trigger_characters = type(config.show_on_x_blocked_trigger_characters) == 'function'
      and config.show_on_x_blocked_trigger_characters()
    or config.show_on_x_blocked_trigger_characters
  --- @cast show_on_x_blocked_trigger_characters string[]

  local is_blocked = vim.tbl_contains(show_on_blocked_trigger_characters, char)
    or (is_show_on_x and vim.tbl_contains(show_on_x_blocked_trigger_characters, char))

  return is_trigger and not is_blocked
end

--- Suppresses on_hide and on_show events for the duration of the callback
function trigger.suppress_events_for_callback(cb)
  local mode = vim.api.nvim_get_mode().mode == 'c' and 'cmdline' or 'default'

  local events = mode == 'default' and trigger.buffer_events or trigger.cmdline_events
  if not events then return cb() end

  events:suppress_events_for_callback(cb)
end

function trigger.show_if_on_trigger_character(opts)
  if
    (opts and opts.is_accept)
    and (not config.show_on_trigger_character or not config.show_on_accept_on_trigger_character)
  then
    return
  end

  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)

  if trigger.is_trigger_character(char_under_cursor, true) then
    trigger.show({ trigger_character = char_under_cursor })
  end
end

function trigger.show(opts)
  opts = opts or {}

  -- already triggered at this position, ignore
  local mode = context.get_mode()
  local cursor = context.get_cursor()
  if
    not opts.force
    and trigger.context ~= nil
    and trigger.context.mode == mode
    and cursor[1] == trigger.context.cursor[1]
    and cursor[2] == trigger.context.cursor[2]
  then
    return
  end

  -- update the context id to indicate a new context, and not an update to an existing context
  if trigger.context == nil or opts.providers ~= nil then
    trigger.current_context_id = trigger.current_context_id + 1
  end

  local providers = opts.providers
    or (trigger.context and trigger.context.providers)
    or require('blink.cmp.sources.lib').get_enabled_provider_ids(context.get_mode())

  trigger.context =
    context.new({ id = trigger.current_context_id, providers = providers, trigger_character = opts.trigger_character })
  trigger.prefetch = opts.prefetch == true

  if opts.send_upstream ~= false then trigger.show_emitter:emit({ context = trigger.context }) end
end

function trigger.hide()
  if not trigger.context then return end
  trigger.context = nil
  trigger.hide_emitter:emit()
end

return trigger
