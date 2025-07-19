local clangd = {}
local completion_item_kind = require('blink.cmp.types').CompletionItemKind

--- @param text string
--- @return string
local function strip_ending_punctuation(text)
  local last_char = text:sub(-1)
  if last_char == '>' or last_char == '"' then text = text:sub(1, -2) end
  return text
end

--- @param response blink.cmp.CompletionResponse | nil
--- @return blink.cmp.CompletionResponse | nil
function clangd.process_response(response)
  if not response then return response end

  local items = response.items
  if not items then return response end

  for _, item in ipairs(items) do
    if item.kind == completion_item_kind.File then
      item.textEdit.newText = strip_ending_punctuation(item.textEdit.newText)
      item.label = strip_ending_punctuation(item.label)
    end
    item.lsp_score = item.score
  end
  return response
end

return clangd
