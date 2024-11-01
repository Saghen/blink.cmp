local utils = require('blink.cmp.sources.lib.utils')
local async = require('blink.cmp.sources.lib.async')

--- @class blink.cmp.SourcesContext
--- @field id number
--- @field sources table<string, blink.cmp.SourceProvider>
--- @field active_request blink.cmp.Task | nil
--- @field queued_request_context blink.cmp.Context | nil
--- @field cached_responses table<string, blink.cmp.CompletionResponse> | nil
--- @field on_completions_callback fun(context: blink.cmp.Context, enabled_sources: string[], responses: table<string, blink.cmp.CompletionResponse>)
---
--- @field new fun(context: blink.cmp.Context, sources: table<string, blink.cmp.SourceProvider>, on_completions_callback: fun(context: blink.cmp.Context, items: table<string, blink.cmp.CompletionResponse>)): blink.cmp.SourcesContext
--- @field get_sources fun(self: blink.cmp.SourcesContext): string[]
--- @field get_cached_completions fun(self: blink.cmp.SourcesContext): table<string, blink.cmp.CompletionResponse> | nil
--- @field get_completions fun(self: blink.cmp.SourcesContext, context: blink.cmp.Context)
--- @field get_completions_for_sources fun(self: blink.cmp.SourcesContext, sources: table<string, blink.cmp.SourceProvider>, context: blink.cmp.Context): blink.cmp.Task
--- @field get_completions_with_fallbacks fun(self: blink.cmp.SourcesContext, context: blink.cmp.Context, source: blink.cmp.SourceProvider, sources: table<string, blink.cmp.SourceProvider>): blink.cmp.Task
--- @field destroy fun(self: blink.cmp.SourcesContext)

--- @type blink.cmp.SourcesContext
--- @diagnostic disable-next-line: missing-fields
local sources_context = {}

function sources_context.new(context, sources, on_completions_callback)
  local self = setmetatable({}, { __index = sources_context })
  self.id = context.id
  self.sources = sources

  self.active_request = nil
  self.queued_request_context = nil
  self.on_completions_callback = on_completions_callback

  return self
end

function sources_context:get_sources() return vim.tbl_keys(self.sources) end

function sources_context:get_cached_completions() return self.cached_responses end

function sources_context:get_completions(context)
  assert(context.id == self.id, 'Requested completions on a sources context with a different context ID')

  if self.active_request ~= nil and self.active_request.status == async.STATUS.RUNNING then
    self.queued_request_context = context
    return
  end

  -- Create a task to get the completions, send responses upstream
  -- and run the queued request, if it exists
  self.active_request = self:get_completions_for_sources(self.sources, context):map(function(responses)
    self.cached_responses = responses
    --- @cast responses table<string, blink.cmp.CompletionResponse>
    self.active_request = nil

    -- only send upstream if the responses contain something new
    local is_cached = true
    for _, response in pairs(responses) do
      is_cached = is_cached and (response.is_cached or false)
    end
    if not is_cached then self.on_completions_callback(context, self:get_sources(), responses) end

    -- run the queued request, if it exists
    if self.queued_request_context ~= nil then
      local queued_context = self.queued_request_context
      self.queued_request_context = nil
      self:get_completions(queued_context)
    end
  end)
end

function sources_context:get_completions_for_sources(sources, context)
  local enabled_sources = vim.tbl_keys(sources)
  --- @type blink.cmp.SourceProvider[]
  local non_fallback_sources = vim.tbl_filter(function(source)
    local fallbacks = source.config.fallback_for and source.config.fallback_for(context, enabled_sources) or {}
    fallbacks = vim.tbl_filter(function(fallback) return sources[fallback] end, fallbacks)
    return #fallbacks == 0
  end, vim.tbl_values(sources))

  -- get completions for each non-fallback source
  local tasks = vim.tbl_map(function(source)
    -- the source indicates we should refetch when this character is typed
    local trigger_character = context.trigger.character
      and vim.tbl_contains(source:get_trigger_characters(), context.trigger.character)

    -- The TriggerForIncompleteCompletions kind is handled by the source provider itself
    local source_context = require('blink.cmp.utils').shallow_copy(context)
    source_context.trigger = trigger_character
        and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger.character }
      or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

    return self:get_completions_with_fallbacks(source_context, source, sources)
  end, non_fallback_sources)

  -- wait for all the tasks to complete
  return async.task
    .await_all(tasks)
    :map(function(tasks_results)
      local responses = {}
      for idx, task_result in ipairs(tasks_results) do
        if task_result.status == async.STATUS.COMPLETED then
          --- @type blink.cmp.SourceProvider
          local source = vim.tbl_values(non_fallback_sources)[idx]
          responses[source.id] = task_result.result
        end
      end
      return responses
    end)
    :catch(function(err)
      vim.print('failed to get completions for sources with error: ' .. err)
      return {}
    end)
end

--- Runs the source's get_completions function, falling back to other sources
--- with fallback_for = { source.name } if the source returns no completion items
--- TODO: When a source has multiple fallbacks, we may end up with duplicate completion items
function sources_context:get_completions_with_fallbacks(context, source, sources)
  local enabled_sources = vim.tbl_keys(sources)
  local fallback_sources = vim.tbl_filter(
    function(fallback_source)
      return fallback_source.id ~= source.id
        and fallback_source.config.fallback_for ~= nil
        and vim.tbl_contains(fallback_source.config.fallback_for(context), source.id)
    end,
    vim.tbl_values(sources)
  )

  return source:get_completions(context, enabled_sources):map(function(response)
    -- source returned completions, no need to fallback
    if #response.items > 0 or #fallback_sources == 0 then return response end

    -- run fallbacks
    return async.task
      .await_all(vim.tbl_map(function(fallback) return fallback:get_completions(context) end, fallback_sources))
      :map(function(task_results)
        local successful_task_results = vim.tbl_filter(
          function(task_result) return task_result.status == async.STATUS.COMPLETED end,
          task_results
        )
        local fallback_responses = vim.tbl_map(
          function(task_result) return task_result.result end,
          successful_task_results
        )
        return utils.concat_responses(fallback_responses)
      end)
  end)
end

function sources_context:destroy()
  self.on_completions_callback = function() end
  if self.active_request ~= nil then self.active_request:cancel() end
end

return sources_context
