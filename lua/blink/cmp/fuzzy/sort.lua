local sort = {}

--- @param list blink.cmp.CompletionItem[]
--- @param funcs ("label" | "sort_text" | "kind" | "score" | blink.cmp.SortFunction)[]
--- @return blink.cmp.CompletionItem[]
function sort.sort(list, funcs)
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
  if a.sortText == b.sortText or a.sortText == nil or b.sortText == nil then return end
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
