--- @class blink.cmp.Source
local snippets = {}

function snippets.completions(_, callback)
  local response = { isIncomplete = false, items = {} }
  local snips = require('snippets').load_snippets_for_ft(vim.bo.filetype)

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
end

function snippets.filter_completions(context, sources_responses)
  if sources_responses.snippets == nil then return sources_responses end
  if context.trigger_character == nil then return sources_responses end

  -- copy to avoid mutating the original
  local copied_sources_responses = {}
  for name, response in pairs(sources_responses) do
    copied_sources_responses[name] = response
  end
  sources_responses = copied_sources_responses

  -- don't show if a trigger character triggered this
  -- todo: the idea here is that situations like `text.|` shouldn't show
  -- the buffer completions since it's likely not helpful
  sources_responses.snippets.items = {}
  return sources_responses
end

function snippets.resolve(item, callback)
  -- highlight code block
  local preview = require('snippets.utils').preview(item.insertText)
  preview = string.format('```%s\n%s\n```', vim.bo.filetype, preview)
  item.documentation = {
    kind = 'markdown',
    value = preview,
  }

  -- todo: this wont be respected, but maybe not needed?
  -- item.insertText = require('snippets.utils').expand_vars(item.data.body)

  callback(item)
end

return snippets
