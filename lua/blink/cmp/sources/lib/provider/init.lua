--- Wraps the sources to respect the configuration options and provide a unified interface
--- @class blink.cmp.SourceProvider
--- @field id string
--- @field name string
--- @field config blink.cmp.SourceProviderConfigWrapper
--- @field module blink.cmp.Source
--- @field last_response blink.cmp.CompletionResponse | nil
--- @field last_context blink.cmp.Context | nil
--- @field resolve_tasks table<blink.cmp.CompletionItem, blink.cmp.Task>
---
--- @field new fun(id: string, config: blink.cmp.SourceProviderConfig): blink.cmp.SourceProvider
--- @field enabled fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context): boolean
--- @field get_trigger_characters fun(self: blink.cmp.SourceProvider): string[]
--- @field get_completions fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context): blink.cmp.Task
--- @field should_show_items fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, response: blink.cmp.CompletionResponse): boolean
--- @field resolve fun(self: blink.cmp.SourceProvider, item: blink.cmp.CompletionItem): blink.cmp.Task
--- @field execute fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, item: blink.cmp.CompletionItem, callback: fun()): blink.cmp.Task
--- @field get_signature_help_trigger_characters fun(self: blink.cmp.SourceProvider): { trigger_characters: string[], retrigger_characters: string[] }
--- @field get_signature_help fun(self: blink.cmp.SourceProvider, context: blink.cmp.SignatureHelpContext): blink.cmp.Task
--- @field reload (fun(self: blink.cmp.SourceProvider): nil) | nil

--- @type blink.cmp.SourceProvider
--- @diagnostic disable-next-line: missing-fields
local source = {}

local utils = require('blink.cmp.sources.lib.utils')
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
  self.last_response = nil
  self.last_context = nil
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

function source:get_completions(context)
  -- Return the previous successful completions if the context is the same
  -- and the data doesn't need to be updated
  if self.last_response ~= nil and self.last_context ~= nil and self.last_context.id == context.id then
    if utils.should_run_request(context, self.last_context, self.last_response) == false then
      return async.task.new(
        function(resolve)
          resolve({
            cached = true,
            response = self.last_response,
          })
        end
      )
    end
  end

  -- the source indicates we should refetch when this character is typed
  local trigger_character = context.trigger.character
    and vim.tbl_contains(self:get_trigger_characters(), context.trigger.character)

  -- The TriggerForIncompleteCompletions kind is handled by the source provider itself
  local source_context = require('blink.cmp.lib.utils').shallow_copy(context)
  source_context.trigger = trigger_character
      and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger.character }
    or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

  return async.task
    .new(function(resolve)
      if self.module.get_completions == nil then return resolve() end
      return self.module:get_completions(source_context, resolve)
    end)
    :map(function(response)
      if response == nil then response = { is_incomplete_forward = true, is_incomplete_backward = true, items = {} } end

      -- add non-lsp metadata
      local source_score_offset = self.config.score_offset(context) or 0
      for _, item in ipairs(response.items) do
        item.score_offset = (item.score_offset or 0) + source_score_offset
        item.cursor_column = context.cursor[2]
        item.source_id = self.id
        item.source_name = self.name
      end

      -- if the user provided a transform_items function, run it
      if self.config.transform_items ~= nil then
        response.items = self.config.transform_items(context, response.items)
      end

      self.last_response = response
      self.last_context = context
      return { cached = false, response = response }
    end)
    :catch(function(err)
      vim.print('failed to get completions with error: ' .. err)
      return { cached = false, { is_incomplete_forward = false, is_incomplete_backward = false, items = {} } }
    end)
end

function source:should_show_items(context, response)
  -- if keyword length is configured, check if the context is long enough
  local min_keyword_length = self.config.min_keyword_length(context)
  local current_keyword_length = context.bounds.length
  if current_keyword_length < min_keyword_length then return false end

  if self.config.should_show_items == nil then return true end
  return self.config.should_show_items(context, response.items)
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
