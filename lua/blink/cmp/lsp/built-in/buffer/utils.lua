local utils = {}

--- @param bufnr integer
--- @return integer
function utils.get_buffer_size(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local size = 0
  for _, line in ipairs(lines) do
    size = size + #line + 1
  end
  return size
end

--- @param words string[]
--- @return lsp.CompletionItem[]
function utils.words_to_items(words)
  local text_kind = require('blink.cmp.types').CompletionItemKind.Text
  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText

  local items = {}
  for i = 1, #words do
    items[i] = {
      label = words[i],
      kind = text_kind,
      insertTextFormat = plain_text,
      insertText = words[i],
    }
  end
  return items
end

return utils
