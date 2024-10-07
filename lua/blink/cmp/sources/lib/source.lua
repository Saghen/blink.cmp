local utils = require('blink.cmp.sources.lib.utils')
local async = require('blink.cmp.sources.lib.async')
local source = {}

--- @param config blink.cmp.SourceProviderConfig
function source.new(config)
  local self = setmetatable({}, { __index = source })
  self.name = config[1]
  --- @type blink.cmp.Source
  self.module = require(config[1]).new(config.opts or {})
  self.config = config
  self.last_response = nil

  return self
end

--- Completion ---

--- @return string[]
function source:get_trigger_characters()
  if self.module.get_trigger_characters == nil then return self.config.trigger_characters or {} end
  local trigger_characters = self.module:get_trigger_characters()
  vim.list_extend(trigger_characters, self.config.trigger_characters or {})
  return trigger_characters
end

--- @param context blink.cmp.Context
--- @return blink.cmp.Task
function source:get_completions(context)
  -- Return the previous successful completions if the context is the same
  -- and the data doesn't need to be updated
  if self.last_response ~= nil and self.last_response.context.id == context.id then
    if utils.should_run_request(context, self.last_response) == false then
      return async.task.new(function(resolve) resolve(require('blink.cmp.utils').shallow_copy(self.last_response)) end)
    end
  end

  return async.task
    .new(function(resolve) return self.module:get_completions(context, resolve) end)
    :map(function(response)
      if response == nil then response = { is_incomplete_forward = true, is_incomplete_backward = true, items = {} } end
      response.context = context

      -- add score offset if configured
      for _, item in ipairs(response.items) do
        item.score_offset = (item.score_offset or 0) + (self.config.score_offset or 0)
        item.cursor_column = context.cursor[2]
        item.source = self.config[1]
      end

      self.last_response = require('blink.cmp.utils').shallow_copy(response)
      self.last_response.is_cached = true
      return response
    end)
end

--- @param response blink.cmp.CompletionResponse
--- @return blink.cmp.CompletionItem[]
function source:filter_completions(response)
  if self.module.filter_completions == nil then return response.items end
  return self.module:filter_completions(response)
end

--- @param context blink.cmp.Context
--- @param response blink.cmp.CompletionResponse
--- @return boolean
function source:should_show_completions(context, response)
  -- if keyword length is configured, check if the context is long enough
  local min_keyword_length = self.config.keyword_length or 0
  local current_keyword_length = context.bounds.end_col - context.bounds.start_col
  if self.config.keyword_length ~= nil and current_keyword_length < min_keyword_length then return false end

  if self.module.should_show_completions == nil then return true end
  return self.module:should_show_completions(context, response)
end

--- Resolve ---

--- @param item blink.cmp.CompletionItem
--- @return blink.cmp.Task
function source:resolve(item)
  return async.task.new(function(resolve)
    if self.module.resolve == nil then return resolve(nil) end
    return self.module:resolve(item, function(resolved_item)
      vim.schedule(function() resolve(resolved_item) end)
    end)
  end)
end

--- Signature help ---

--- @return { trigger_characters: string[], retrigger_characters: string[] }
function source:get_signature_help_trigger_characters()
  if self.module.get_signature_help_trigger_characters == nil then
    return { trigger_characters = {}, retrigger_characters = {} }
  end
  return self.module:get_signature_help_trigger_characters()
end

--- @param context blink.cmp.SignatureHelpContext
--- @return blink.cmp.Task
function source:get_signature_help(context)
  return async.task.new(function(resolve)
    if self.module.get_signature_help == nil then return resolve(nil) end
    return self.module:get_signature_help(context, function(signature_help)
      vim.schedule(function() resolve(signature_help) end)
    end)
  end)
end

return source
