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
--- @param regex string
--- @param exclude_from_prefix_regex string
--- @return { start_col: number, length: number }
--- TODO: switch to return start_col, length to simplify downstream logic
function utils.get_regex_around_cursor(range, regex, exclude_from_prefix_regex)
  local current_col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local line = vim.api.nvim_get_current_line()

  -- Search backward for the start of the word
  local start_col = current_col
  local length = 0
  while start_col > 0 do
    local char = line:sub(start_col - 1, start_col - 1)
    if char:match(regex) == nil then break end
    start_col = start_col - 1
    length = length + 1
  end

  -- Search forward for the end of the word if configured
  if range == 'full' then
    while start_col + length < #line do
      local col = start_col + length
      local char = line:sub(col, col)
      if char:match(regex) == nil then break end
      length = length + 1
    end
  end

  -- exclude characters matching exclude_prefix_regex from the beginning of the bounds
  if exclude_from_prefix_regex ~= nil then
    while length > 0 do
      local char = line:sub(start_col, start_col)
      if char:match(exclude_from_prefix_regex) == nil then break end
      start_col = start_col + 1
      length = length - 1
    end
  end

  return { start_col = start_col, length = length }
end

return utils
