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

--- Determines whether the current buffer is a "special" buffer or if the filetype is in the list of ignored filetypes
--- @return boolean
function utils.is_blocked_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  local blocked_filetypes = require('blink.cmp.config').blocked_filetypes or {}
  local buf_filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

  if vim.tbl_contains(blocked_filetypes, buf_filetype) then return true end
  return buftype ~= ''
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

--- Flattens an arbitrarily deep table into a  single level table
--- @param t table
--- @return table
function utils.flatten(t)
  if t[1] == nil then return t end

  local flattened = {}
  for _, v in ipairs(t) do
    if v[1] == nil then
      table.insert(flattened, v)
    else
      vim.list_extend(flattened, utils.flatten(v))
    end
  end
  return flattened
end

--- Returns the index of the first occurrence of the value in the array
--- @generic T
--- @param arr T[]
--- @param val T
--- @return number | nil
function utils.index_of(arr, val)
  for idx, v in ipairs(arr) do
    if v == val then return idx end
  end
  return nil
end

--- Slices an array
--- @generic T
--- @param arr T[]
--- @param start number
--- @param finish number
--- @return T[]
function utils.slice(arr, start, finish)
  start = start or 1
  finish = finish or #arr
  local sliced = {}
  for i = start, finish do
    sliced[#sliced + 1] = arr[i]
  end
  return sliced
end

function utils.fast_gsub(str, old_char, new_char)
  local result = ''
  for i = 1, #str do
    local c = str:sub(i, i)
    result = result .. (c == old_char and new_char or c)
  end
  return result
end

return utils
