local config = require('blink.cmp.config')
local sources = {
  current_context = nil,
  sources_registered = false,
  sources_groups = {},
  on_completions_callback = function(_, _) end,
}

function sources.register()
  assert(#sources.sources_groups == 0, 'Sources have already been registered')

  for _, sources_group in ipairs(config.sources.providers) do
    local group = {}
    for _, source_config in ipairs(sources_group) do
      table.insert(group, require('blink.cmp.sources.lib.source').new(source_config))
    end
    table.insert(sources.sources_groups, group)
  end
end

--- @return string[]
function sources.get_trigger_characters()
  local blocked_trigger_characters = {}
  for _, char in ipairs(config.trigger.blocked_trigger_characters) do
    blocked_trigger_characters[char] = true
  end

  local trigger_characters = {}
  -- todo: should this be all source groups?
  for _, source in pairs(sources.sources_groups[1]) do
    local source_trigger_characters = source:get_trigger_characters()
    for _, char in ipairs(source_trigger_characters) do
      if not blocked_trigger_characters[char] then table.insert(trigger_characters, char) end
    end
  end
  return trigger_characters
end

function sources.listen_on_completions(callback) sources.on_completions_callback = callback end

--- @param context blink.cmp.Context
function sources.request_completions(context)
  -- a new context means we should refetch everything
  local is_new_context = sources.current_context == nil or context.id ~= sources.current_context.id
  if is_new_context then
    if sources.current_context ~= nil then sources.current_context:destroy() end
    sources.current_context =
      require('blink.cmp.sources.lib.context').new(context, sources.sources_groups, sources.on_completions_callback)
  end

  sources.current_context:get_completions(context)
end

function sources.cancel_completions()
  if sources.current_context ~= nil then sources.current_context:destroy() end
  sources.current_context = nil
end

--- @param item blink.cmp.CompletionItem
--- @param callback fun(resolved_item: blink.cmp.CompletionItem | nil)
--- @return fun(): nil Cancelation function
function sources.resolve(item, callback)
  local item_source = nil
  for _, group in ipairs(sources.sources_groups) do
    for _, source in ipairs(group) do
      if source.name == item.source then
        item_source = source
        break
      end
    end
    if item_source ~= nil then break end
  end

  if item_source == nil then
    callback(nil)
    return function() end
  end
  return item_source:resolve(item):map(function(resolved_item) callback(resolved_item) end):catch(function(err)
    vim.print('failed to resolve item with error: ' .. err)
    callback(nil)
  end)
end

return sources
