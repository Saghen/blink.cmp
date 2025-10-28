local async = require('blink.cmp.lib.async')
local lsp = require('blink.cmp.lsp')

local queue = {}

--- @param context blink.cmp.Context
--- @param on_completions_callback fun(context: blink.cmp.Context, responses: table<integer, lsp.CompletionItem[]>)
--- @return blink.cmp.SourcesQueue
function queue.new(context, on_completions_callback)
  local self = setmetatable({}, { __index = queue })
  self.id = context.id

  self.request = nil
  self.queued_request_context = nil
  self.on_completions_callback = on_completions_callback

  return self
end

--- @return table<integer, lsp.CompletionItem[]>?
function queue:get_cached_completions() return self.cached_items_by_lsp end

--- @param context blink.cmp.Context
function queue:get_completions(context)
  assert(context.id == self.id, 'Requested completions on a sources context with a different context ID')

  if self.request ~= nil then
    -- already running, queue the request
    if self.request.status == async.STATUS.RUNNING then
      self.queued_request_context = context
      return
    end
    self.request:cancel()
  end

  local get_completions = require('blink.cmp.lsp.client.completion')
  local tasks = vim.tbl_map(
    function(client) return get_completions(context, client) end,
    lsp.get_clients({ method = 'textDocument/completion' })
  )

  self.request = async.task.all(tasks):map(function(responses)
    local items_by_lsp = {} --- @type table<integer, lsp.CompletionItem[]>
    for _, response in ipairs(responses) do
      items_by_lsp[response.client_id] = response.items
    end

    self.cached_items_by_lsp = items_by_lsp
    self.on_completions_callback(context, items_by_lsp)

    -- run the queued request, if it exists
    local queued_context = self.queued_request_context
    if queued_context ~= nil then
      self.queued_request_context = nil
      self.request:cancel()
      self:get_completions(queued_context)
    end
  end)
end

function queue:destroy()
  --- @type fun(context: blink.cmp.Context, items: table<string, lsp.CompletionItem[]>)
  self.on_completions_callback = function(_, _) end
  if self.request ~= nil then self.request:cancel() end
end

return queue
