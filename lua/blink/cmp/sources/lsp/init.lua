local async = require('blink.cmp.lib.async')

--- @type blink.cmp.Source
--- @diagnostic disable-next-line: missing-fields
local lsp = {}

function lsp.new() return setmetatable({}, { __index = lsp }) end

--- Completion ---

function lsp:get_trigger_characters()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local trigger_characters = {}

  for _, client in pairs(clients) do
    local completion_provider = client.server_capabilities.completionProvider
    if completion_provider and completion_provider.triggerCharacters then
      for _, trigger_character in pairs(completion_provider.triggerCharacters) do
        table.insert(trigger_characters, trigger_character)
      end
    end
  end

  return trigger_characters
end

function lsp:get_completions(context, callback)
  local completion_lib = require('blink.cmp.sources.lsp.completion')
  local clients = vim.tbl_filter(
    function(client) return client.server_capabilities and client.server_capabilities.completionProvider end,
    vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/completion' })
  )

  -- TODO: implement a timeout before returning the menu as-is. In the future, it would be neat
  -- to detect slow LSPs and consistently run them async
  local task = async.task
    .await_all(vim.tbl_map(function(client) return completion_lib.get_completion_for_client(context, client) end, clients))
    :map(function(responses)
      local final = { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
      for _, response in ipairs(responses) do
        final.is_incomplete_forward = final.is_incomplete_forward or response.is_incomplete_forward
        final.is_incomplete_backward = final.is_incomplete_backward or response.is_incomplete_backward
        vim.list_extend(final.items, response.items)
      end
      callback(final)
    end)
  return function() task:cancel() end
end

--- Resolve ---

function lsp:resolve(item, callback)
  local client = vim.lsp.get_client_by_id(item.client_id)
  if client == nil or not client.server_capabilities.completionProvider.resolveProvider then
    callback(item)
    return
  end

  -- strip blink specific fields to avoid decoding errors on some LSPs
  item = require('blink.cmp.sources.lib.utils').blink_item_to_lsp_item(item)

  local success, request_id = client.request('completionItem/resolve', item, function(error, resolved_item)
    if error or resolved_item == nil then callback(item) end
    callback(resolved_item)
  end)
  if not success then callback(item) end
  if request_id ~= nil then
    return function() client.cancel_request(request_id) end
  end
end

--- Signature help ---

function lsp:get_signature_help_trigger_characters()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local trigger_characters = {}
  local retrigger_characters = {}

  for _, client in pairs(clients) do
    local signature_help_provider = client.server_capabilities.signatureHelpProvider
    if signature_help_provider and signature_help_provider.triggerCharacters then
      for _, trigger_character in pairs(signature_help_provider.triggerCharacters) do
        table.insert(trigger_characters, trigger_character)
      end
    end
    if signature_help_provider and signature_help_provider.retriggerCharacters then
      for _, retrigger_character in pairs(signature_help_provider.retriggerCharacters) do
        table.insert(retrigger_characters, retrigger_character)
      end
    end
  end

  return { trigger_characters = trigger_characters, retrigger_characters = retrigger_characters }
end

function lsp:get_signature_help(context, callback)
  -- no providers with signature help support
  if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/signatureHelp' }) == 0 then
    callback(nil)
    return function() end
  end

  -- TODO: offset encoding is global but should be per-client
  local first_client = vim.lsp.get_clients({ bufnr = 0 })[1]
  local offset_encoding = first_client and first_client.offset_encoding or 'utf-16'

  local params = vim.lsp.util.make_position_params(nil, offset_encoding)
  params.context = {
    triggerKind = context.trigger.kind,
    triggerCharacter = context.trigger.character,
    isRetrigger = context.is_retrigger,
    activeSignatureHelp = context.active_signature_help,
  }

  -- otherwise, we call all clients
  -- TODO: some LSPs never response (typescript-tools.nvim)
  return vim.lsp.buf_request_all(0, 'textDocument/signatureHelp', params, function(result)
    local signature_helps = {}
    for client_id, res in pairs(result) do
      local signature_help = res.result
      if signature_help ~= nil then
        signature_help.client_id = client_id
        table.insert(signature_helps, signature_help)
      end
    end
    -- todo: pick intelligently
    callback(signature_helps[1])
  end)
end

return lsp
