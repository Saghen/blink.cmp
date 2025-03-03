--- @class blink.cmp.LSPCacheEntry
--- @field context blink.cmp.Context
--- @field response blink.cmp.CompletionResponse

--- @class blink.cmp.LSPCache
local cache = {
  --- @type table<number, blink.cmp.LSPCacheEntry>
  entries = {},
}

function cache.get(context, client)
  local entry = cache.entries[client.id]
  if entry == nil then return end

  if context.id ~= entry.context.id then return end
  if entry.response.is_incomplete_forward and entry.context.cursor[2] ~= context.cursor[2] then return end
  if not entry.response.is_incomplete_forward and entry.context.cursor[2] > context.cursor[2] then return end

  return entry.response
end

--- @param context blink.cmp.Context
--- @param client vim.lsp.Client
--- @param response blink.cmp.CompletionResponse
function cache.set(context, client, response)
  cache.entries[client.id] = {
    context = context,
    response = response,
  }
end

return cache
