local async = require('blink.cmp.lib.async')

local signature = {
  last_request_client = nil,
  last_request_id = nil,
}

function signature.get_trigger_characters()
  local trigger_characters = {}
  local retrigger_characters = {}

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.server_capabilities.signatureHelpProvider ~= nil then
      vim.list_extend(trigger_characters, client.server_capabilities.signatureHelpProvider.triggerCharacters or {})
      vim.list_extend(retrigger_characters, client.server_capabilities.signatureHelpProvider.retriggerCharacters or {})
    end
  end

  return { trigger_characters = trigger_characters, retrigger_characters = retrigger_characters }
end

function signature.get_signature_help(context)
  local tasks = vim.tbl_map(function(client)
    local offset_encoding = client.offset_encoding or 'utf-16'

    local params = vim.lsp.util.make_position_params(nil, offset_encoding)
    params.context = {
      triggerKind = context.trigger.kind,
      triggerCharacter = context.trigger.character,
      isRetrigger = context.is_retrigger,
      activeSignatureHelp = context.active_signature_help,
    }

    return client:request('textDocument/signatureHelp', context.params)
  end, vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/signatureHelp' }))

  return async.task.all(tasks):map(function(signature_helps)
    return vim.tbl_filter(function(signature_help) return signature_help ~= nil end, signature_helps)
  end)
end

return signature
