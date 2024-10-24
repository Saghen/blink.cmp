local config = require('blink.cmp.config')

local fuzzy = {
  rust = require('blink.cmp.fuzzy.rust'),
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
---@param haystack blink.cmp.CompletionItem[]?
---@return blink.cmp.CompletionItem[]
function fuzzy.filter_items(needle, haystack)
  haystack = haystack or {}

  -- get the nearby words
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local start_row = math.max(0, cursor_row - 30)
  local end_row = math.min(cursor_row + 30, vim.api.nvim_buf_line_count(0))
  local nearby_text = table.concat(vim.api.nvim_buf_get_lines(0, start_row, end_row, false), '\n')
  local nearby_words = #nearby_text < 10000 and fuzzy.rust.get_words(nearby_text) or {}

  -- perform fuzzy search
  local matched_indices = fuzzy.rust.fuzzy(needle, haystack, {
    -- each matching char is worth 4 points and it receives a bonus for capitalization, delimiter and prefix
    -- so this should generally be good
    -- TODO: make this configurable
    min_score = config.fuzzy.use_typo_resistance and (6 * needle:len()) or 0,
    max_items = config.fuzzy.max_items,
    use_typo_resistance = config.fuzzy.use_typo_resistance,
    use_frecency = config.fuzzy.use_frecency,
    use_proximity = config.fuzzy.use_proximity,
    sorts = config.fuzzy.sorts,
    nearby_words = nearby_words,
  })

  local filtered_items = {}
  for _, idx in ipairs(matched_indices) do
    table.insert(filtered_items, haystack[idx + 1])
  end
  return filtered_items
end

--- Gets the text under the cursor to be used for fuzzy matching
--- @return string
function fuzzy.get_query()
  local line = vim.api.nvim_get_current_line()
  local cmp_config = config.trigger.completion
  local range = require('blink.cmp.utils').get_regex_around_cursor(
    cmp_config.keyword_range,
    cmp_config.keyword_regex,
    cmp_config.exclude_from_prefix_regex
  )
  return string.sub(line, range.start_col, range.start_col + range.length - 1)
end

return fuzzy
