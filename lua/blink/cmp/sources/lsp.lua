--- @class blink.cmp.Source
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

function lsp:get_clients_with_capability(capability, filter)
  local clients = {}
  for _, client in pairs(vim.lsp.get_clients(filter)) do
    local capabilities = client.server_capabilities or {}
    if capabilities[capability] then table.insert(clients, client) end
  end
  return clients
end

function lsp:get_completions(context, callback)
  -- todo: offset encoding is global but should be per-client
  -- todo: should make separate LSP requests to return results earlier, in the case of slow LSPs

  -- no providers with completion support
  if not self:has_capability('completionProvider') then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return function() end
  end

  -- completion context with additional info about how it was triggered
  local params = vim.lsp.util.make_position_params()
  params.context = {
    triggerKind = context.trigger.kind,
  }
  if context.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter then
    params.context.triggerCharacter = context.trigger.character
  end

  -- special case, the first character of the context is a trigger character, so we adjust the position
  -- sent to the LSP server to be the start of the trigger character
  --
  -- some LSP do their own filtering before returning results, which we want to avoid
  -- since we perform fuzzy matching ourselves.
  --
  -- this also avoids having to make multiple calls to the LSP server in case characters are deleted
  -- for these special cases
  -- i.e. hello.wor| would be sent as hello.|wor
  -- todo: should we still make two calls to the LSP server and merge?
  -- todo: breaks the textEdit resolver since it assumes the request was made from the cursor
  -- local trigger_characters = self:get_trigger_characters()
  -- local trigger_character_block_list = { ' ', '\n', '\t' }
  -- local bounds = context.bounds
  -- local trigger_character_before_context = context.line:sub(bounds.start_col - 1, bounds.start_col - 1)
  -- if
  --   vim.tbl_contains(trigger_characters, trigger_character_before_context)
  --   and not vim.tbl_contains(trigger_character_block_list, trigger_character_before_context)
  -- then
  --   local offset_encoding = vim.lsp.get_clients({ bufnr = 0 })[1].offset_encoding
  --   params.position.character =
  --     vim.lsp.util.character_offset(0, params.position.line, bounds.start_col - 1, offset_encoding)
  -- end

  -- request from each of the clients
  -- todo: refactor
  return vim.lsp.buf_request_all(0, 'textDocument/completion', params, function(result)
    local responses = {}
    for client_id, response in pairs(result) do
      -- todo: pass error upstream
      if response.error or response.result == nil then
        responses[client_id] = { is_incomplete_forward = true, is_incomplete_backward = true, items = {} }

      -- as per the spec, we assume it's complete if we get CompletionItem[]
      elseif response.result.items == nil then
        responses[client_id] = {
          is_incomplete_forward = false,
          is_incomplete_backward = true,
          items = response.result,
        }

      -- convert full response to our internal format
      else
        local defaults = response.result and response.result.itemDefaults or {}
        for _, item in ipairs(response.result.items) do
          -- add defaults to the item
          for key, value in pairs(defaults) do
            item[key] = value
          end
        end

        responses[client_id] = {
          is_incomplete_forward = response.result.isIncomplete,
          is_incomplete_backward = true,
          items = response.result.items,
        }
      end
    end

    -- add client_id and defaults to the items
    for client_id, response in pairs(responses) do
      for _, item in ipairs(response.items) do
        -- todo: terraform lsp doesn't return a .kind in situations like `toset`, is there a default value we need to grab?
        -- it doesn't seem to return itemDefaults either
        item.kind = item.kind or require('blink.cmp.types').CompletionItemKind.Text
        item.client_id = client_id

        -- todo: make configurable
        if item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) then item.score_offset = -2 end
      end
    end

    -- combine responses
    -- todo: ideally pass multiple responses to the sources
    -- so that we can do fine-grained isIncomplete
    -- or do caching here
    local combined_response = { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    for _, response in pairs(responses) do
      combined_response.is_incomplete_forward = combined_response.is_incomplete_forward
        or response.is_incomplete_forward
      combined_response.is_incomplete_backward = combined_response.is_incomplete_backward
        or response.is_incomplete_backward
      vim.list_extend(combined_response.items, response.items)
    end

    callback(combined_response)
  end)
end

--- Resolve ---

function lsp:resolve(item, callback)
  local client = vim.lsp.get_client_by_id(item.client_id)
  if client == nil or not client.server_capabilities.completionProvider.resolveProvider then
    callback(item)
    return
  end

  -- strip blink specific fields to avoid decoding errors on some LSPs (i.e. fsautocomplete)
  item = require('blink.cmp.sources.lib.utils').blink_item_to_lsp_item(item)

  local _, request_id = client.request('completionItem/resolve', item, function(error, resolved_item)
    if error or resolved_item == nil then callback(item) end
    callback(resolved_item)
  end)
  if request_id ~= nil then return function() client.cancel_request(request_id) end end
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
  local params = vim.lsp.util.make_position_params()
  params.context = {
    triggerKind = context.trigger.kind,
    triggerCharacter = context.trigger.character,
    isRetrigger = context.is_retrigger,
    activeSignatureHelp = context.active_signature_help,
  }

  -- otherwise, we call all clients
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
