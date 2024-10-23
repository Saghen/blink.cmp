local async = require('blink.cmp.sources.lib.async')
local config = require('blink.cmp.config')

--- @class blink.cmp.Sources
--- @field current_context blink.cmp.SourcesContext | nil
--- @field current_signature_help blink.cmp.Task | nil
--- @field sources_registered boolean
--- @field providers table<string, blink.cmp.SourceProvider>
--- @field on_completions_callback fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[])
---
--- @field register fun()
--- @field get_enabled_providers fun(context?: blink.cmp.Context): table<string, blink.cmp.SourceProvider>
--- @field get_trigger_characters fun(): string[]
--- @field request_completions fun(context: blink.cmp.Context)
--- @field cancel_completions fun()
--- @field listen_on_completions fun(callback: fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[]))
--- @field resolve fun(item: blink.cmp.CompletionItem, callback: fun(resolved_item: lsp.CompletionItem | nil)): (fun(): nil) | nil
--- @field get_signature_help_trigger_characters fun(): { trigger_characters: string[], retrigger_characters: string[] }
--- @field get_signature_help fun(context: blink.cmp.SignatureHelpContext, callback: fun(signature_help: lsp.SignatureHelp | nil)): (fun(): nil) | nil
--- @field cancel_signature_help fun()
--- @field reload fun()

--- @type blink.cmp.Sources
--- @diagnostic disable-next-line: missing-fields
local sources = {
  current_context = nil,
  sources_registered = false,
  providers = {},
  on_completions_callback = function(_, _) end,
}

function sources.register()
  assert(not sources.sources_registered, 'Sources have already been registered')
  sources.sources_registered = true

  for key, source_config in pairs(config.sources.providers) do
    sources.providers[key] = require('blink.cmp.sources.lib.provider').new(key, source_config)
  end
end

function sources.get_enabled_providers(context)
  local mode_providers = type(config.sources.completion) == 'function' and config.sources.completion(context)
    or config.sources.completion
  --- @cast mode_providers string[]

  --- @type table<string, blink.cmp.SourceProvider>
  local providers = {}
  for key, provider in pairs(sources.providers) do
    if provider.config.enabled(context) and vim.tbl_contains(mode_providers, key) then providers[key] = provider end
  end
  return providers
end

--- Completion ---

function sources.get_trigger_characters()
  local providers = sources.get_enabled_providers()
  local blocked_trigger_characters = {}
  for _, char in ipairs(config.trigger.completion.blocked_trigger_characters) do
    blocked_trigger_characters[char] = true
  end

  local trigger_characters = {}
  for _, source in pairs(providers) do
    local source_trigger_characters = source:get_trigger_characters()
    for _, char in ipairs(source_trigger_characters) do
      if not blocked_trigger_characters[char] then table.insert(trigger_characters, char) end
    end
  end
  return trigger_characters
end

function sources.listen_on_completions(callback) sources.on_completions_callback = callback end

function sources.request_completions(context)
  -- create a new context if the id changed or if we haven't created one yet
  local is_new_context = sources.current_context == nil or context.id ~= sources.current_context.id
  if is_new_context then
    if sources.current_context ~= nil then sources.current_context:destroy() end
    sources.current_context = require('blink.cmp.sources.lib.context').new(
      context,
      sources.get_enabled_providers(context),
      sources.on_completions_callback
    )
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

function sources.resolve(item, callback)
  local item_source = nil
  for _, source in pairs(sources.providers) do
    if source.id == item.source_id then
      item_source = source
      break
    end
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
  for _, source in pairs(sources.providers) do
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

function sources.get_signature_help(context, callback)
  local tasks = {}
  for _, source in pairs(sources.providers) do
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

--- Misc ---

--- For external integrations to force reloading the source
function sources.reload()
  for _, source in ipairs(sources.providers) do
    source:reload()
  end
end

return sources
