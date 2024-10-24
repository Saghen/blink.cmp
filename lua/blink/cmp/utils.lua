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

function utils.split_lines(text)
  local lines = {}
  for s in text:gmatch('[^\r\n]+') do
    table.insert(lines, s)
  end
  return lines
end

--- Combines adjacent paragraph lines together
--- @param lines string[]
--- @return string[]
--- TODO: Likely buggy
function utils.combine_markdown_lines(lines)
  local combined_lines = {}

  local special_starting_chars = { '#', '>', '-', '|' }
  local in_code_block = false
  local prev_is_special = false
  for _, line in ipairs(lines) do
    if line:match('^%s*```') then in_code_block = not in_code_block end

    local is_special = line:match('^%s*[' .. table.concat(special_starting_chars) .. ']') or line:match('^%s*%d\\.$')
    local is_empty = line:match('^%s*$')
    local has_linebreak = line:match('%s%s$')

    if #combined_lines == 0 or in_code_block or is_special or prev_is_special or is_empty or has_linebreak then
      table.insert(combined_lines, line)
    elseif line:match('^%s*$') then
      table.insert(combined_lines, '')
    else
      combined_lines[#combined_lines] = combined_lines[#combined_lines] .. '' .. line
    end

    prev_is_special = is_special
  end

  return combined_lines
end

--- Highlights the given range with treesitter with the given filetype
--- @param bufnr number
--- @param filetype string
--- @param start_line number
--- @param end_line number
--- TODO: fallback to regex highlighting if treesitter fails
function utils.highlight_with_treesitter(bufnr, filetype, start_line, end_line)
  local Range = require('vim.treesitter._range')

  local root_lang = vim.treesitter.language.get_lang(filetype)
  if root_lang == nil then return end

  local success, trees = pcall(vim.treesitter.get_parser, bufnr, root_lang)
  if not success then return end

  trees:parse({ start_line, end_line })
  if not trees then return end

  trees:for_each_tree(function(tree, tstree)
    local lang = tstree:lang()
    local highlighter_query = vim.treesitter.query.get(lang, 'highlights')
    if not highlighter_query then return end

    local root_node = tree:root()
    local _, _, root_end_row, _ = root_node:range()

    local iter = highlighter_query:iter_captures(tree:root(), bufnr, start_line, end_line)
    local line = start_line
    while line < end_line do
      local capture, node, metadata, _ = iter(line)
      if capture == nil then break end

      local range = { root_end_row + 1, 0, root_end_row + 1, 0 }
      if node then range = vim.treesitter.get_range(node, bufnr, metadata and metadata[capture]) end
      local start_row, start_col, end_row, end_col = Range.unpack4(range)

      if capture then
        local name = highlighter_query.captures[capture]
        local hl = 0
        if not vim.startswith(name, '_') then hl = vim.api.nvim_get_hl_id_by_name('@' .. name .. '.' .. lang) end

        -- The "priority" attribute can be set at the pattern level or on a particular capture
        local priority = (
          tonumber(metadata.priority or metadata[capture] and metadata[capture].priority)
          or vim.highlight.priorities.treesitter
        )

        -- The "conceal" attribute can be set at the pattern level or on a particular capture
        local conceal = metadata.conceal or metadata[capture] and metadata[capture].conceal

        if hl and end_row >= line then
          vim.api.nvim_buf_set_extmark(bufnr, require('blink.cmp.config').highlight.ns, start_row, start_col, {
            end_line = end_row,
            end_col = end_col,
            hl_group = hl,
            priority = priority,
            conceal = conceal,
          })
        end
      end

      if start_row > line then line = start_row end
    end
  end)
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
