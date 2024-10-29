--- Wraps the sources to respect the configuration options and provide a unified interface
--- @class blink.cmp.SourceProvider
--- @field id string
--- @field name string
--- @field config blink.cmp.SourceProviderConfigWrapper
--- @field module blink.cmp.Source
--- @field last_response blink.cmp.CompletionResponse | nil
--- @field resolve_tasks table<blink.cmp.CompletionItem, blink.cmp.Task>
---
--- @field new fun(id: string, config: blink.cmp.SourceProviderConfig): blink.cmp.SourceProvider
--- @field enabled fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context): boolean
--- @field get_trigger_characters fun(self: blink.cmp.SourceProvider): string[]
--- @field get_completions fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, enabled_sources: string[]): blink.cmp.Task
--- @field should_show_items fun(self: blink.cmp.SourceProvider, context: blink.cmp.Context, enabled_sources: string[], response: blink.cmp.CompletionResponse): boolean
--- @field resolve fun(self: blink.cmp.SourceProvider, item: blink.cmp.CompletionItem): blink.cmp.Task
--- @field get_signature_help_trigger_characters fun(self: blink.cmp.SourceProvider): string[]
--- @field get_signature_help fun(self: blink.cmp.SourceProvider, context: blink.cmp.SignatureHelpContext): blink.cmp.Task
--- @field reload (fun(self: blink.cmp.SourceProvider): nil) | nil

--- @type blink.cmp.SourceProvider
--- @diagnostic disable-next-line: missing-fields
local source = {}

local utils = require('blink.cmp.sources.lib.utils')
local async = require('blink.cmp.sources.lib.async')

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

function source:get_completions(context, enabled_sources)
  -- Return the previous successful completions if the context is the same
  -- and the data doesn't need to be updated
  if self.last_response ~= nil and self.last_response.context.id == context.id then
    if utils.should_run_request(context, self.last_response) == false then
      return async.task.new(function(resolve) resolve(require('blink.cmp.utils').shallow_copy(self.last_response)) end)
    end
  end

  return async.task
    .new(function(resolve)
      if self.module.get_completions == nil then return resolve() end
      return self.module:get_completions(context, resolve)
    end)
    :map(function(response)
      if response == nil then response = { is_incomplete_forward = true, is_incomplete_backward = true, items = {} } end
      response.context = context

      -- add non-lsp metadata
      local source_score_offset = self.config.score_offset(context, enabled_sources) or 0
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

      self.last_response = require('blink.cmp.utils').shallow_copy(response)
      self.last_response.is_cached = true
      return response
    end)
    :catch(function(err)
      vim.print('failed to get completions with error: ' .. err)
      return { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    end)
end

function source:should_show_items(context, enabled_sources, response)
  -- if keyword length is configured, check if the context is long enough
  local min_keyword_length = self.config.min_keyword_length(context, enabled_sources)
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
