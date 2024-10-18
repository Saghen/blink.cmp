local config = require('blink.cmp.config').fuzzy

local fuzzy = {
  ---@type blink.cmp.Context?
  last_context = nil,
  ---@type blink.cmp.CompletionItem[]?
  last_items = nil,
  rust = require('libblink_cmp_fuzzy'),
}

---@param db_path string
function fuzzy.init_db(db_path)
  fuzzy.rust.init_db(db_path)

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = fuzzy.rust.destroy_db,
  })

  return fuzzy
end

---@param item blink.cmp.CompletionItem
function fuzzy.access(item) fuzzy.rust.access(item) end

---@param lines string
function fuzzy.get_words(lines) return fuzzy.rust.get_words(lines) end

---@param needle string
---@param items blink.cmp.CompletionItem[]?
---@return blink.cmp.CompletionItem[]
function fuzzy.filter_items(needle, haystack)
  haystack = haystack or {}

  -- get the nearby words
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local start_row = math.max(0, cursor_row - 30)
  local end_row = math.min(cursor_row + 30, vim.api.nvim_buf_line_count(0))
  local nearby_words =
    fuzzy.rust.get_words(table.concat(vim.api.nvim_buf_get_lines(0, start_row, end_row, false), '\n'))

  -- perform fuzzy search
  local filtered_items = {}
  local matched_indices = fuzzy.rust.fuzzy(needle, haystack, {
    -- each matching char is worth 4 points and it receives a bonus for capitalization, delimiter and prefix
    -- so this should generally be good
    -- TODO: make this configurable
    min_score = 6 * needle:len(),
    max_items = config.max_items,
    use_frecency = config.use_frecency,
    use_proximity = config.use_proximity,
    sorts = config.sorts,
    nearby_words = nearby_words,
  })

  for _, idx in ipairs(matched_indices) do
    table.insert(filtered_items, haystack[idx + 1])
  end

  return filtered_items
end

---@param needle string
---@param context blink.cmp.Context
---@param items blink.cmp.CompletionItem[]?
function fuzzy.filter_items_with_cache(needle, context, items)
  if items == nil then
    if fuzzy.last_context == nil or fuzzy.last_context.id ~= context.id then return {} end
    items = fuzzy.last_items
  end
  fuzzy.last_context = context
  fuzzy.last_items = items

  return fuzzy.filter_items(needle, items)
end

--- Gets the text under the cursor to be used for fuzzy matching
--- @param regex string | nil
--- @return string
function fuzzy.get_query(regex)
  if regex == nil then regex = '[%w_\\-]+$' end

  local bufnr = vim.api.nvim_get_current_buf()

  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local current_col = vim.api.nvim_win_get_cursor(0)[2] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line, current_line + 1, false)[1]

  return string.sub(line, 1, current_col + 1):match(regex) or ''
end

return fuzzy
