-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `keyword_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.

local config = require('blink.cmp.config').trigger.completion

local trigger = {
  current_context_id = -1,
  --- @type blink.cmp.Context | nil
  context = nil,
  event_targets = {
    --- @type fun(context: blink.cmp.Context)
    on_show = function() end,
    --- @type fun()
    on_hide = function() end,
  },
}

function trigger.activate_events()
  trigger.buffer_events = require('blink.cmp.trigger.completion.modes.buffer').new(trigger)
  trigger.cmdline_events = require('blink.cmp.trigger.completion.modes.cmdline').new(trigger)

  trigger.buffer_events:activate()
  trigger.cmdline_events:activate()

  return trigger
end

function trigger.show_if_on_trigger_character()
  if trigger.context == nil or trigger.context.mode ~= 'completion' then return end
  trigger.buffer_events:show_if_on_trigger_character()
end

--- @param opts { mode: blink.cmp.Mode, trigger_character?: string, send_upstream?: boolean, force?: boolean } | nil
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
  trigger.context = require('blink.cmp.trigger.completion.context').new({
    id = trigger.context and trigger.context.id,
    keyword_regex = config.keyword_regex,
    mode = opts.mode,
    trigger_character = opts.trigger_character,
  })

  if opts.send_upstream ~= false then trigger.event_targets.on_show(trigger.context) end
end

--- @param callback fun(context: blink.cmp.Context)
function trigger.listen_on_show(callback) trigger.event_targets.on_show = callback end

function trigger.hide()
  if not trigger.context then return end
  trigger.context = nil
  trigger.event_targets.on_hide()
end

--- @param callback fun()
function trigger.listen_on_hide(callback) trigger.event_targets.on_hide = callback end

return trigger
