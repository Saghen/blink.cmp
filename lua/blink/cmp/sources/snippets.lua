--- @class blink.cmp.Source
local snippets = {}

function snippets.new(config) return setmetatable(config, { __index = snippets }) end

function snippets:get_completions(_, callback)
  local response = { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
  local snips = require('snippets').load_snippets_for_ft(vim.bo.filetype)

  if snips == nil then
    callback(response)
    return function() end
  end

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
          score_offset = -3,
        })
      end
    else
      table.insert(response.items, {
        label = prefix,
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
        insertText = body,
        score_offset = -3,
      })
    end
  end

  callback(response)
  return function() end
end

function snippets:should_show_completions(context) return context.trigger.character == nil end

function snippets:resolve(item, callback)
  -- highlight code block
  local preview = require('snippets.utils').preview(item.insertText)
  preview = string.format('```%s\n%s\n```', vim.bo.filetype, preview)
  item.documentation = {
    kind = 'markdown',
    value = preview,
  }

  callback(item)
end

return snippets
