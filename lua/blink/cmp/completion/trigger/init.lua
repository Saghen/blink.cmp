--- @alias blink.cmp.CompletionTriggerKind 'manual' | 'prefetch' | 'keyword' | 'trigger_character'
---
-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `keyword_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.
--- @class blink.cmp.CompletionTrigger
--- @field buffer_events blink.cmp.BufferEvents
--- @field cmdline_events blink.cmp.CmdlineEvents
--- @field current_context_id number
--- @field context? blink.cmp.Context
--- @field show_emitter blink.cmp.EventEmitter<{ context: blink.cmp.Context }>
--- @field hide_emitter blink.cmp.EventEmitter<{}>
---
--- @field activate fun()
--- @field is_keyword_character fun(char: string): boolean
--- @field is_trigger_character fun(char: string, is_show_on_x?: boolean): boolean
--- @field suppress_events_for_callback fun(cb: fun())
--- @field show_if_on_trigger_character fun(opts?: { is_accept?: boolean })
--- @field show fun(opts?: { trigger_kind: blink.cmp.CompletionTriggerKind, trigger_character?: string, force?: boolean, send_upstream?: boolean, providers?: string[] }): blink.cmp.Context?
--- @field hide fun()
--- @field within_query_bounds fun(cursor: number[]): boolean
--- @field get_bounds fun(regex: vim.regex, line: string, cursor: number[]): blink.cmp.ContextBounds

local config = require('blink.cmp.config').completion.trigger
local context = require('blink.cmp.completion.trigger.context')
local utils = require('blink.cmp.completion.trigger.utils')

--- @type blink.cmp.CompletionTrigger
--- @diagnostic disable-next-line: missing-fields
local trigger = {
  current_context_id = -1,
  show_emitter = require('blink.cmp.lib.event_emitter').new('show'),
  hide_emitter = require('blink.cmp.lib.event_emitter').new('hide'),
}

function trigger.activate()
  trigger.buffer_events = require('blink.cmp.lib.buffer_events').new({
    -- TODO: should this ignore trigger.kind == 'prefetch'?
    has_context = function() return trigger.context ~= nil end,
    show_in_snippet = config.show_in_snippet,
  })
  trigger.cmdline_events = require('blink.cmp.lib.cmdline_events').new()

  local function on_char_added(char, is_ignored)
    -- we were told to ignore the text changed event, so we update the context
    -- but don't send an on_show event upstream
    if is_ignored then
      if trigger.context ~= nil then trigger.show({ send_upstream = false, trigger_kind = 'keyword' }) end

    -- character forces a trigger according to the sources, create a fresh context
    elseif trigger.is_trigger_character(char) and (config.show_on_trigger_character or trigger.context ~= nil) then
      trigger.context = nil
      trigger.show({ trigger_kind = 'trigger_character', trigger_character = char })

    -- character is part of a keyword
    elseif trigger.is_keyword_character(char) and (config.show_on_keyword or trigger.context ~= nil) then
      trigger.show({ trigger_kind = 'keyword' })

    -- nothing matches so hide
    else
      trigger.hide()
    end
  end

  local function on_cursor_moved(event, is_ignored)
    local cursor = context.get_cursor()
    local cursor_col = cursor[2]

    local char_under_cursor = utils.get_char_at_cursor()
    local is_keyword = trigger.is_keyword_character(char_under_cursor)

    -- we were told to ignore the cursor moved event, so we update the context
    -- but don't send an on_show event upstream
    if is_ignored and event == 'CursorMoved' then
      if trigger.context ~= nil then
        -- TODO: If we `auto_insert` with the `path` source, we may end up on a trigger character
        -- i.e. `downloads/`. If we naively update the context, we'll show the menu with the
        -- existing context. So we clear the context if we're not on a keyword character.
        -- Is there a better solution here?
        if not is_keyword then trigger.context = nil end

        trigger.show({ send_upstream = false, trigger_kind = 'keyword' })
      end
      return
    end

    local is_on_trigger_for_show = trigger.is_trigger_character(char_under_cursor)

    -- TODO: doesn't handle `a` where the cursor moves immediately after
    -- Reproducible with `example.|a` and pressing `a`, should not show the menu
    local insert_enter_on_trigger_character = config.show_on_trigger_character
      and config.show_on_insert_on_trigger_character
      and event == 'InsertEnter'
      and trigger.is_trigger_character(char_under_cursor, true)

    -- check if we're still within the bounds of the query used for the context
    if trigger.context ~= nil and trigger.context:within_query_bounds(cursor) then
      trigger.show({ trigger_kind = 'keyword' })

    -- check if we've entered insert mode on a trigger character
    -- or if we've moved onto a trigger character while open
    elseif
      insert_enter_on_trigger_character
      or (is_on_trigger_for_show and trigger.context ~= nil and trigger.context.trigger.kind ~= 'prefetch')
    then
      trigger.context = nil
      trigger.show({ trigger_kind = 'trigger_character', trigger_character = char_under_cursor })

    -- show if we currently have a context, and we've moved outside of it's bounds by 1 char
    elseif is_keyword and trigger.context ~= nil and cursor_col == trigger.context.bounds.start_col - 1 then
      trigger.context = nil
      trigger.show({ trigger_kind = 'keyword' })

    -- prefetch completions without opening window on InsertEnter
    elseif event == 'InsertEnter' and config.prefetch_on_insert then
      trigger.show({ trigger_kind = 'prefetch' })

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

function trigger.is_keyword_character(char)
  -- special case for hyphen, since we don't consider a lone hyphen to be a keyword
  if char == '-' then return true end

  local keyword_start_col, keyword_end_col = require('blink.cmp.fuzzy').get_keyword_range(char, #char, 'prefix')
  return keyword_start_col ~= keyword_end_col
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

  local cursor_col = context.get_cursor()[2]
  local char_under_cursor = context.get_line():sub(cursor_col, cursor_col)

  if trigger.is_trigger_character(char_under_cursor, true) then
    trigger.show({ trigger_kind = 'trigger_character', trigger_character = char_under_cursor })
  end
end

function trigger.show(opts)
  if not require('blink.cmp.config').enabled() then return trigger.hide() end

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

  local initial_trigger_kind = trigger.context and trigger.context.trigger.initial_kind or opts.trigger_kind
  -- if we prefetched, don't keep that as the initial trigger kind
  if initial_trigger_kind == 'prefetch' then initial_trigger_kind = opts.trigger_kind end
  -- if we're manually triggering, set it as the initial trigger kind
  if opts.trigger_kind == 'manual' then initial_trigger_kind = 'manual' end

  trigger.context = context.new({
    id = trigger.current_context_id,
    providers = providers,
    initial_trigger_kind = initial_trigger_kind,
    initial_trigger_character = trigger.context and trigger.context.trigger.initial_character or opts.trigger_character,
    trigger_kind = opts.trigger_kind,
    trigger_character = opts.trigger_character,
  })

  if opts.send_upstream ~= false then trigger.show_emitter:emit({ context = trigger.context }) end
  return trigger.context
end

function trigger.hide()
  if not trigger.context then return end
  trigger.context = nil
  trigger.hide_emitter:emit()
end

return trigger
