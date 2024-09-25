local config = require('blink.cmp.config')
local sources = {
  registered = {},
  responses = {},
  current_context = { id = -1 },
  on_completions_callback = function(_, _) end,
}

function sources.register()
  for _, source_config in ipairs(config.sources.providers) do
    local source = require('blink.cmp.sources.lib.source').new(source_config)
    local name = source_config[1]
    source:listen_on_completions(function(response)
      if response.context.id ~= sources.current_context.id then return end
      sources.responses[name] = response
      sources.send_completions()
    end)
    sources.registered[name] = source
  end
end

--- @return string[]
function sources.get_trigger_characters()
  local blocked_trigger_characters = {}
  for _, char in ipairs(config.trigger.blocked_trigger_characters) do
    blocked_trigger_characters[char] = true
  end

  local trigger_characters = {}
  for _, source in pairs(sources.registered) do
    local source_trigger_characters = source:get_trigger_characters()
    for _, char in ipairs(source_trigger_characters) do
      if not blocked_trigger_characters[char] then table.insert(trigger_characters, char) end
    end
  end
  return trigger_characters
end

function sources.listen_on_completions(callback) sources.on_completions_callback = callback end

--- @param context blink.cmp.ShowContext
function sources.completions(context)
  -- a new context means we should refetch everything
  local is_new_context = context.id ~= sources.current_context.id
  if is_new_context then sources.responses = {} end
  sources.current_context = context

  for _, source in pairs(sources.registered) do
    -- the source indicates we should refetch when this character is typed
    local trigger_character = context.trigger_character
      and vim.tbl_contains(source:get_trigger_characters(), context.trigger_character)

    -- The TriggerForIncompleteCompletions kind is handled by the source itself
    local source_context = vim.fn.deepcopy(context)
    source_context.trigger = trigger_character
        and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger_character }
      or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

    source:request_completions(source_context)
  end
end

function sources.send_completions()
  -- check that all sources have responded at least once
  -- TODO: on the 2nd+ request, this would cause duplicate completion callbacks
  -- so we somehow need to know if we should expect more data to come in
  for name, _ in pairs(sources.registered) do
    if sources.responses[name] == nil then
      vim.print('No response for ' .. name)
      return
    end
  end

  -- apply source filters
  for name, source in pairs(sources.registered) do
    sources.responses = source:filter_completions(sources.responses[name].context, sources.responses)
  end

  -- flatten the items
  local flattened_items = {}
  for name, response in pairs(sources.responses) do
    local source = sources.registered[name]
    if source:should_show_completions(response.context, sources.responses) then
      vim.list_extend(flattened_items, response.items)
    end
  end

  sources.on_completions_callback(sources.current_context, flattened_items)
end

function sources.cancel_completions()
  for _, source in pairs(sources.registered) do
    source:cancel_completions()
  end
end

--- @param item blink.cmp.CompletionItem
--- @param callback fun(resolved_item: blink.cmp.CompletionItem | nil)
--- @return fun(): nil Cancelation function
function sources.resolve(item, callback)
  local item_source = sources.registered[item.source]
  if item_source == nil then
    callback(nil)
    return function() end
  end
  return item_source
    :resolve(item)
    :await(function(success, resolved_item) callback(success and resolved_item or nil) end)
end

return sources
