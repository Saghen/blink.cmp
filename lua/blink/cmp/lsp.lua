local lsp = {}

---@param capability string|table|nil Server capability (possibly nested
---   supplied via table) to check.
---
---@return boolean Whether at least one LSP client supports `capability`.
---@private
lsp.has_capability = function(capability)
  local clients = vim.lsp.buf_get_clients()
  if vim.tbl_isempty(clients) then return false end
  if not capability then return true end

  for _, c in pairs(clients) do
    local has_capability = lsp.table_get(c.server_capabilities, capability)
    if has_capability then return true end
  end
  return false
end

lsp.completions = function(callback)
  lsp.cancel_completions()

  -- no providers with completion support
  if not lsp.has_capability('completionProvider') then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params()
  lsp.completions_cancel_fun = vim.lsp.buf_request_all(bufnr, 'textDocument/completion', params, function(result)
    -- process items
    local items = {}
    for client_id, item in pairs(result) do
      if not item.err and item.result then vim.list_extend(items, lsp.get_words(item.result, client_id) or {}) end
    end

    -- todo: TEMPORARY
    -- should instead be smart where if the user had typed then dont update,
    -- but if the prompt is empty then update
    if #items == 0 then return end

    callback(items)
  end)
end

lsp.cancel_completions = function()
  if lsp.completions_cancel_fun then
    -- fails if the LSP no longer exists so we wrap it
    pcall(lsp.completions_cancel_fun)
  end
end

-- @return function Cancel function
lsp.resolve = function(item, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.lsp.buf_request_all(bufnr, 'completionItem/resolve', item.item, function(result)
    for client_id, resolved_item in pairs(result) do
      if not resolved_item.err and resolved_item.result then callback(client_id, resolved_item.result) end
    end
  end)
end

-- Utils --

lsp.get_words = function(response, client_id)
  -- Response can be `CompletionList` with 'items' field or `CompletionItem[]`
  local items = lsp.table_get(response, { 'items' }) or response
  if type(items) ~= 'table' then return {} end
  return lsp.parse_item(items, client_id)
end

lsp.parse_item = function(items, client_id)
  if vim.tbl_count(items) == 0 then return {} end

  local res = {}
  local docs, info
  for _, item in pairs(items) do
    -- Documentation info
    docs = item.documentation
    info = docs ~= nil and docs['value']
    if not info and type(docs) == 'string' then info = docs end

    -- Manually written version of the following line for performance
    -- Speeds up this function by ~4x
    -- local word = M.table_get(item, { 'textEdit', 'newText' }) or item.insertText or item.label or ''
    local word
    local tmp = item['textEdit']
    if tmp ~= nil then word = tmp['newText'] end
    if word == nil then
      word = item.insertText
      if word == nil then
        word = item.label
        if word == nil then word = '' end
      end
    end

    table.insert(res, {
      word = word,
      abbr = item.label,
      kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown',
      menu = item.detail or '',
      info = info,
      item = item,
      client_id = client_id,
    })
  end
  return res
end

lsp.table_get = function(t, id)
  if type(id) ~= 'table' then return lsp.table_get(t, { id }) end
  local res = t
  for _, i in ipairs(id) do
    if type(res) == 'table' and res[i] ~= nil then
      res = res[i]
    else
      return nil
    end
  end
  return res
end

return lsp
