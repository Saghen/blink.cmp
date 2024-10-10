local text_edits_lib = require('blink.cmp.accept.text-edits')
local brackets_lib = require('blink.cmp.accept.brackets')
local config = require('blink.cmp.config')

--- Applies a completion item to the current buffer
--- @param item blink.cmp.CompletionItem
local function accept(item)
  local has_original_text_edit = item.textEdit ~= nil
  item = vim.deepcopy(item)
  item.textEdit = text_edits_lib.get_from_item(item)

  -- As `text_edits.guess_text_edit`'s way of detecting the start position of the edit is a bit
  -- naive for now, if selection mode is `auto_insert` and the LSP didn't provide a textEdit, then
  -- we need to manually set the correct position here.
  if config.windows.autocomplete.selection == 'auto_insert' and not has_original_text_edit then
    local word = item.insertText or item.label
    if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then word = item.label end
    local current_col = vim.api.nvim_win_get_cursor(0)[2]
    item.textEdit.range.start.character = current_col - #word
  end

  -- Add brackets to the text edit if needed
  local brackets_status, text_edit_with_brackets, offset = brackets_lib.add_brackets(vim.bo.filetype, item)
  item.textEdit = text_edit_with_brackets

  -- Snippet
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    -- We want to handle offset_encoding and the text edit api can do this for us
    -- so we empty the newText and apply
    local temp_text_edit = vim.deepcopy(item.textEdit)
    temp_text_edit.newText = ''
    text_edits_lib.apply_text_edits(item.client_id, { temp_text_edit })

    -- Expand the snippet
    vim.snippet.expand(item.textEdit.newText)

  -- OR Normal: Apply the text edit and move the cursor
  else
    text_edits_lib.apply_text_edits(item.client_id, { item.textEdit })
    vim.api.nvim_win_set_cursor(0, {
      item.textEdit.range.start.line + 1,
      item.textEdit.range.start.character + #item.textEdit.newText + offset,
    })
  end

  -- Check semantic tokens for brackets, if needed, and apply additional text edits
  if brackets_status == 'check_semantic_token' then
    -- todo: since we apply the additional text edits after, auto imported functions will not
    -- get auto brackets. If we apply them before, we have to modify the textEdit to compensate
    brackets_lib.add_brackets_via_semantic_token(vim.bo.filetype, item, function()
      require('blink.cmp.trigger.signature').show_if_on_trigger_character()
      text_edits_lib.apply_additional_text_edits(item)
    end)
  else
    require('blink.cmp.trigger.signature').show_if_on_trigger_character()
    text_edits_lib.apply_additional_text_edits(item)
  end

  -- Notify the rust module that the item was accessed
  require('blink.cmp.fuzzy').access(item)
end

return accept
