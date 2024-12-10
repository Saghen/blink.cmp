--- Wraps the sources to respect the configuration options and provide a unified interface
--- @class blink.cmp.SourceProvider
--- @field id string
--- @field name string
--- @field config blink.cmp.SourceProviderConfigWrapper
--- @field module blink.cmp.Source
--- @field list blink.cmp.SourceProviderList | nil
--- @field resolve_tasks table<blink.cmp.CompletionItem, blink.cmp.Task>
---
--- @field new fun(id: string, config: blink.cmp.SourceProviderConfig): blink.cmp.SourceProvider
--- @field enabled fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context): boolean
--- @field get_trigger_characters fun(self: blink.cmp.SourceProvider): string[]
--- @field get_completions fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, on_items: fun(items: blink.cmp.CompletionItem[]))
--- @field should_show_items fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean
--- @field resolve fun(self: blink.cmp.SourceProvider, item: blink.cmp.CompletionItem): blink.cmp.Task
--- @field execute fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, item: blink.cmp.CompletionItem, callback: fun()): blink.cmp.Task
--- @field get_signature_help_trigger_characters fun(self: blink.cmp.SourceProvider): { trigger_characters: string[], retrigger_characters: string[] }
--- @field get_signature_help fun(self: blink.cmp.SourceProvider, context: blink.cmp.SignatureHelpContext): blink.cmp.Task
--- @field reload (fun(self: blink.cmp.SourceProvider): nil) | nil

--- @type blink.cmp.SourceProvider
--- @diagnostic disable-next-line: missing-fields
local source = {}

local async = require('blink.cmp.lib.async')

function source.new(id, config)
  assert(type(config.name) == 'string', 'Each source in config.sources.providers must have a "name" of type string')
  assert(type(config.module) == 'string', 'Each source in config.sources.providers must have a "module" of type string')

  local self = setmetatable({}, { __index = source })
  self.id = id
  self.name = config.name
  self.module = require('blink.cmp.sources.lib.provider.override').new(
    require(config.module).new(config.opts, config),
    config.override
  )
  self.config = require('blink.cmp.sources.lib.provider.config').new(config)
  self.list = nil
  self.resolve_tasks = {}

  return self
end

function source:enabled(context)
  -- user defined
  if not self.config.enabled(context) then return false end

  -- source defined
  if self.module.enabled == nil then return true end
  return self.module:enabled(context)
end

--- Completion ---

function source:get_trigger_characters()
  if self.module.get_trigger_characters == nil then return {} end
  return self.module:get_trigger_characters()
end

function source:get_completions(context, on_items)
  -- return the previous successful completions if the context is the same
  -- and the data doesn't need to be updated
  -- or if the list is async, since we don't want to cause a flash of no items
  if self.list ~= nil and self.list:is_valid_for_context(context) then
    self.list:set_on_items(on_items)
    self.list:emit()
    return
  end

  -- the source indicates we should refetch when this character is typed
  local trigger_character = context.trigger.character
    and vim.tbl_contains(self:get_trigger_characters(), context.trigger.character)

  -- The TriggerForIncompleteCompletions kind is handled by the source provider itself
  local source_context = require('blink.cmp.lib.utils').shallow_copy(context)
  source_context.trigger = trigger_character
      and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger.character }
    or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

  local async_initial_items = self.list ~= nil and self.list.context.id == context.id and self.list.items or {}
  if self.list ~= nil then self.list:destroy() end

  self.list = require('blink.cmp.sources.lib.provider.list').new(
    self,
    context,
    on_items,
    -- HACK: if the source is async, we're not reusing the previous list and the response was marked as incomplete,
    -- the user will see a flash of no items from the provider, since the list emits immediately. So we hack around
    -- this for now
    { async_initial_items = async_initial_items }
  )
end

function source:should_show_items(context, items)
  -- if keyword length is configured, check if the context is long enough
  local min_keyword_length = self.config.min_keyword_length(context)
  local current_keyword_length = context.bounds.length
  if current_keyword_length < min_keyword_length then return false end

  if self.config.should_show_items == nil then return true end
  return self.config.should_show_items(context, items)
end

--- Resolve ---

--- @param item blink.cmp.CompletionItem
--- @return blink.cmp.Task
function source:resolve(item)
  local tasks = self.resolve_tasks
  if tasks[item] == nil or tasks[item].status == async.STATUS.CANCELLED then
    tasks[item] = async.task.new(function(resolve)
      if self.module.resolve == nil then return resolve(item) end
      return self.module:resolve(item, function(resolved_item)
        -- use the item's existing documentation and detail if the LSP didn't return it
        -- TODO: do we need this? this would be for java but never checked if it's needed
        if resolved_item ~= nil and resolved_item.documentation == nil then
          resolved_item.documentation = item.documentation
        end
        if resolved_item ~= nil and resolved_item.detail == nil then resolved_item.detail = item.detail end

        vim.schedule(function() resolve(resolved_item or item) end)
      end)
    end)
  end
  return tasks[item]
end

--- Execute ---

function source:execute(context, item)
  if self.module.execute == nil then return async.task.new(function(resolve) resolve() end) end
  return async.task.new(function(resolve) self.module:execute(context, item, resolve) end)
end

--- Signature help ---

function source:get_signature_help_trigger_characters()
  if self.module.get_signature_help_trigger_characters == nil then
    return { trigger_characters = {}, retrigger_characters = {} }
  end
  return self.module:get_signature_help_trigger_characters()
end

function source:get_signature_help(context)
  return async.task.new(function(resolve)
    if self.module.get_signature_help == nil then return resolve(nil) end
    return self.module:get_signature_help(context, function(signature_help)
      vim.schedule(function() resolve(signature_help) end)
    end)
  end)
end

--- Misc ---

--- For external integrations to force reloading the source
function source:reload()
  if self.module.reload == nil then return end
  self.module:reload()
end

return source
