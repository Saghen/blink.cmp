local keyword = {}

local BACKWARD_REGEX = vim.regex([[\k*$]])
local FORWARD_REGEX = vim.regex([[^\k+]])

--- @generic T
--- @generic Y
--- @param cb fun(): T, Y
--- @return T, Y
function keyword.with_constant_is_keyword(cb)
  local existing_is_keyword = vim.opt.iskeyword
  local desired_is_keyword = '@,48-57,_,-,192-255'
  if existing_is_keyword == desired_is_keyword then return cb() end

  vim.opt.iskeyword = '@,48-57,_,-,192-255'
  local success, a, b = pcall(cb)
  vim.opt.iskeyword = existing_is_keyword

  if success then return a, b end
  error(a)
end

--- @param line string
--- @param col number
--- @param match_suffix boolean
--- @return number, number
function keyword.get_keyword_range(line, col, match_suffix)
  return keyword.with_constant_is_keyword(function()
    local before_match_start = BACKWARD_REGEX:match_str(line:sub(1, col))
    if not match_suffix then return before_match_start or col, col end

    local after_match_end = FORWARD_REGEX:match_str(line:sub(col + 1))
    if after_match_end then after_match_end = after_match_end + col end
    return before_match_start or col, after_match_end or col
  end)
end

function keyword.guess_keyword_range_from_item(item_text, line, cursor_col, match_suffix)
  local line_range_start, line_range_end = keyword.get_keyword_range(line, cursor_col, match_suffix)
  local text_range_start, _ = keyword.get_keyword_range(item_text, #item_text, false)

  local line_prefix = line:sub(1, line_range_start)
  local text_prefix = item_text:sub(1, text_range_start)
  if line_prefix:sub(-#text_prefix) == text_prefix then return line_range_start - #text_prefix, line_range_end end

  return line_range_start, line_range_end
end

function keyword.guess_keyword_from_item(item_text, line, cursor_col, match_suffix)
  local start, finish = keyword.guess_keyword_range_from_item(item_text, line, cursor_col, match_suffix)
  return line:sub(start + 1, finish)
end

return keyword
