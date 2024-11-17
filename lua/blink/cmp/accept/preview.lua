local _
local INVALID_CHARS = {}
_ = string.gsub('\'"=$()[]<>{} \t\n\r', '.', function(char)
  INVALID_CHARS[string.byte(char)] = true
end)

local PAIRS = {}
PAIRS[string.byte('<')] = string.byte('>')
PAIRS[string.byte('[')] = string.byte(']')
PAIRS[string.byte('(')] = string.byte(')')
PAIRS[string.byte('{')] = string.byte('}')
PAIRS[string.byte('"')] = string.byte('"')
PAIRS[string.byte("'")] = string.byte("'")

local ALPHANUMERIC = {}
_ = string.gsub('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', '.', function(char)
  ALPHANUMERIC[string.byte(char)] = true
end)

---get_word
---@param text string
---@return string
local get_word = function(text)
  local has_alnum = false
  local stack = {}
  local word = {}
  local add = function(c)
    table.insert(word, string.char(c))
    if stack[#stack] == c then
      table.remove(stack, #stack)
    else
      if PAIRS[c] then
        table.insert(stack, PAIRS[c])
      end
    end
  end
  for i = 1, #text do
    local c = string.byte(text, i)
    if not INVALID_CHARS[c] then
      add(c)
      has_alnum = has_alnum or ALPHANUMERIC[c]
    elseif not has_alnum or #stack ~= 0 then
      add(c)
      if has_alnum and #stack == 0 then
        break
      end
    else
      break
    end
  end
  return table.concat(word, '')
end

--- @param item blink.cmp.CompletionItem
local function preview(item, previous_text_edit)
  local text_edits_lib = require('blink.cmp.accept.text-edits')
  local text_edit = text_edits_lib.get_from_item(item)

  -- with auto_insert, we may have to undo the previous preview
  if previous_text_edit ~= nil then text_edit.range = text_edits_lib.get_undo_range(previous_text_edit) end

  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(text_edit.newText)
    text_edit.newText = get_word(expanded_snippet and tostring(expanded_snippet) or text_edit.newText)
  end

  local cursor_pos = {
    text_edit.range.start.line + 1,
    text_edit.range.start.character + #text_edit.newText,
  }

  text_edits_lib.apply({ text_edit })
  vim.api.nvim_win_set_cursor(0, cursor_pos)

  -- return so that it can be undone in the future
  return text_edit
end

return preview
