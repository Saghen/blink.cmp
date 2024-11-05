local config = require('blink.cmp.config')
local text_edits = {}

--- Position is a https://microsoft.github.io/language-server-protocol/specifications/specification-current/#position
--- @param position lsp.Position
--- @param offset_encoding string|nil utf-8|utf-16|utf-32
--- @return integer
local function get_line_byte_from_position(position, offset_encoding)
  local bufnr = vim.api.nvim_get_current_buf()
  -- LSP's line and characters are 0-indexed
  -- Vim's line and columns are 1-indexed
  local col = position.character
  -- When on the first character, we can ignore the difference between byte and
  -- character
  if col > 0 then
    local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, true)[1] or ''
    return vim.lsp.util._str_byteindex_enc(line, col, offset_encoding or 'utf-16')
  end
  return col
end

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

    local client = vim.lsp.get_client_by_id(client_id)
    local offset_encoding = client ~= nil and client.offset_encoding or 'utf-8'

    if offset_encoding ~= 'utf-8' then
      text_edit.range.start.character = get_line_byte_from_position(text_edit.range.start, offset_encoding)
      text_edit.range['end'].character = get_line_byte_from_position(text_edit.range['end'], offset_encoding)
    end

    local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset
    return text_edit
  end

  -- No text edit so we fallback to our own resolution
  return text_edits.guess_text_edit(item)
end

--- @param edits lsp.TextEdit[]
function text_edits.apply_text_edits(edits)
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), 'utf-8')
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

  text_edits.apply_text_edits({ text_edit })
end

--- @param item blink.cmp.CompletionItem
--- TODO: doesnt work when the item contains characters not included in the context regex
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
  local text_edit = {
    range = {
      start = { line = current_line - 1, character = range.start_col - 1 },
      ['end'] = { line = current_line - 1, character = range.start_col - 1 + range.length },
    },
    newText = word,
  }

  return text_edit
end

return text_edits
