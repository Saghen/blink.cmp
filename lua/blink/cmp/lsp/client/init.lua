local async = require('blink.cmp.lib.async')
local lsp = require('blink.cmp.lsp')
local utils = require('blink.cmp.lib.utils')

local clients = {
  signature = require('blink.cmp.lsp.client.signature'),
}

function clients.get_trigger_characters()
  local trigger_characters = {}
  for _, client in ipairs(lsp.get_clients({ bufnr = 0 })) do
    if client.server_capabilities.completionProvider ~= nil then
      vim.list_extend(trigger_characters, client.server_capabilities.completionProvider.triggerCharacters or {})
    end
  end
  return utils.deduplicate(trigger_characters)
end

--- @param context blink.cmp.Context
--- @param _items_by_provider table<string, lsp.CompletionItem[]>
function clients.emit_completions(context, _items_by_provider)
  local items_by_provider = {}
  for name, items in pairs(_items_by_provider) do
    if lsp.config[name].should_show_items(context, items) then items_by_provider[name] = items end
  end
  clients.completions_emitter:emit({ context = context, items = items_by_provider })
end

--- @param context blink.cmp.Context
function clients.get_completions(context)
  -- create a new context if the id changed or if we haven't created one yet
  if clients.completions_queue == nil or context.id ~= clients.completions_queue.id then
    if clients.completions_queue ~= nil then clients.completions_queue:destroy() end
    clients.completions_queue = require('blink.cmp.lsp.client.queue').new(context, clients.emit_completions)

  -- send cached completions if they exist to immediately trigger updates
  elseif clients.completions_queue:get_cached_completions() ~= nil then
    clients.emit_completions(context, clients.completions_queue:get_cached_completions() or {})
  end

  clients.completions_queue:get_completions(context)
end

--- Limits the number of items per LSP as configured
function clients.apply_max_items(context, items)
  -- get the configured max items for each LSP
  local total_items_for_lsps = {}
  local max_items_for_lsps = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local max_items = lsp.config[client.name].max_items(context, items)
    if max_items ~= nil then
      max_items_for_lsps[client.name] = max_items
      total_items_for_lsps[client.name] = 0
    end
  end

  -- no max items configured, return as-is
  if #vim.tbl_keys(max_items_for_lsps) == 0 then return items end

  -- apply max items
  local filtered_items = {}
  for _, item in ipairs(items) do
    local max_items = max_items_for_lsps[item.blink.client_name]
    total_items_for_lsps[item.blink.client_name] = total_items_for_lsps[item.blink.client_name] + 1
    if max_items == nil or total_items_for_lsps[item.blink.client_name] <= max_items then
      table.insert(filtered_items, item)
    end
  end
  return filtered_items
end

function clients.resolve(item)
  local client = vim.lsp.get_client_by_id(item.blink.client_id)
  if client == nil then return async.task.identity(item) end

  local lsp_item = vim.deepcopy(item)
  lsp_item.blink = nil

  return async.task.new(function(resolve, reject)
    client:request('completionItem/resolve', lsp_item, function(err, resolved_item)
      if err then
        return reject(err)
      elseif resolved_item ~= nil then
        resolved_item.blink = item.blink
        resolve(resolved_item)
      else
        resolve(item)
      end
    end)
  end)
end

return clients
