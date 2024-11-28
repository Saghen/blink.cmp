local config = require('blink.cmp.config')
local text_edits = {}

--- Applies one or more text edits to the current buffer, assuming utf-8 encoding
--- @param edits lsp.TextEdit[]
function text_edits.apply(edits) vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), 'utf-8') end

------- Undo -------

--- Gets the reverse of the text edit, must be called before applying
--- @param text_edit lsp.TextEdit
--- @return lsp.TextEdit
function text_edits.get_undo_text_edit(text_edit)
  return {
    range = text_edits.get_undo_range(text_edit),
    newText = text_edits.get_text_to_replace(text_edit),
  }
end

--- Gets the range for undoing an applied text edit
--- @param text_edit lsp.TextEdit
function text_edits.get_undo_range(text_edit)
  text_edit = vim.deepcopy(text_edit)
  local lines = vim.split(text_edit.newText, '\n')
  local last_line_len = lines[#lines] and #lines[#lines] or 0

  local range = text_edit.range
  range['end'].line = range.start.line + #lines - 1
  range['end'].character = #lines > 1 and last_line_len or range.start.character + last_line_len

  return range
end

--- Gets the text the text edit will replace
--- @param text_edit lsp.TextEdit
--- @return string
function text_edits.get_text_to_replace(text_edit)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = {}
  for line = text_edit.range.start.line, text_edit.range['end'].line do
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
    local is_start_line = line == text_edit.range.start.line
    local is_end_line = line == text_edit.range['end'].line

    if is_start_line and is_end_line then
      table.insert(lines, line_text:sub(text_edit.range.start.character + 1, text_edit.range['end'].character))
    elseif is_start_line then
      table.insert(lines, line_text:sub(text_edit.range.start.character + 1))
    elseif is_end_line then
      table.insert(lines, line_text:sub(1, text_edit.range['end'].character))
    else
      table.insert(lines, line_text)
    end
  end
  return table.concat(lines, '\n')
end

------- Get -------

--- Grabbed from vim.lsp.utils. Converts an offset_encoding to byte offset
--- @param position lsp.Position
--- @param offset_encoding? 'utf-8'|'utf-16'|'utf-32'
--- @return number
local function get_line_byte_from_position(position, offset_encoding)
  local bufnr = vim.api.nvim_get_current_buf()
  local col = position.character

  -- When on the first character, we can ignore the difference between byte and character
  if col == 0 then return 0 end

  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1] or ''
  if vim.fn.has('nvim-0.11.0') == 1 then
    col = vim.str_byteindex(line, offset_encoding or 'utf-16', col, false) or 0
  else
    col = vim.lsp.util._str_byteindex_enc(line, col, offset_encoding or 'utf-16')
  end
  return math.min(col, #line)
end

--- Gets the text edit from an item, handling insert/replace ranges and converts
--- offset encodings (utf-16 | utf-32) to utf-8
--- @param item blink.cmp.CompletionItem
--- @return lsp.TextEdit
function text_edits.get_from_item(item)
  local text_edit = vim.deepcopy(item.textEdit)

  -- Fallback to default edit range if defined, and no text edit was set
  if text_edit == nil and item.editRange ~= nil then
    text_edit = {
      newText = item.textEditText or item.insertText or item.label,
      -- FIXME: temporarily convert insertReplaceEdit to regular textEdit
      range = vim.deepcopy(item.editRange.insert or item.editRange.replace or item.editRange),
    }
  end

  -- Guess the text edit if the item doesn't define it
  if text_edit == nil then return text_edits.guess(item) end

  -- FIXME: temporarily convert insertReplaceEdit to regular textEdit
  text_edit.range = text_edit.range or text_edit.insert or text_edit.replace
  text_edit.insert = nil
  text_edit.replace = nil
  --- @cast text_edit lsp.TextEdit

  -- Adjust the position of the text edit to be the current cursor position
  -- since the data might be outdated. We compare the cursor column position
  -- from when the items were fetched versus the current.
  -- HACK: is there a better way?
  -- TODO: take into account the offset_encoding
  local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
  text_edit.range['end'].character = text_edit.range['end'].character + offset

  -- convert the offset encoding to utf-8
  -- TODO: we have to do this last because it applies a max on the position based on the length of the line
  -- so it would break the offset code when removing characters at the end of the line
  local offset_encoding = text_edits.offset_encoding_from_item(item)
  text_edit = text_edits.to_utf_8(text_edit, offset_encoding)

  return text_edit
end

function text_edits.offset_encoding_from_item(item)
  local client = vim.lsp.get_client_by_id(item.client_id)
  return client ~= nil and client.offset_encoding or 'utf-8'
end

function text_edits.to_utf_8(text_edit, offset_encoding)
  if offset_encoding == 'utf-8' then return text_edit end
  text_edit = vim.deepcopy(text_edit)
  text_edit.range.start.character = get_line_byte_from_position(text_edit.range.start, offset_encoding)
  text_edit.range['end'].character = get_line_byte_from_position(text_edit.range['end'], offset_encoding)
  return text_edit
end

--- Uses the keyword_regex to guess the text edit ranges
--- @param item blink.cmp.CompletionItem
--- TODO: doesnt work when the item contains characters not included in the context regex
function text_edits.guess(item)
  local word = item.insertText or item.label

  local keyword = config.completion.keyword
  local range = require('blink.cmp.lib.utils').get_regex_around_cursor(
    keyword.range,
    keyword.regex,
    keyword.exclude_from_prefix_regex
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
