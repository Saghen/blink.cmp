local text_edits_lib = require('blink.cmp.accept.text-edits')
local brackets_lib = require('blink.cmp.accept.brackets')

--- Applies a completion item to the current buffer
--- @param item blink.cmp.CompletionItem
local function accept(item)
  item = vim.deepcopy(item)

  local text_edit = item.textEdit
  if text_edit ~= nil then
    -- Adjust the position of the text edit to be the current cursor position
    -- since the data might be outdated. We compare the cursor column position
    -- from when the items were fetched versus the current.
    -- hack: figure out a better way
    local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset
  else
    -- No text edit so we fallback to our own resolution
    text_edit = text_edits_lib.guess_text_edit(vim.api.nvim_get_current_buf(), item)
  end
  item.textEdit = text_edit

  -- Add brackets to the text edit if needed
  local brackets_status, text_edit_with_brackets, offset = brackets_lib.add_brackets(vim.bo.filetype, item)
  text_edit = text_edit_with_brackets

  -- Snippet
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    -- We want to handle offset_encoding and the text edit api can do this for us
    -- so we empty the newText and apply
    local temp_text_edit = vim.deepcopy(text_edit)
    temp_text_edit.newText = ''
    text_edits_lib.apply_text_edits(item.client_id, { temp_text_edit })

    -- Expand the snippet
    vim.snippet.expand(text_edit.newText)

  -- OR Normal: Apply the text edit and move the cursor
  else
    text_edits_lib.apply_text_edits(item.client_id, { text_edit })
    vim.api.nvim_win_set_cursor(0, {
      text_edit.range.start.line + 1,
      text_edit.range.start.character + #text_edit.newText + offset,
    })
  end

  -- Check semantic tokens for brackets, if needed, and apply additional text edits
  if brackets_status == 'check_semantic_token' then
    brackets_lib.add_brackets_via_semantic_token(
      vim.bo.filetype,
      item,
      function() text_edits_lib.apply_additional_text_edits(item) end
    )
  else
    text_edits_lib.apply_additional_text_edits(item)
  end

  -- Notify the rust module that the item was accessed
  require('blink.cmp.fuzzy').access(item)
end

return accept
