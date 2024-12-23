local config = require('blink.cmp.config')

local fuzzy = {
  rust = require('blink.cmp.fuzzy.rust'),
  haystacks_by_provider_cache = {},
  has_init_db = false,
}

function fuzzy.init_db()
  if fuzzy.has_init_db then return end

  fuzzy.rust.init_db(vim.fn.stdpath('data') .. '/blink/cmp/fuzzy.db')

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

function fuzzy.fuzzy_matched_indices(needle, haystack) return fuzzy.rust.fuzzy_matched_indices(needle, haystack) end

--- @param needle string
--- @param haystacks_by_provider table<string, blink.cmp.CompletionItem[]>
--- @return blink.cmp.CompletionItem[]
function fuzzy.fuzzy(needle, haystacks_by_provider)
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

  local filtered_items = {}
  for provider_id, haystack in pairs(haystacks_by_provider) do
    -- perform fuzzy search
    local scores, matched_indices = fuzzy.rust.fuzzy(needle, provider_id, {
      -- each matching char is worth 4 points and it receives a bonus for capitalization, delimiter and prefix
      -- so this should generally be good
      -- TODO: make this configurable
      min_score = config.fuzzy.use_typo_resistance and (6 * needle:len()) or 0,
      use_typo_resistance = config.fuzzy.use_typo_resistance,
      use_frecency = config.fuzzy.use_frecency and #needle > 0,
      use_proximity = config.fuzzy.use_proximity and #needle > 0,
      sorts = config.fuzzy.sorts,
      nearby_words = nearby_words,
    })

    for idx, item_index in ipairs(matched_indices) do
      local item = haystack[item_index + 1]
      item.score = scores[idx]
      table.insert(filtered_items, item)
    end
  end

  return require('blink.cmp.fuzzy.sort').sort(filtered_items, config.fuzzy.sorts)
end

return fuzzy
