--- @param item blink.cmp.CompletionItem
local function preview(item)
  local text_edits_lib = require('blink.cmp.lib.text_edits')
  local text_edit = text_edits_lib.get_from_item(item)

  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(text_edit.newText)
    local snippet = expanded_snippet and tostring(expanded_snippet) or text_edit.newText
    local get_prefix_before_brackets_and_quotes = require('blink.cmp.completion.accept.prefix')
    text_edit.newText = get_prefix_before_brackets_and_quotes(snippet)
  end

  local undo_text_edit = text_edits_lib.get_undo_text_edit(text_edit)
  local cursor_pos = {
    text_edit.range.start.line + 1,
    text_edit.range.start.character + #text_edit.newText,
  }

  text_edits_lib.apply({ text_edit })

  vim.api.nvim_win_set_cursor(0, cursor_pos)
  return undo_text_edit
end

return preview
