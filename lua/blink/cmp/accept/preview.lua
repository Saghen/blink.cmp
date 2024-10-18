--- @param item blink.cmp.CompletionItem
local function preview(item)
  local text_edits_lib = require('blink.cmp.accept.text-edits')
  local text_edit = text_edits_lib.get_from_item(item)

  -- for snippets, expand them with the default property names
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(text_edit.newText)
    text_edit.newText = expanded_snippet and tostring(expanded_snippet) or text_edit.newText
  end

  text_edits_lib.apply_text_edits(item.client_id, { text_edit })
  vim.api.nvim_win_set_cursor(0, {
    text_edit.range.start.line + 1,
    text_edit.range.start.character + #text_edit.newText,
  })

  return text_edit
end

return preview
