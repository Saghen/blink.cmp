local async = require('blink.cmp.lib.async')

--- @class blink.cmp.SourcesContext
--- @field id number
--- @field sources table<string, blink.cmp.SourceProvider>
--- @field active_request blink.cmp.Task | nil
--- @field queued_request_context blink.cmp.Context | nil
--- @field cached_responses table<string, blink.cmp.CompletionResponse> | nil
--- @field on_completions_callback fun(context: blink.cmp.Context, responses: table<string, blink.cmp.CompletionResponse>)
---
--- @field new fun(context: blink.cmp.Context, sources: table<string, blink.cmp.SourceProvider>, on_completions_callback: fun(context: blink.cmp.Context, responses: table<string, blink.cmp.CompletionResponse>)): blink.cmp.SourcesContext
--- @field get_cached_completions fun(self: blink.cmp.SourcesContext): table<string, blink.cmp.CompletionResponse> | nil
--- @field get_completions fun(self: blink.cmp.SourcesContext, context: blink.cmp.Context)
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

function sources_context:get_cached_completions() return self.cached_responses end

function sources_context:get_completions(context)
  assert(context.id == self.id, 'Requested completions on a sources context with a different context ID')

  if self.active_request ~= nil and self.active_request.status == async.STATUS.RUNNING then
    self.queued_request_context = context
    return
  end

  -- Create a task to get the completions, send responses upstream
  -- and run the queued request, if it exists
  local sources_tree = require('blink.cmp.sources.lib.tree').new(context, vim.tbl_values(self.sources))
  self.active_request = sources_tree:get_completions(context):map(function(result)
    self.cached_responses = result.responses
    self.active_request = nil

    -- only send upstream if the responses contain something new
    if not result.cached then self.on_completions_callback(context, result.responses) end

    -- run the queued request, if it exists
    local queued_context = self.queued_request_context
    if queued_context ~= nil then
      self.queued_request_context = nil
      self:get_completions(queued_context)
    end
  end)
end

function sources_context:destroy()
  self.on_completions_callback = function() end
  if self.active_request ~= nil then self.active_request:cancel() end
end

return sources_context
