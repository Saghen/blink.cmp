local snippets = {}

function snippets.completions(_, callback)
  local response = { isIncomplete = false, items = {} }
  local snips = Snippets.load_snippets_for_ft(vim.bo.filetype)

  if snips == nil then return callback(response) end

  for key in pairs(snips) do
    local snippet = snips[key]
    local body
    if type(snippet.body) == 'table' then
      body = table.concat(snippet.body, '\n')
    else
      body = snippet.body
    end

    local prefix = snips[key].prefix
    if type(prefix) == 'table' then
      for _, p in ipairs(prefix) do
        table.insert(response.items, {
          label = p,
          kind = vim.lsp.protocol.CompletionItemKind.Snippet,
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
          insertText = body,
          data = {
            prefix = p,
            body = body,
          },
          score_offset = -2,
        })
      end
    else
      table.insert(response.items, {
        label = prefix,
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
        insertText = body,
        data = {
          prefix = prefix,
          body = body,
        },
        score_offset = -2,
      })
    end
  end

  callback(response)
end

return snippets
