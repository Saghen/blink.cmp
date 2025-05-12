local match = require('blink.cmp.fuzzy.lua.match')
local match_indices = require('blink.cmp.fuzzy.lua.match_indices')
local get_keyword_range = require('blink.cmp.fuzzy.lua.keyword').get_keyword_range
local guess_keyword_range_from_item = require('blink.cmp.fuzzy.lua.keyword').guess_keyword_range_from_item

--- @type blink.cmp.FuzzyImplementation
--- @diagnostic disable-next-line: missing-fields
local fuzzy = {
  provider_items = {},
}

function fuzzy.init_db() end
function fuzzy.destroy_db() end
function fuzzy.access() end

local words_regex = vim.regex(
  [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\%(\w\|á\|Á\|é\|É\|í\|Í\|ó\|Ó\|ú\|Ú\)*\%(-\%(\w\|á\|Á\|é\|É\|í\|Í\|ó\|Ó\|ú\|Ú\)*\)*\)]]
)

--- Takes ~0.25ms for 1200 characters split over 40 lines
function fuzzy.get_words(text)
  local words = {}

  while #text > 0 do
    local match_start, match_end = words_regex:match_str(text)
    if match_start == nil then break end

    if match_end - match_start > 2 then
      local word = text:sub(match_start + 1, match_end)
      words[word] = true
    end

    text = text:sub(match_end + 1)
  end

  return vim.tbl_keys(words)
end

function fuzzy.set_provider_items(provider_id, items) fuzzy.provider_items[provider_id] = items end

function fuzzy.fuzzy(line, cursor_col, provider_id, opts)
  local keyword_start, keyword_end = get_keyword_range(line, cursor_col, opts.match_suffix)
  local keyword = line:sub(keyword_start + 1, keyword_end)

  local scores = {}
  local matched_indices = {}
  local exacts = {}
  for idx, item in ipairs(fuzzy.provider_items[provider_id] or {}) do
    local score, exact = match(keyword, item.filterText or item.label)
    if score ~= nil then
      table.insert(scores, score)
      table.insert(matched_indices, idx - 1)
      table.insert(exacts, exact)
    end
  end

  return scores, matched_indices, exacts
end

function fuzzy.fuzzy_matched_indices(line, cursor_col, haystack, match_suffix)
  local keyword_start, keyword_end = get_keyword_range(line, cursor_col, match_suffix)
  local keyword = line:sub(keyword_start + 1, keyword_end)

  return vim.tbl_map(function(text) return match_indices(keyword, text) end, haystack)
end

function fuzzy.get_keyword_range(line, col, match_suffix) return get_keyword_range(line, col, match_suffix) end

function fuzzy.guess_edit_range(item, line, col, match_suffix)
  return guess_keyword_range_from_item(item.insertText or item.label, line, col, match_suffix)
end

return fuzzy
