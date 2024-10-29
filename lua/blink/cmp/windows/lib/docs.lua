local docs = {}

--- @param bufnr number
--- @param detail? string
--- @param documentation? lsp.MarkupContent | string
function docs.render_detail_and_documentation(bufnr, detail, documentation, max_width)
  local detail_lines = {}
  if detail and detail ~= '' then detail_lines = docs.split_lines(detail) end

  local doc_lines = {}
  if documentation ~= nil then
    local doc = type(documentation) == 'string' and documentation or documentation.value
    doc_lines = docs.split_lines(doc)
    if type(documentation) ~= 'string' and documentation.kind == 'markdown' then
      -- if the rendering seems bugged, it's likely due to this function
      doc_lines = docs.combine_markdown_lines(doc_lines)
    end
  end

  local combined_lines = vim.list_extend({}, detail_lines)
  -- add a blank line for the --- separator
  if #detail_lines > 0 and #doc_lines > 0 then table.insert(combined_lines, '') end
  vim.list_extend(combined_lines, doc_lines)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, combined_lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })

  -- Highlight with treesitter
  vim.api.nvim_buf_clear_namespace(bufnr, require('blink.cmp.config').highlight.ns, 0, -1)

  if #detail_lines > 0 then docs.highlight_with_treesitter(bufnr, vim.bo.filetype, 0, #detail_lines) end

  -- Only add the separator if there are documentation lines (otherwise only display the detail)
  if #detail_lines > 0 and #doc_lines > 0 then
    vim.api.nvim_buf_set_extmark(bufnr, require('blink.cmp.config').highlight.ns, #detail_lines, 0, {
      virt_text = { { string.rep('─', max_width) } },
      virt_text_pos = 'overlay',
      hl_eol = true,
      hl_group = 'BlinkCmpDocDetail',
    })
  end

  if #doc_lines > 0 then
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

  local special_starting_chars = { '#', '>', '-', '|' }
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

function docs.split_lines(text)
  local lines = {}
  for s in text:gmatch('[^\r\n]+') do
    table.insert(lines, s)
  end
  return lines
end

return docs
