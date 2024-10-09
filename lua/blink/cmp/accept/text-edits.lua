local utils = require('blink.cmp.utils')
local text_edits = {}

function text_edits.get_from_item(item)
  -- Adjust the position of the text edit to be the current cursor position
  -- since the data might be outdated. We compare the cursor column position
  -- from when the items were fetched versus the current.
  -- hack: is there a better way?
  if item.textEdit ~= nil then
    local text_edit = utils.shallow_copy(item.textEdit)
    local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset
    return text_edit
  end

  -- No text edit so we fallback to our own resolution
  return text_edits.guess_text_edit(vim.api.nvim_get_current_buf(), item)
end

function text_edits.apply_text_edits(client_id, edits)
  local client = vim.lsp.get_client_by_id(client_id)
  local offset_encoding = client ~= nil and client.offset_encoding or 'utf-16'
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), offset_encoding)
end

function text_edits.apply_additional_text_edits(item)
  -- Apply additional text edits
  -- LSPs can either include these in the initial response or require a resolve
  -- These are used for things like auto-imports
  -- todo: if the main text edit was before this text edit, do we need to compensate?
  if item.additionalTextEdits ~= nil then
    text_edits.apply_text_edits(item.client_id, item.additionalTextEdits)
  else
    require('blink.cmp.sources.lib').resolve(item, function(resolved_item)
      resolved_item = resolved_item or item
      text_edits.apply_text_edits(resolved_item.client_id, resolved_item.additionalTextEdits or {})
    end)
  end
end

-- todo: doesnt work when the item contains characters not included in the context regex
function text_edits.guess_text_edit(bufnr, item)
  local word = item.insertText or item.label

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]

  -- Search forward/backward for the start/end of the word
  local start_col = current_col
  while start_col > 0 do
    local char = line:sub(start_col, start_col)
    if char:match('[%w_\\-]') == nil then break end
    start_col = start_col - 1
  end

  -- convert to 0-index
  return {
    range = {
      start = { line = current_line - 1, character = start_col },
      ['end'] = { line = current_line - 1, character = current_col },
    },
    newText = word,
  }
end

return text_edits
