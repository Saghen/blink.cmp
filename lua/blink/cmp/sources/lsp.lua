local known_defaults = {
  'commitCharacters',
  'insertTextFormat',
  'insertTextMode',
  'data',
}
local CompletionTriggerKind = vim.lsp.protocol.CompletionTriggerKind

--- @type blink.cmp.Source
--- @diagnostic disable-next-line: missing-fields
local lsp = {}

function lsp.new() return setmetatable({}, { __index = lsp }) end

---@param capability string|table|nil Server capability (possibly nested
---   supplied via table) to check.
---
---@return boolean Whether at least one LSP client supports `capability`.
---@private
function lsp:has_capability(capability)
  for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local has_capability = client.server_capabilities[capability]
    if has_capability then return true end
  end
  return false
end

--- @param method string
--- @return boolean Whether at least one LSP client supports `method`
--- @private
function lsp:has_method(method) return #vim.lsp.get_clients({ bufnr = 0, method = method }) > 0 end

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

--- @param capability string
--- @param filter? table
--- @return vim.lsp.Client[]
function lsp:get_clients_with_capability(capability, filter)
  local clients = {}
  for _, client in pairs(vim.lsp.get_clients(filter)) do
    local capabilities = client.server_capabilities or {}
    if capabilities[capability] then table.insert(clients, client) end
  end
  return clients
end

function lsp:get_completions(context, callback)
  local clients =
    self:get_clients_with_capability('completionProvider', { bufnr = 0, method = 'textDocument/completion' })

  -- no clients with completion support
  if #clients == 0 then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return function() end
  end

  -- request from each client individually so slow LSPs don't delay the response
  local cancel_fns = {}
  for _, client in pairs(clients) do
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = { triggerKind = context.trigger.kind }
    if context.trigger.kind == CompletionTriggerKind.TriggerCharacter then
      params.context.triggerCharacter = context.trigger.character
    end

    local _, request_id = client.request('textDocument/completion', params, function(err, result)
      if err or result == nil then
        callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
        return
      end

      local items = result.items or result
      local default_edit_range = result.itemDefaults and result.itemDefaults.editRange
      for _, item in ipairs(items) do
        item.client_id = client.id

        -- score offset for deprecated items
        -- todo: make configurable
        if item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) then item.score_offset = -2 end

        -- set defaults
        for key, value in pairs(result.itemDefaults or {}) do
          if vim.tbl_contains(known_defaults, key) then item[key] = item[key] or value end
        end
        if default_edit_range and item.textEdit == nil then
          local new_text = item.textEditText or item.insertText or item.label
          if default_edit_range.replace ~= nil then
            item.textEdit = {
              replace = default_edit_range.replace,
              insert = default_edit_range.insert,
              newText = new_text,
            }
          else
            item.textEdit = {
              range = result.itemDefaults.editRange,
              newText = new_text,
            }
          end
        end
      end

      callback({
        is_incomplete_forward = result.isIncomplete or false,
        is_incomplete_backward = true,
        items = items,
      })
    end)
    if request_id ~= nil then cancel_fns[#cancel_fns + 1] = function() client.cancel_request(request_id) end end
  end

  return function()
    for _, cancel_fn in ipairs(cancel_fns) do
      cancel_fn()
    end
  end
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
  if not self:has_method('textDocument/signatureHelp') then
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
