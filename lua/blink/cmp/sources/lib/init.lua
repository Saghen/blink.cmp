local async = require('blink.cmp.sources.lib.async')
local nvim_cmp_registry = require('blink.cmp.sources.lib.nvim_cmp_registry')
local config = require('blink.cmp.config')
local sources = {
  current_context = nil,
  sources_registered = false,
  sources_groups = {},
  on_completions_callback = function(_, _) end,
  nvim_cmp_registry = nvim_cmp_registry.new(),
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

--- Completion ---

--- @return string[]
function sources.get_trigger_characters()
  local blocked_trigger_characters = {}
  for _, char in ipairs(config.trigger.completion.blocked_trigger_characters) do
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
  -- create a new context if the id changed or if we haven't created one yet
  local is_new_context = sources.current_context == nil or context.id ~= sources.current_context.id
  if is_new_context then
    if sources.current_context ~= nil then sources.current_context:destroy() end
    sources.current_context =
      require('blink.cmp.sources.lib.context').new(context, sources.sources_groups, sources.on_completions_callback)
  end

  sources.current_context:get_completions(context)
end

function sources.cancel_completions()
  if sources.current_context ~= nil then
    sources.current_context:destroy()
    sources.current_context = nil
  end
end

--- Resolve ---

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

--- Signature help ---

--- @return { trigger_characters: string[], retrigger_characters: string[] }
function sources.get_signature_help_trigger_characters()
  local blocked_trigger_characters = {}
  local blocked_retrigger_characters = {}
  for _, char in ipairs(config.trigger.signature_help.blocked_trigger_characters) do
    blocked_trigger_characters[char] = true
  end
  for _, char in ipairs(config.trigger.signature_help.blocked_retrigger_characters) do
    blocked_retrigger_characters[char] = true
  end

  local trigger_characters = {}
  local retrigger_characters = {}

  -- todo: should this be all source groups?
  for _, source in ipairs(sources.sources_groups[1]) do
    local res = source:get_signature_help_trigger_characters()
    for _, char in ipairs(res.trigger_characters) do
      if not blocked_trigger_characters[char] then table.insert(trigger_characters, char) end
    end
    for _, char in ipairs(res.retrigger_characters) do
      if not blocked_retrigger_characters[char] then table.insert(retrigger_characters, char) end
    end
  end
  return { trigger_characters = trigger_characters, retrigger_characters = retrigger_characters }
end

--- @param context blink.cmp.SignatureHelpContext
--- @param callback fun(signature_helps: lsp.SignatureHelp)
function sources.get_signature_help(context, callback)
  local tasks = {}
  for _, source in ipairs(sources.sources_groups[1]) do
    table.insert(tasks, source:get_signature_help(context))
  end
  sources.current_signature_help = async.task.await_all(tasks):map(function(tasks_results)
    local signature_helps = {}
    for _, task_result in ipairs(tasks_results) do
      if task_result.status == async.STATUS.COMPLETED and task_result.result ~= nil then
        table.insert(signature_helps, task_result.result)
      end
    end
    callback(signature_helps[1])
  end)
end

function sources.cancel_signature_help()
  if sources.current_signature_help ~= nil then
    sources.current_signature_help:cancel()
    sources.current_signature_help = nil
  end
end

return sources
