local docs = {}

--- @param bufnr number
--- @param detail? string
--- @param documentation? lsp.MarkupContent | string
--- @param max_width number
--- @param use_treesitter_highlighting boolean
function docs.render_detail_and_documentation(bufnr, detail, documentation, max_width, use_treesitter_highlighting)
  local detail_lines = {}
  if detail and detail ~= '' then detail_lines = docs.split_lines(detail) end

  local doc_lines = {}
  if documentation ~= nil then
    local doc = type(documentation) == 'string' and documentation or documentation.value
    doc_lines = docs.split_lines(doc)
    -- if type(documentation) ~= 'string' and documentation.kind == 'markdown' then
    --   -- if the rendering seems bugged, it's likely due to this function
    --   doc_lines = docs.combine_markdown_lines(doc_lines)
    -- end
  end

  detail_lines, doc_lines = docs.extract_detail_from_doc(detail_lines, doc_lines)

  local combined_lines = vim.list_extend({}, detail_lines)
  -- add a blank line for the --- separator
  if #detail_lines > 0 and #doc_lines > 0 then table.insert(combined_lines, '') end
  vim.list_extend(combined_lines, doc_lines)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, combined_lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })

  -- Highlight with treesitter
  vim.api.nvim_buf_clear_namespace(bufnr, require('blink.cmp.config').highlight.ns, 0, -1)

  if #detail_lines > 0 and use_treesitter_highlighting then docs.highlight_with_treesitter(bufnr, vim.bo.filetype, 0, #detail_lines) end

  -- Only add the separator if there are documentation lines (otherwise only display the detail)
  if #detail_lines > 0 and #doc_lines > 0 then
    vim.api.nvim_buf_set_extmark(bufnr, require('blink.cmp.config').highlight.ns, #detail_lines, 0, {
      virt_text = { { string.rep('─', max_width) } },
      virt_text_pos = 'overlay',
      hl_eol = true,
      hl_group = 'BlinkCmpDocDetail',
    })
  end

  if #doc_lines > 0 and use_treesitter_highlighting then
    local start = #detail_lines + (#detail_lines > 0 and 1 or 0)
    docs.highlight_with_treesitter(bufnr, 'markdown', start, start + #doc_lines)
  end
end

--- Highlights the given range with treesitter with the given filetype
--- @param bufnr number
--- @param filetype string
--- @param start_line number
--- @param end_line number
--- TODO: fallback to regex highlighting if treesitter fails
--- TODO: only render what's visible
function docs.highlight_with_treesitter(bufnr, filetype, start_line, end_line)
  local Range = require('vim.treesitter._range')

  local root_lang = vim.treesitter.language.get_lang(filetype)
  if root_lang == nil then return end

  local success, trees = pcall(vim.treesitter.get_parser, bufnr, root_lang)
  if not success or not trees then return end

  trees:parse({ start_line, end_line })

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

--- Combines adjacent paragraph lines together
--- @param lines string[]
--- @return string[]
--- TODO: Likely buggy
function docs.combine_markdown_lines(lines)
  local combined_lines = {}

  local special_starting_chars = { '#', '>', '-', '|', '*', '•' }
  local in_code_block = false
  local prev_is_special = false
  for _, line in ipairs(lines) do
    if line:match('^%s*```') then in_code_block = not in_code_block end
    -- skip separators
    if line:match('^[%s\\-]+$') then goto continue end

    local is_special = line:match('^%s*[' .. table.concat(special_starting_chars) .. ']') or line:match('^%s*%d\\.$')
    local is_empty = line:match('^%s*$')
    local has_linebreak = line:match('%s%s$')

    if #combined_lines == 0 or in_code_block or is_special or prev_is_special or is_empty or has_linebreak then
      table.insert(combined_lines, line)
    elseif line:match('^%s*$') then
      if combined_lines[#combined_lines] ~= '' then table.insert(combined_lines, '') end
    else
      combined_lines[#combined_lines] = combined_lines[#combined_lines] .. '' .. line
    end

    prev_is_special = is_special
    ::continue::
  end

  return combined_lines
end

--- Gets the start and end row of the code block for the given row
--- Or returns nil if there's no code block
--- @param lines string[]
--- @param row number
--- @return number?, number?
function docs.get_code_block_range(lines, row)
  if row < 1 or row > #lines then return end
  -- get the start of the code block
  local code_block_start = nil
  for i = 1, row do
    local line = lines[i]
    if line:match('^%s*```') then
      if code_block_start == nil then
        code_block_start = i
      else
        code_block_start = nil
      end
    end
  end
  if code_block_start == nil then return end

  -- get the end of the code block
  local code_block_end = nil
  for i = row, #lines do
    local line = lines[i]
    if line:match('^%s*```') then
      code_block_end = i
      break
    end
  end
  if code_block_end == nil then return end

  return code_block_start, code_block_end
end

--- Avoids showing the detail if it's part of the documentation
--- or, if the detail is in a code block in the doc,
--- extracts the code block into the detail
---@param detail_lines string[]
---@param doc_lines string[]
---@return string[], string[]
--- TODO: Also move the code block into detail if it's at the start of the doc
--- and we have no detail
function docs.extract_detail_from_doc(detail_lines, doc_lines)
  local detail_str = table.concat(detail_lines, '\n')
  local doc_str = table.concat(doc_lines, '\n')
  local doc_str_detail_row = doc_str:find(detail_str, 1, true)

  -- didn't find the detail in the doc, so return as is
  if doc_str_detail_row == nil or #detail_str == 0 or #doc_str == 0 then
    return detail_lines, doc_lines
  end

  -- get the line of the match
  -- hack: surely there's a better way to do this but it's late 
  -- and I can't be bothered
  local offset = 1
  local detail_line = 1
  for line_num, line in ipairs(doc_lines) do
    if #line + offset > doc_str_detail_row then
      detail_line = line_num
      break
    end
    offset = offset + #line + 1
  end

  -- extract the code block, if it exists, and use it as the detail
  local code_block_start, code_block_end = docs.get_code_block_range(doc_lines, detail_line)
  if code_block_start ~= nil and code_block_end ~= nil then
    detail_lines = vim.list_slice(doc_lines, code_block_start + 1, code_block_end - 1)

    local doc_lines_start = vim.list_slice(doc_lines, 1, code_block_start - 1)
    local doc_lines_end = vim.list_slice(doc_lines, code_block_end + 1, #doc_lines)
    vim.list_extend(doc_lines_start, doc_lines_end)
    doc_lines = doc_lines_start
  else
    detail_lines = {}
  end

  return detail_lines, doc_lines
end

function docs.split_lines(text)
  local lines = {}
  for s in text:gmatch('[^\r\n]+') do
    table.insert(lines, s)
  end
  return lines
end

return docs
