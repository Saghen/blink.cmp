--- @param item blink.cmp.CompletionItem
local function preview(item, previous_text_edit)
  local text_edits_lib = require('blink.cmp.accept.text-edits')
  local text_edit = text_edits_lib.get_from_item(item)

  -- with auto_insert, we may have to undo the previous preview
  if previous_text_edit ~= nil then text_edit.range = text_edits_lib.get_undo_text_edit_range(previous_text_edit) end

  -- for snippets, expand them with the default property names
  local cursor_pos = {
    text_edit.range.start.line + 1,
    text_edit.range.start.character + #text_edit.newText,
  }
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(text_edit.newText)
    text_edit.newText = expanded_snippet and tostring(expanded_snippet) or text_edit.newText

    -- place the cursor at the first tab stop
    local tabstops = require('blink.cmp.sources.snippets.utils').get_tab_stops(text_edit.newText)
    if tabstops and #tabstops > 0 then
      cursor_pos[1] = text_edit.range.start.line + tabstops[1].line
      cursor_pos[2] = text_edit.range.start.character + tabstops[1].character
    end
  end

  text_edits_lib.apply_text_edits(item.client_id, { text_edit })
  vim.api.nvim_win_set_cursor(0, cursor_pos)

  -- return so that it can be undone in the future
  return text_edit
end

return preview
