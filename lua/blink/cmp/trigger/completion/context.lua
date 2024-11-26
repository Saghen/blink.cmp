--- @type blink.cmp.Context
--- @diagnostic disable-next-line: missing-fields
local context = {}
local context_id = 0

function context.new(opts)
  if not opts.id then
    context_id = context_id + 1
    opts.id = context_id
  end

  local self = setmetatable({}, { __index = context })
  self.id = opts.id
  self.mode = opts.mode or 'editor'
  self.buf = vim.api.nvim_get_current_buf()
  self.cursor = opts.mode == 'cmdline' and { 1, vim.fn.getcmdpos() } or vim.api.nvim_win_get_cursor(0)
  self.line = opts.mode == 'cmdline' and (vim.fn.getcmdtype() .. vim.fn.getcmdline())
    or vim.api.nvim_buf_get_lines(0, self.cursor[1] - 1, self.cursor[1], false)[1]
  self.trigger = {
    kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
      or vim.lsp.protocol.CompletionTriggerKind.Invoked,
    character = opts.trigger_character,
  }
  self.bounds = context.get_bounds(self.cursor, self.line, opts.keyword_regex)

  return self
end

--- Moves forward and backwards around the cursor looking for word boundaries
function context.get_bounds(cursor, line, regex)
  local cursor_line = cursor[1]
  local cursor_col = cursor[2]

  local start_col = cursor_col
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match(regex) == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end

  local end_col = cursor_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match(regex) == nil then break end
    end_col = end_col + 1
  end

  -- hack: why do we have to math.min here?
  start_col = math.min(start_col, end_col)

  local length = end_col - start_col + 1
  -- Since sub(1, 1) returns a single char string, we need to check if that single char matches
  -- and otherwise mark the length as 0
  if start_col == end_col and line:sub(start_col, end_col):match(regex) == nil then length = 0 end

  return { line_number = cursor_line, start_col = start_col, end_col = end_col, length = length }
end

function context:get_keyword()
  vim.print('line: ' .. self.line)
  vim.print('bounds: ' .. vim.inspect(self.bounds))
  vim.print('keyword: ' .. self.line:sub(self.bounds.start_col, self.bounds.start_col + self.bounds.length - 1))
  return self.line:sub(self.bounds.start_col + 1, self.bounds.start_col + self.bounds.length)
end

function context:get_cursor()
  return self.mode == 'cmdline' and { 1, vim.fn.getcmdpos() - 1 } or vim.api.nvim_win_get_cursor(self.bufnr)
end

function context:get_line()
  return self.mode == 'cmdline' and vim.fn.getcmdline()
    or vim.api.nvim_buf_get_lines(0, self:get_cursor()[1] - 1, self:get_cursor()[1], false)[1]
end

--- Gets characters around the cursor and returns the range
--- @param range 'prefix' | 'full'
--- @param regex string
--- @param exclude_from_prefix_regex string
--- @return { start_col: number, length: number }
--- TODO: switch to return start_col, length to simplify downstream logic
function context:get_regex_around_cursor(range, regex, exclude_from_prefix_regex)
  local current_col = self:get_cursor()[2] + 1
  local line = self:get_line()

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

function context:is_within_bounds(cursor)
  local row, col = cursor[1], cursor[2]
  return row == self.bounds.line_number and col >= self.bounds.start_col and col <= self.bounds.end_col
end

return context
