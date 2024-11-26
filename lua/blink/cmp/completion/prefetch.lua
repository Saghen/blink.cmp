-- Run `resolve` on the item ahead of time to avoid delays
-- when accepting the item or showing documentation

local last_context_id = nil
local last_request = nil
local timer = vim.uv.new_timer()

--- @param context blink.cmp.Context
--- @param item blink.cmp.CompletionItem
local function prefetch_resolve(context, item)
  if not item then return end

  local resolve = vim.schedule_wrap(function()
    if last_request ~= nil then last_request:cancel() end
    last_request = require('blink.cmp.sources.lib').resolve(item)
  end)

  -- immediately resolve if the context has changed
  if last_context_id ~= context.id then
    last_context_id = context.id
    resolve()
  end

  -- otherwise, wait for the debounce period
  timer:stop()
  timer:start(50, 0, resolve)
end

return prefetch_resolve
