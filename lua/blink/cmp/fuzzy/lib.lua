local fuzzy = {
  rust = require('blink.cmp.fuzzy'),
}

function fuzzy.init_db(db_path)
  fuzzy.rust.init_db(db_path)
  return fuzzy
end

function fuzzy.fuzzy(needle, haystack, haystack_score_offsets, nearby_words, max_items)
  return fuzzy.rust.fuzzy(needle, haystack, haystack_score_offsets, nearby_words, max_items)
end

function fuzzy.access(item) fuzzy.rust.access(item) end

function fuzzy.get_lines_words(lines) return fuzzy.rust.get_lines_words(lines) end

function fuzzy.filter_items(needle, items)
  -- convert to table of strings
  local haystack = {}
  local haystack_score_offsets = {}
  for _, item in ipairs(items) do
    table.insert(haystack, item.label)
    table.insert(haystack_score_offsets, item.score_offset or 0)
  end

  -- get the nearby words
  local cursor_column = vim.api.nvim_win_get_cursor(0)[2]
  local nearby_words = fuzzy.rust.get_lines_words(
    table.concat(vim.api.nvim_buf_get_lines(0, cursor_column - 30, cursor_column + 30, false), '\n')
  )

  -- perform fuzzy search
  local filtered_items = {}
  local max_items = 200
  local selected_indices = fuzzy.rust.fuzzy(needle, haystack, haystack_score_offsets, nearby_words, max_items)
  for _, selected_index in ipairs(selected_indices) do
    table.insert(filtered_items, items[selected_index + 1])
  end

  return filtered_items
end

function fuzzy.get_query()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local current_col = vim.api.nvim_win_get_cursor(0)[2] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line, current_line + 1, false)[1]
  local query = string.sub(line, 1, current_col + 1):match('[%w_\\-]+$') or ''
  return query
end

return fuzzy
