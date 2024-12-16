local sort = {}

--- Similar to Zed, we split the list into two buckets, sort them separately and combine.
--- By default, the strong matches will be sorted by score and then sort_text, while the weak
--- matches will be sorted by sort_text and then score.
--- https://github.com/zed-industries/zed/blob/f64fcedab/crates/editor/src/code_context_menus.rs#L553-L566
--- @param list blink.cmp.CompletionItem[]
--- @param score_threshold number
--- @param strong_match_funcs blink.cmp.SortFunctions
--- @param weak_match_funcs blink.cmp.SortFunctions
--- @return blink.cmp.CompletionItem[]
function sort.sort(list, score_threshold, strong_match_funcs, weak_match_funcs)
  local strong_matches, weak_matches = sort.partition_by_score(list, score_threshold)

  sort.list(strong_matches, strong_match_funcs)
  sort.list(weak_matches, weak_match_funcs)

  return vim.list_extend(strong_matches, weak_matches)
end

function sort.partition_by_score(list, score_threshold)
  local above = {}
  local below = {}
  for _, item in ipairs(list) do
    if item.score >= score_threshold then
      table.insert(above, item)
    else
      table.insert(below, item)
    end
  end
  return above, below
end

--- @param list blink.cmp.CompletionItem[]
--- @param funcs blink.cmp.SortFunctions
--- @return blink.cmp.CompletionItem[]
function sort.list(list, funcs)
  local sorting_funcs = vim.tbl_map(
    function(name_or_func) return type(name_or_func) == 'string' and sort[name_or_func] or name_or_func end,
    funcs
  )
  table.sort(list, function(a, b)
    for _, sorting_func in ipairs(sorting_funcs) do
      local result = sorting_func(a, b)
      if result ~= nil then return result end
    end
  end)
  return list
end

function sort.score(a, b)
  if a.score == b.score then return end
  return a.score > b.score
end

function sort.kind(a, b)
  if a.kind == b.kind then return end
  return a.kind < b.kind
end

function sort.sort_text(a, b)
  if a.sortText == b.sortText then return end
  return a.sortText < b.sortText
end

function sort.label(a, b)
  local _, entry1_under = a.label:find('^_+')
  local _, entry2_under = b.label:find('^_+')
  entry1_under = entry1_under or 0
  entry2_under = entry2_under or 0
  if entry1_under > entry2_under then
    return false
  elseif entry1_under < entry2_under then
    return true
  end
  return a.label < b.label
end

return sort
