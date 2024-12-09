local utils = {}

--- Shallow copy table
--- @generic T
--- @param t T
--- @return T
function utils.shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--- Returns the union of the keys of two tables
--- @generic T
--- @param t1 T[]
--- @param t2 T[]
--- @return T[]
function utils.union_keys(t1, t2)
  local t3 = {}
  for k, _ in pairs(t1) do
    t3[k] = true
  end
  for k, _ in pairs(t2) do
    t3[k] = true
  end
  return vim.tbl_keys(t3)
end

--- Returns a list of unique values from the input array
--- @generic T
--- @param arr T[]
--- @return T[]
function utils.deduplicate(arr)
  local hash = {}
  for _, v in ipairs(arr) do
    hash[v] = true
  end
  return vim.tbl_keys(hash)
end

--- Gets characters around the cursor and returns the range, 0-indexed
--- @param range 'prefix' | 'full'
--- @param regex_str string
--- @param exclude_from_prefix_regex_str string
--- @return { start_col: number, length: number }
--- TODO: switch to return start_col, length to simplify downstream logic
function utils.get_regex_around_cursor(range, regex_str, exclude_from_prefix_regex_str)
  local backward_regex = vim.regex('\\(' .. regex_str .. '\\)\\+$')
  local forward_regex = vim.regex('^\\(' .. regex_str .. '\\)\\+')

  local current_col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local line = vim.api.nvim_get_current_line()

  local length = 0
  local start_col = current_col

  -- Search backward for the start of the word
  local line_before = line:sub(1, current_col - 1)
  local before_match_start, _ = backward_regex:match_str(line_before)
  if before_match_start ~= nil then
    start_col = before_match_start + 1
    length = current_col - start_col
  end

  -- Search forward for the end of the word if configured
  if range == 'full' then
    local line_after = line:sub(current_col)
    local _, after_match_end = forward_regex:match_str(line_after)
    if after_match_end ~= nil then length = length + after_match_end end
  end

  -- exclude characters matching exclude_prefix_regex from the beginning of the bounds
  if exclude_from_prefix_regex_str ~= nil then
    local exclude_from_prefix_regex = vim.regex(exclude_from_prefix_regex_str)
    while length > 0 do
      local char = line:sub(start_col, start_col)
      if exclude_from_prefix_regex:match_str(char) == nil then break end
      start_col = start_col + 1
      length = length - 1
    end
  end

  return { start_col = start_col, length = length }
end

function utils.schedule_if_needed(fn)
  if vim.in_fast_event() then
    vim.schedule(fn)
  else
    fn()
  end
end

return utils
