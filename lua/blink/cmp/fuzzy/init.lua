local config = require('blink.cmp.config')

--- @class blink.cmp.Fuzzy
local fuzzy = {
  rust = require('blink.cmp.fuzzy.rust'),
  haystacks_by_provider_cache = {},
  has_init_db = false,
}

function fuzzy.init_db()
  if fuzzy.has_init_db then return end

  fuzzy.rust.init_db(vim.fn.stdpath('data') .. '/blink/cmp/fuzzy.db', config.use_unsafe_no_lock)

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = fuzzy.rust.destroy_db,
  })

  fuzzy.has_init_db = true
end

---@param item blink.cmp.CompletionItem
function fuzzy.access(item)
  fuzzy.init_db()

  -- writing to the db takes ~10ms, so schedule writes in another thread
  vim.uv
    .new_work(function(itm, cpath)
      package.cpath = cpath
      require('blink.cmp.fuzzy.rust').access(vim.mpack.decode(itm))
    end, function() end)
    :queue(vim.mpack.encode(item), package.cpath)
end

---@param lines string
function fuzzy.get_words(lines) return fuzzy.rust.get_words(lines) end

--- @param line string
--- @param cursor_col number
--- @param haystack string[]
--- @param range blink.cmp.CompletionKeywordRange
function fuzzy.fuzzy_matched_indices(line, cursor_col, haystack, range)
  return fuzzy.rust.fuzzy_matched_indices(line, cursor_col, haystack, range == 'full')
end

--- @param line string
--- @param cursor_col number
--- @param haystacks_by_provider table<string, blink.cmp.CompletionItem[]>
--- @param range blink.cmp.CompletionKeywordRange
--- @return blink.cmp.CompletionItem[]
function fuzzy.fuzzy(line, cursor_col, haystacks_by_provider, range)
  fuzzy.init_db()

  for provider_id, haystack in pairs(haystacks_by_provider) do
    -- set the provider items once since Lua <-> Rust takes the majority of the time
    if fuzzy.haystacks_by_provider_cache[provider_id] ~= haystack then
      fuzzy.haystacks_by_provider_cache[provider_id] = haystack
      fuzzy.rust.set_provider_items(provider_id, haystack)
    end
  end

  -- get the nearby words
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local start_row = math.max(0, cursor_row - 30)
  local end_row = math.min(cursor_row + 30, vim.api.nvim_buf_line_count(0))
  local nearby_text = table.concat(vim.api.nvim_buf_get_lines(0, start_row, end_row, false), '\n')
  local nearby_words = #nearby_text < 10000 and fuzzy.rust.get_words(nearby_text) or {}

  local keyword_start_col, keyword_end_col =
    require('blink.cmp.fuzzy').get_keyword_range(line, cursor_col, config.completion.keyword.range)
  local keyword_length = keyword_end_col - keyword_start_col
  local keyword = line:sub(keyword_start_col, keyword_end_col)

  local filtered_items = {}
  for provider_id, haystack in pairs(haystacks_by_provider) do
    -- perform fuzzy search
    local scores, matched_indices = fuzzy.rust.fuzzy(line, cursor_col, provider_id, {
      -- TODO: make this configurable
      max_typos = config.fuzzy.max_typos(keyword),
      use_frecency = config.fuzzy.use_frecency and keyword_length > 0,
      use_proximity = config.fuzzy.use_proximity and keyword_length > 0,
      sorts = config.fuzzy.sorts,
      nearby_words = nearby_words,
      match_suffix = range == 'full',
    })

    for idx, item_index in ipairs(matched_indices) do
      local item = haystack[item_index + 1]
      item.score = scores[idx]
      table.insert(filtered_items, item)
    end
  end

  return require('blink.cmp.fuzzy.sort').sort(filtered_items, config.fuzzy.sorts)
end

--- @param line string
--- @param col number
--- @param range? blink.cmp.CompletionKeywordRange
--- @return number, number
function fuzzy.get_keyword_range(line, col, range)
  return require('blink.cmp.fuzzy.rust').get_keyword_range(line, col, range == 'full')
end

function fuzzy.is_keyword_character(char)
  -- special case for hyphen, since we don't consider a lone hyphen to be a keyword
  if char == '-' then return true end

  local keyword_start_col, keyword_end_col = fuzzy.get_keyword_range(char, #char, 'prefix')
  return keyword_start_col ~= keyword_end_col
end

--- @param item blink.cmp.CompletionItem
--- @param line string
--- @param col number
--- @param range blink.cmp.CompletionKeywordRange
--- @return number, number
function fuzzy.guess_edit_range(item, line, col, range)
  return require('blink.cmp.fuzzy.rust').guess_edit_range(item, line, col, range == 'full')
end

return fuzzy
