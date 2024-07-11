local cmp = {}

cmp.kind_icons = {
  Text = '󰉿',
  Method = '󰊕',
  Function = '󰊕',
  Constructor = '󰒓',

  Field = '󰜢',
  Variable = '󰆦',
  Property = '󰖷',

  Class = '󱡠',
  Interface = '󱡠',
  Struct = '󱡠',
  Module = '󰅩',

  Unit = '󰪚',
  Value = '󰦨',
  Enum = '󰦨',
  EnumMember = '󰦨',

  Keyword = '󰻾',
  Constant = '󰏿',

  Snippet = '󱄽',
  Color = '󰏘',
  File = '󰈔',
  Reference = '󰬲',
  Folder = '󰉋',
  Event = '󱐋',
  Operator = '󰪚',
  TypeParameter = '󰬛',
}
cmp.filtered_items = {}
-- the column of the cursor when the items were fetched
cmp.items_column = -1

cmp.fuzzy = require('blink.fuzzy').fuzzy
cmp.lsp = require('blink.cmp.lsp')

cmp.accept = function(cmp_win)
  -- Get the item from the filtered items based on the cursorline position
  local item = cmp.filtered_items[vim.api.nvim_win_get_cursor(cmp_win.id)[1]]
  local text_edit = item.item.textEdit

  if text_edit ~= nil then
    -- Adjust the position of the text edit to be the current cursor position
    -- since the data might be outdated. We compare the cursor column position
    -- from when the items were fetched versus the current.
    -- HACK: need to figure out a better way
    local offset = vim.api.nvim_win_get_cursor(0)[2] - cmp.items_cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset

    -- Delete the old text
    vim.api.nvim_buf_set_text(
      vim.api.nvim_get_current_buf(),
      text_edit.range.start.line,
      text_edit.range.start.character,
      text_edit.range['end'].line,
      text_edit.range['end'].character,
      {}
    )

    -- HACK: some LSPs (typescript-language-server) include snippets in non-snippet
    -- completions because fuck a spec so we expand all text as a snippet
    vim.snippet.expand(text_edit.newText)

    -- Apply the text edit and move the cursor
    -- cmp.apply_text_edits(item.client_id, { text_edit })
    -- vim.api.nvim_win_set_cursor(
    --   0,
    --   { text_edit.range.start.line + 1, text_edit.range.start.character + #text_edit.newText }
    -- )
  else
    -- No text edit so we fallback to our own resolution
    -- TODO: LSP provides info on what chars should be replaced in general
    -- and the get_query_to_replace function should take advantage of it
    local current_line, start_col, end_col = cmp.get_query_to_replace(vim.api.nvim_get_current_buf())
    vim.api.nvim_buf_set_text(
      vim.api.nvim_get_current_buf(),
      current_line,
      start_col,
      current_line,
      end_col,
      { item.word }
    )
    vim.api.nvim_win_set_cursor(0, { current_line + 1, start_col + #item.word })
  end

  -- Apply additional text edits
  -- LSPs can either include these in the initial response or require a resolve
  -- These are used for things like auto-imports
  -- TODO: check capabilities to know ahead of time
  if item.additionalTextEdits ~= nil then
    cmp.apply_additional_text_edits(item.client_id, item)
  else
    cmp.lsp.resolve(
      item.item,
      function(client_id, resolved_item) cmp.apply_additional_text_edits(client_id, resolved_item) end
    )
  end
end

cmp.select_next = function(cmp_win, doc_win)
  if cmp_win.id == nil then return end

  local current_line = vim.api.nvim_win_get_cursor(cmp_win.id)[1]
  local item_count = #cmp.filtered_items
  local line_count = vim.api.nvim_buf_line_count(cmp_win.buf)

  -- draw a new line if we're at the end and there's more items
  -- todo: this is a hack while waiting for virtual scroll
  if current_line == line_count and item_count > line_count then
    cmp.draw_item(cmp_win.buf, line_count + 1, cmp.filtered_items[line_count + 1])
    vim.api.nvim_win_set_cursor(cmp_win.id, { line_count + 1, 0 })
  -- otherwise just move the cursor, wrapping if at the bottom
  else
    local line = current_line == item_count and 1 or current_line + 1
    vim.api.nvim_win_set_cursor(cmp_win.id, { line, 0 })
  end

  cmp.update_doc(cmp_win, doc_win)
end

-- todo: how to handle overflow to the bottom? should probably just do proper virtual scroll
cmp.select_prev = function(cmp_win, doc_win)
  if cmp_win.id == nil then return end

  local current_line = vim.api.nvim_win_get_cursor(cmp_win.id)[1]
  local line_count = vim.api.nvim_buf_line_count(cmp_win.buf)
  local line = current_line - 1 == 0 and line_count or current_line - 1
  vim.api.nvim_win_set_cursor(cmp_win.id, { line, 0 })

  cmp.update_doc(cmp_win, doc_win)
end

cmp.update = function(cmp_win, doc_win, items, cursor_column, opts)
  local query = cmp.get_query()

  -- get the items based on the user's query
  local filtered_items = cmp.filter_items(query, items)
  cmp.items_cursor_column = cursor_column

  -- guards for cases where we shouldn't show the completion window
  local no_items = #filtered_items == 0
  local is_exact_match = #filtered_items == 1 and filtered_items[1].word == query and opts.force ~= true
  local not_in_insert = vim.api.nvim_get_mode().mode ~= 'i'
  local no_query = query == '' and opts.force ~= true
  if no_items or is_exact_match or not_in_insert or no_query then
    cmp_win:close()
    doc_win:close()
    return
  end
  cmp_win:open()

  -- update completion window
  vim.api.nvim_buf_set_lines(cmp_win.buf, 0, -1, true, {})
  vim.api.nvim_buf_set_option(cmp_win.buf, 'modified', false)

  for idx, item in ipairs(filtered_items) do
    cmp.draw_item(cmp_win.buf, idx, item)
    -- only draw until the window is full
    if idx >= cmp_win.config.max_height then break end
  end
  -- select first line
  vim.api.nvim_win_set_cursor(cmp_win.id, { 1, 0 })
  cmp_win:update()

  -- documentation
  cmp.update_doc(cmp_win, doc_win)

  cmp.filtered_items = filtered_items
end

function cmp.update_doc(cmp_win, doc_win)
  -- completion window isn't open
  if cmp_win.id == nil then return end

  local current_line = vim.api.nvim_win_get_cursor(cmp_win.id)[1]
  local item = cmp.filtered_items[current_line]
  if item == nil then
    doc_win:close()
    return
  end

  cmp.lsp.resolve(item, function(_, resolved_item)
    if resolved_item.detail == nil then
      doc_win:close()
      return
    end
    local doc_lines = {}
    for s in resolved_item.detail:gmatch('[^\r\n]+') do
      table.insert(doc_lines, s)
    end
    vim.api.nvim_buf_set_lines(doc_win.buf, 0, -1, true, doc_lines)
    doc_win:open()

    -- set unmodified so we don't get the prompt to save
    vim.api.nvim_buf_set_option(doc_win.buf, 'modified', false)
  end)
end

---------- UTILS ------------
cmp.draw_item = function(bufnr, idx, item)
  -- get highlight
  local kind_hl = 'CmpItemKind' .. item.kind
  local kind_icon = cmp.kind_icons[item.kind] or cmp.kind_icons.Field
  local kind = item.kind

  -- get line text
  local max_length = 40
  local utf8len = vim.fn.strdisplaywidth
  local other_content_length = utf8len(kind_icon) + utf8len(kind) + 5
  local remaining_length = math.max(0, max_length - other_content_length - utf8len(item.abbr))
  local abbr = string.sub(item.abbr, 1, max_length - other_content_length) .. string.rep(' ', remaining_length)

  local line = string.format(' %s  %s %s ', kind_icon, abbr, kind)

  -- draw the line
  vim.api.nvim_buf_set_lines(bufnr, idx - 1, idx, false, { line })
  vim.api.nvim_buf_add_highlight(bufnr, -1, kind_hl, idx - 1, 0, #kind_icon + 2)

  -- set unmodified so we don't get the prompt to save
  vim.api.nvim_buf_set_option(bufnr, 'modified', false)
end

cmp.filter_items = function(query, items)
  if query == '' then return items end

  -- convert to table of strings
  local words = {}
  for _, item in ipairs(items) do
    table.insert(words, item.word)
  end

  -- perform fuzzy search
  local filtered_items = {}
  local selected_indices = cmp.fuzzy(query, words)
  for _, selected_index in ipairs(selected_indices) do
    table.insert(filtered_items, items[selected_index + 1])
  end

  return filtered_items
end

cmp.get_query = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local current_col = vim.api.nvim_win_get_cursor(0)[2] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line, current_line + 1, false)[1]
  local query = string.sub(line, 1, current_col + 1):match('[%w_\\-]+$') or ''
  return query
end

cmp.get_query_to_replace = function(bufnr)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]

  -- Search forward/backward for the start/end of the word
  local start_col = current_col
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match('[%w_\\-]') == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end

  local end_col = current_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match('[%w_\\-]') == nil then break end
    end_col = end_col + 1
  end

  -- convert to 0-index
  return current_line - 1, start_col - 1, end_col
end

cmp.apply_additional_text_edits = function(client_id, item)
  cmp.apply_text_edits(client_id, item.additionalTextEdits or {})
end

cmp.apply_text_edits = function(client_id, edits)
  local offset_encoding = vim.lsp.get_client_by_id(client_id).offset_encoding
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), offset_encoding)
end

return cmp
