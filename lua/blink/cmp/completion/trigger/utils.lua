local context = require('blink.cmp.completion.trigger.context')
local utils = {}

--- Gets the full Unicode character at cursor position
--- @return string
function utils.get_char_at_cursor()
  local line = context.get_line()
  if line == '' then return '' end
  local cursor_col = context.get_cursor()[2]

  -- Find the start of the UTF-8 character
  local start_col = cursor_col
  while start_col > 1 do
    local char = string.byte(line:sub(start_col, start_col))
    if char < 0x80 or char > 0xBF then break end
    start_col = start_col - 1
  end

  -- Find the end of the UTF-8 character
  local end_col = cursor_col
  while end_col < #line do
    local char = string.byte(line:sub(end_col + 1, end_col + 1))
    if char < 0x80 or char > 0xBF then break end
    end_col = end_col + 1
  end

  return line:sub(start_col, end_col)
end

return utils
