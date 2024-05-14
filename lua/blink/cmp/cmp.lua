local M = {}

M.kind_icons = {
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
M.filtered_items = {}

M.fuzzy = require('blink.fuzzy').fuzzy
M.lsp = require('blink.cmp.lsp')

M.accept = function(cmp_win)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line, start_col, end_col = M.get_query_to_replace(bufnr)

  -- Get the item from the filtered items based on the cursorline position
  local item = M.filtered_items[vim.api.nvim_win_get_cursor(cmp_win.id)[1]]

  -- Apply text edit
  vim.api.nvim_buf_set_text(bufnr, current_line, start_col, current_line, end_col, { item.word })
  vim.api.nvim_win_set_cursor(0, { current_line + 1, start_col + #item.word })

  -- Apply additional text edits
  -- LSPs can either include these in the initial response or require a resolve
  -- These are used for things like auto-imports
  -- todo: check capabilities to know ahead of time
  if item.additionalTextEdits ~= nil then
    M.apply_additional_text_edits(item.client_id, item)
  else
    M.lsp.resolve(item, function(client_id, resolved_item) M.apply_additional_text_edits(client_id, resolved_item) end)
  end
end

M.select_next = function(cmp_win)
  local current_line = vim.api.nvim_win_get_cursor(cmp_win.id)[1]
  vim.api.nvim_win_set_cursor(cmp_win.id, { current_line + 1, 0 })
end

M.select_prev = function(cmp_win)
  local current_line = vim.api.nvim_win_get_cursor(cmp_win.id)[1]
  vim.api.nvim_win_set_cursor(cmp_win.id, { current_line - 1, 0 })
end

M.update = function(cmp_win, doc_win, items, opts)
  local query = M.get_query()

  -- get the items based on the user's query
  local filtered_items = M.filter_items(query, items)

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
  for idx, item in ipairs(filtered_items) do
    local max_length = 40
    local kind_hl = 'CmpItemKind' .. item.kind
    local kind_icon = M.kind_icons[item.kind] or M.kind_icons.Field
    local kind = item.kind

    local utf8len = vim.fn.strdisplaywidth
    local other_content_length = utf8len(kind_icon) + utf8len(kind) + 5
    local remaining_length = math.max(0, max_length - other_content_length - utf8len(item.abbr))
    local abbr = string.sub(item.abbr, 1, max_length - other_content_length) .. string.rep(' ', remaining_length)

    local line = string.format(' %s  %s %s ', kind_icon, abbr, kind)
    vim.api.nvim_buf_set_lines(cmp_win.buf, idx - 1, idx, false, { line })
    vim.api.nvim_buf_add_highlight(cmp_win.buf, -1, kind_hl, idx - 1, 0, #kind_icon + 2)

    if idx > cmp_win.config.max_height then break end
  end

  -- set height
  vim.api.nvim_win_set_height(cmp_win.id, math.min(#filtered_items, cmp_win.config.max_height))

  -- select first line
  vim.api.nvim_win_set_cursor(cmp_win.id, { 1, 0 })

  -- documentation
  local first_item = filtered_items[1]
  if first_item ~= nil then
    M.lsp.resolve(first_item, function(_, resolved_item)
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
    end)
  end

  M.filtered_items = filtered_items
end

---------- UTILS ------------

M.filter_items = function(query, items)
  if query == '' then return items end

  -- convert to table of strings
  local words = {}
  for _, item in ipairs(items) do
    table.insert(words, item.word)
  end

  -- perform fuzzy search
  local filtered_items = {}
  local selected_indices = M.fuzzy(query, words)
  for _, selected_index in ipairs(selected_indices) do
    table.insert(filtered_items, items[selected_index + 1])
  end

  return filtered_items
end

M.get_query = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local current_col = vim.api.nvim_win_get_cursor(0)[2] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line, current_line + 1, false)[1]
  local query = string.sub(line, 1, current_col + 1):match('[%w_\\-]+$') or ''
  return query
end

M.get_query_to_replace = function(bufnr)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]

  -- Search forward/backward for the start/end of the word
  local start_col = current_col
  while start_col > 1 do
    local char = line:sub(start_col - 1, start_col - 1)
    if char:match('[%w_\\-]') == nil then break end
    start_col = start_col - 1
  end

  local end_col = current_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match('[%w_\\-]') == nil then break end
    end_col = end_col + 1
  end

  -- convert to 0-index
  return current_line - 1, start_col - 1, end_col - 1
end

M.apply_additional_text_edits = function(client_id, item) M.apply_text_edits(client_id, item.additionalTextEdits or {}) end

M.apply_text_edits = function(client_id, edits)
  local offset_encoding = vim.lsp.get_client_by_id(client_id).offset_encoding
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), offset_encoding)
end

return M
