local config = require('blink.cmp.config')
local text_edits = {}

--- @param item blink.cmp.CompletionItem
--- @return lsp.TextEdit
function text_edits.get_from_item(item)
  -- Adjust the position of the text edit to be the current cursor position
  -- since the data might be outdated. We compare the cursor column position
  -- from when the items were fetched versus the current.
  -- hack: is there a better way?
  if item.textEdit ~= nil then
    -- FIXME: temporarily convert insertReplaceEdit to regular textEdit
    if item.textEdit.insert ~= nil then
      item.textEdit.range = item.textEdit.insert
    elseif item.textEdit.replace ~= nil then
      item.textEdit.range = item.textEdit.replace
    end

    local text_edit = vim.deepcopy(item.textEdit)
    local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset
    return text_edit
  end

  -- No text edit so we fallback to our own resolution
  return text_edits.guess_text_edit(item)
end

--- @param client_id number
--- @param edits lsp.TextEdit[]
function text_edits.apply_text_edits(client_id, edits)
  local client = vim.lsp.get_client_by_id(client_id)
  local offset_encoding = client ~= nil and client.offset_encoding or 'utf-16'
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), offset_encoding)
end

--- @param text_edit lsp.TextEdit
function text_edits.get_undo_text_edit_range(text_edit)
  text_edit = vim.deepcopy(text_edit)
  local lines = vim.split(text_edit.newText, '\n')
  local last_line_len = lines[#lines] and #lines[#lines] or 0

  local range = text_edit.range
  range['end'].line = range.start.line + #lines - 1
  range['end'].character = #lines > 1 and last_line_len or range.start.character + last_line_len

  return range
end

function text_edits.undo_text_edit(text_edit)
  text_edit = vim.deepcopy(text_edit)
  text_edit.range = text_edits.get_undo_text_edit_range(text_edit)
  text_edit.newText = ''

  vim.lsp.util.apply_text_edits({ text_edit }, vim.api.nvim_get_current_buf(), 'utf-16')
end

--- @param item blink.cmp.CompletionItem
function text_edits.apply_additional_text_edits(item)
  -- Apply additional text edits
  -- LSPs can either include these in the initial response or require a resolve
  -- These are used for things like auto-imports
  -- todo: if the main text edit was before this text edit, do we need to compensate?
  if item.additionalTextEdits ~= nil and next(item.additionalTextEdits) ~= nil then
    text_edits.apply_text_edits(item.client_id, item.additionalTextEdits)
  else
    require('blink.cmp.sources.lib').resolve(item, function(resolved_item)
      resolved_item = resolved_item or item
      text_edits.apply_text_edits(resolved_item.client_id, resolved_item.additionalTextEdits or {})
    end)
  end
end

--- @param item blink.cmp.CompletionItem
--- todo: doesnt work when the item contains characters not included in the context regex
function text_edits.guess_text_edit(item)
  local word = item.textEditText or item.insertText or item.label

  local cmp_config = config.trigger.completion
  local range = require('blink.cmp.utils').get_regex_around_cursor(
    cmp_config.keyword_range,
    cmp_config.keyword_regex,
    cmp_config.exclude_from_prefix_regex
  )
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- convert to 0-index
  return {
    range = {
      start = { line = current_line - 1, character = range.start_col - 1 },
      ['end'] = { line = current_line - 1, character = range.start_col - 1 + range.length },
    },
    newText = word,
  }
end

return text_edits
