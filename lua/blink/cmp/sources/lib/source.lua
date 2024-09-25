local utils = require('blink.cmp.sources.lib.utils')
local async = require('blink.cmp.sources.lib.async')
--- @type blink.cmp.SourceProvider
local source = {}

--- @param config blink.cmp.SourceProviderConfig
--- @return blink.cmp.SourceProvider
function source.new(config)
  local self = setmetatable({}, { __index = source })
  self.name = config[1]
  self.module = require(config[1]).new(config.opts or {})
  self.config = config
  self.completions_task = nil
  self.completions_task_context = nil
  self.completions_queue_task_context = nil
  self.on_completions_callback = function() end

  return self
end

function source:get_trigger_characters()
  if self.module.get_trigger_characters == nil then return {} end
  return self.module:get_trigger_characters()
end

function source:request_completions(context)
  if self.completions_task ~= nil and self.completions_task_context ~= nil then
    local is_new_context = self.completions_task_context.id ~= context.id
    vim.print(
      self.name .. ': is_new_context: ' .. tostring(is_new_context) .. ' | status: ' .. self.completions_task.status
    )

    -- cancel in-flight completions task if we have a new context
    -- TODO: also cancel if we know for sure, that the data will be out of date
    -- potentially by having the sources inform us whether results will be complete backwards/forwards or not
    if is_new_context then
      self:cancel_completions()

    -- already running for this context, so queue this request, replacing any previously queued request
    elseif self.completions_task.status == async.STATUS.RUNNING then
      self.completions_queue_task_context = context
      return

    -- already ran for this context, check if we can ignore the request due to cached content
    elseif self.completions_task.status == async.STATUS.COMPLETED then
      local response = self.completions_task.result
      if utils.should_run_request(response.context, context, response) == false then return end
    end
  end

  self:get_completions(context)
end

function source:get_completions(context)
  vim.print(self.name .. ': running completions request')
  self.completions_task_context = context
  self.completions_task = async.task
    .new(self.module.get_completions, self.module, context)
    :map(function(response)
      response.context = context

      -- add score offset if configured
      for _, item in ipairs(response.items) do
        item.score_offset = self.config.score_offset
        item.cursor_column = context.end_col -- todo: is this correct?
        item.source = self.config[1]
      end

      return response
    end)
    :map_error(function()
      -- TODO: log error
      return { context = context, is_incomplete_forward = true, is_incomplete_backward = true, items = {} }
    end)
    :await(function(success, response)
      if success then
        self.on_completions_callback(response)
      else
        vim.print(self.name .. ': failed to load completions')
      end -- TODO: error logging

      -- run the queued completions request, if necessary
      local queued_context = self.completions_queue_task_context
      self.completions_queue_task_context = nil
      local should_run_request = queued_context ~= nil and utils.should_run_request(context, queued_context, response)
      if should_run_request ~= false then
        if should_run_request == 'backward' then
          queued_context.trigger = { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerForIncompleteCompletions }
        end
        vim.print(self.name .. ': found completion request in queue')
        self:get_completions(queued_context)
      end
    end)
end

function source:listen_on_completions(cb) self.on_completions_callback = cb end

function source:cancel_completions()
  if self.completions_task ~= nil then self.completions_task:cancel() end
  self.completions_task = nil
  self.completions_task_context = nil
  self.completions_queue_task_context = nil
end

function source:filter_completions(context, source_responses)
  if self.module.filter_completions == nil then return source_responses end
  return self.module:filter_completions(context, source_responses)
end

function source:should_show_completions(context, source_responses)
  if self.module.should_show_completions == nil then return true end
  return self.module:should_show_completions(context, source_responses)
end

function source:resolve(item)
  if self.module.resolve == nil then return async.task.new(function(cb) cb(nil) end) end
  return async.task.new(self.module.resolve, self.module, item)
end

return source
