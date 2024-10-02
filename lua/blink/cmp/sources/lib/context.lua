local async = require('blink.cmp.sources.lib.async')
local sources_context = {}

--- @param context blink.cmp.Context
--- @param sources_groups blink.cmp.Source[][]
--- @param on_completions_callback fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[])
function sources_context.new(context, sources_groups, on_completions_callback)
  local self = setmetatable({}, { __index = sources_context })
  self.id = context.id
  self.sources_groups = sources_groups

  self.active_request = nil
  self.queued_request_context = nil
  self.last_successful_completions = nil
  --- @type fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[])
  self.on_completions_callback = on_completions_callback

  return self
end

--- @return blink.cmp.CompletionItem[]
function sources_context:get_last_successful_completions() return self.last_successful_completions end

--- @param context blink.cmp.Context
function sources_context:get_completions(context)
  assert(context.id == self.id, 'Requested completions on a sources context with a different context ID')

  if self.active_request ~= nil and self.active_request.status == async.STATUS.RUNNING then
    self.queued_request_context = context
    return
  end

  -- Create a task to get the completions for the first sources group,
  -- falling back to the next sources group iteratively if there are no items
  local request = self:get_completions_for_group(self.sources_groups[1], context)
  for idx, sources_group in ipairs(self.sources_groups) do
    if idx > 1 then
      request = request:map(function(items)
        if #items > 0 then return items end
        return self:get_completions_for_group(sources_group, context)
      end)
    end
  end

  -- Send response upstream and run the queued request, if it exists
  self.active_request = request:map(function(items)
    self.active_request = nil
    self.last_successful_completions = items
    self.on_completions_callback(context, items)

    -- todo: when the queued request results in 100% cached content, we end up
    -- calling the on_completions_callback with the same data, which triggers
    -- unnecessary fuzzy + render updates
    if self.queued_request_context ~= nil then
      local queued_context = self.queued_request_context
      self.queued_request_context = nil
      self:get_completions(queued_context)
    end
  end)
end

--- @param sources_group blink.cmp.Source[]
--- @param context blink.cmp.Context
--- @return blink.cmp.Task
function sources_context:get_completions_for_group(sources_group, context)
  -- get completions for each source in the group
  local tasks = vim.tbl_map(function(source)
    -- the source indicates we should refetch when this character is typed
    local trigger_character = context.trigger.character
      and vim.tbl_contains(source:get_trigger_characters(), context.trigger.character)

    -- The TriggerForIncompleteCompletions kind is handled by the source itself
    local source_context = vim.fn.deepcopy(context)
    source_context.trigger = trigger_character
        and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger.character }
      or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

    return source:get_completions(source_context):catch(function(err)
      vim.print(source.name .. ': failed to get completions with error: ' .. err)
      return { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    end)
  end, sources_group)

  -- wait for all the tasks to complete
  return async.task
    .await_all(tasks)
    :map(function(tasks_results)
      local items = {}
      -- for each task, filter the items and add them to the list
      -- if the source should show the completions
      for idx, task_result in ipairs(tasks_results) do
        if task_result.status == async.STATUS.COMPLETED then
          local source = sources_group[idx]
          --- @type blink.cmp.CompletionResponse
          local response = task_result.result
          response.items = source:filter_completions(response)
          if source:should_show_completions(response) then vim.list_extend(items, response.items) end
        end
      end
      return items
    end)
    :catch(function(err)
      vim.print('failed to get completions for group with error: ' .. err)
      return { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    end)
end

function sources_context:destroy()
  self.on_completions_callback = function() end
  if self.active_request ~= nil then self.active_request:cancel() end
end

return sources_context
