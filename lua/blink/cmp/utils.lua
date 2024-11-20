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

--- @param ctx blink.cmp.DrawItemContext
--- @return string|nil
function utils.get_tailwind_hl(ctx)
  local doc = ctx.item.documentation
  if ctx.kind == 'Color' and doc then
    local content = type(doc) == 'string' and doc or doc.value
    if content and content:match('^#%x%x%x%x%x%x$') then
      local hl_name = 'HexColor' .. content:sub(2)
      if #vim.api.nvim_get_hl(0, { name = hl_name }) == 0 then vim.api.nvim_set_hl(0, hl_name, { fg = content }) end
      return hl_name
    end
  end
end

local PAIRS_AND_INVALID_CHARS = {}
string.gsub('\'"=$()[]<>{} \t\n\r', '.', function(char) PAIRS_AND_INVALID_CHARS[string.byte(char)] = true end)

local CLOSING_PAIR = {
  [string.byte('<')] = string.byte('>'),
  [string.byte('[')] = string.byte(']'),
  [string.byte('(')] = string.byte(')'),
  [string.byte('{')] = string.byte('}'),
  [string.byte('"')] = string.byte('"'),
  [string.byte("'")] = string.byte("'"),
}

local ALPHANUMERIC = {}
string.gsub(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
  '.',
  function(char) ALPHANUMERIC[string.byte(char)] = true end
)

--- Gets the prefix of the given text, stopping at brackets and quotes
--- @param text string
--- @return string
function utils.get_prefix_before_brackets_and_quotes(text)
  local closing_pairs_stack = {}
  local word = ''

  local add = function(char)
    word = word .. string.char(char)

    -- if we've seen the opening pair, and we've just received the closing pair,
    -- remove it from the closing pairs stack
    if closing_pairs_stack[#closing_pairs_stack] == char then
      table.remove(closing_pairs_stack, #closing_pairs_stack)
    -- if the character is an opening pair, add it to the closing pairs stack
    elseif CLOSING_PAIR[char] ~= nil then
      table.insert(closing_pairs_stack, CLOSING_PAIR[char])
    end
  end

  local has_alphanumeric = false
  for i = 1, #text do
    local char = string.byte(text, i)
    if PAIRS_AND_INVALID_CHARS[char] == nil then
      add(char)
      has_alphanumeric = has_alphanumeric or ALPHANUMERIC[char]
    elseif not has_alphanumeric or #closing_pairs_stack ~= 0 then
      add(char)
      -- if we had an alphanumeric, and the closing pairs stuck *just* emptied,
      -- because the current character is a closing pair, we exit
      if has_alphanumeric and #closing_pairs_stack == 0 then break end
    else
      break
    end
  end
  return word
end

return utils
