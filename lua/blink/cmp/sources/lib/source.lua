local utils = require('blink.cmp.sources.lib.utils')
local async = require('blink.cmp.sources.lib.async')
local source = {}

--- @param config blink.cmp.SourceProviderConfig
--- @return blink.cmp.SourceProvider
function source.new(config)
  local self = setmetatable({}, { __index = source })
  self.name = config[1]
  --- @type blink.cmp.Source
  self.module = require(config[1]).new(config.opts or {})
  self.config = config

  self.last_response = nil

  return self
end

--- @return string[]
function source:get_trigger_characters()
  if self.module.get_trigger_characters == nil then return {} end
  return self.module:get_trigger_characters()
end

--- @param context blink.cmp.CompletionContext
--- @return blink.cmp.Task
function source:get_completions(context)
  -- Return the previous successful completions if the context is the same
  -- and the data doesn't need to be updated
  if self.last_response ~= nil and self.last_response.context.id == context.id then
    if utils.should_run_request(context, self.last_response) == false then
      vim.print(self.name .. ': returning cached completions')
      return async.task.new(function(resolve) resolve(self.last_response) end)
    end
  end
  vim.print(self.name .. ': running completions request')

  return async.task
    .new(function(resolve) return self.module:get_completions(context, resolve) end)
    :map(function(response)
      self.last_response = response

      -- add score offset if configured
      for _, item in ipairs(response.items) do
        item.score_offset = (item.score_offset or 0) + (self.config.score_offset or 0)
        item.cursor_column = context.bounds.end_col -- todo: is this correct?
        item.source = self.config[1]
      end

      return response
    end)
end

--- @param response blink.cmp.CompletionResponse
--- @return blink.cmp.CompletionItem[]
function source:filter_completions(response)
  if self.module.filter_completions == nil then return response.items end
  return self.module:filter_completions(response)
end

--- @param response blink.cmp.CompletionResponse
--- @return boolean
function source:should_show_completions(response)
  if self.module.should_show_completions == nil then return true end
  return self.module:should_show_completions(response)
end

--- @param item blink.cmp.CompletionItem
--- @return blink.cmp.Task
function source:resolve(item)
  return async.task.new(function(resolve)
    if self.module.resolve == nil then return resolve(nil) end
    return self.module:resolve(item, resolve)
  end)
end

return source
