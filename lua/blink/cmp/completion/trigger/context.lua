-- TODO: remove the end_col field from ContextBounds

--- @class blink.cmp.ContextBounds
--- @field line string
--- @field line_number number
--- @field start_col number
--- @field end_col number
--- @field length number

--- @class blink.cmp.Context
--- @field mode blink.cmp.Mode
--- @field id number
--- @field bufnr number
--- @field cursor number[]
--- @field line string
--- @field bounds blink.cmp.ContextBounds
--- @field trigger { kind: number, character: string | nil }
--- @field providers string[]
---
--- @field new fun(opts: blink.cmp.ContextOpts): blink.cmp.Context
--- @field get_keyword fun(): string
--- @field within_query_bounds fun(self: blink.cmp.Context, cursor: number[]): boolean
---
--- @field get_mode fun(): blink.cmp.Mode
--- @field get_cursor fun(): number[]
--- @field set_cursor fun(cursor: number[])
--- @field get_line fun(num?: number): string
--- @field get_bounds fun(line: string, cursor: number[]): blink.cmp.ContextBounds
--- @field get_regex_around_cursor fun(range: string, regex_str: string, exclude_from_prefix_regex_str: string): { start_col: number, length: number }

--- @class blink.cmp.ContextOpts
--- @field id number
--- @field providers string[]
--- @field trigger_character? string

local keyword_regex = vim.regex(require('blink.cmp.config').completion.keyword.regex)

--- @type blink.cmp.Context
--- @diagnostic disable-next-line: missing-fields
local context = {}

function context.new(opts)
  local cursor = context.get_cursor()
  local line = context.get_line()

  return setmetatable({
    mode = context.get_mode(),
    id = opts.id,
    bufnr = vim.api.nvim_get_current_buf(),
    cursor = cursor,
    line = line,
    bounds = context.get_bounds(line, cursor),
    trigger = {
      kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
      character = opts.trigger_character,
    },
    providers = opts.providers,
  }, { __index = context })
end

function context.get_keyword()
  local keyword = require('blink.cmp.config').completion.keyword
  local range = context.get_regex_around_cursor(keyword.range, keyword.regex, keyword.exclude_from_prefix_regex)
  return string.sub(context.get_line(), range.start_col, range.start_col + range.length - 1)
end

--- @param cursor number[]
--- @return boolean
function context:within_query_bounds(cursor)
  local row, col = cursor[1], cursor[2]
  local bounds = self.bounds
  return row == bounds.line_number and col >= bounds.start_col and col <= bounds.end_col
end

function context.get_mode() return vim.api.nvim_get_mode().mode == 'c' and 'cmdline' or 'default' end

function context.get_cursor()
  return context.get_mode() == 'cmdline' and { 1, vim.fn.getcmdpos() - 1 } or vim.api.nvim_win_get_cursor(0)
end

function context.set_cursor(cursor)
  local mode = context.get_mode()
  if mode == 'default' then return vim.api.nvim_win_set_cursor(0, cursor) end

  assert(mode == 'cmdline', 'Unsupported mode for setting cursor: ' .. mode)
  assert(cursor[1] == 1, 'Cursor must be on the first line in cmdline mode')
  vim.fn.setcmdpos(cursor[2])
end

function context.get_line(num)
  if context.get_mode() == 'cmdline' then
    assert(
      num == nil or num == 0,
      'Cannot get line number ' .. tostring(num) .. ' in cmdline mode. Only 0 is supported'
    )
    return vim.fn.getcmdline()
  end

  if num == nil then num = context.get_cursor()[1] - 1 end
  return vim.api.nvim_buf_get_lines(0, num, num + 1, false)[1]
end

--- Moves forward and backwards around the cursor looking for word boundaries
function context.get_bounds(line, cursor)
  local cursor_line = cursor[1]
  local cursor_col = cursor[2]

  local start_col = cursor_col
  while start_col >= 1 do
    local char = line:sub(start_col, start_col)
    if keyword_regex:match_str(char) == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end
  start_col = math.max(start_col, 1)

  local end_col = cursor_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if keyword_regex:match_str(char) == nil then break end
    end_col = end_col + 1
  end

  -- hack: why do we have to math.min here?
  start_col = math.min(start_col, end_col)

  local length = end_col - start_col + 1
  -- Since sub(1, 1) returns a single char string, we need to check if that single char matches
  -- and otherwise mark the length as 0
  if start_col == end_col and keyword_regex:match_str(line:sub(start_col, end_col)) == nil then length = 0 end

  return { line_number = cursor_line, start_col = start_col, end_col = end_col, length = length }
end

--- Gets characters around the cursor and returns the range, 0-indexed
function context.get_regex_around_cursor(range, regex_str, exclude_from_prefix_regex_str)
  local line = context.get_line()
  local current_col = context.get_cursor()[2] + 1

  local backward_regex = vim.regex('\\(' .. regex_str .. '\\)\\+$')
  local forward_regex = vim.regex('^\\(' .. regex_str .. '\\)\\+')

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

return context
