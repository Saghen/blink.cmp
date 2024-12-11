local sort = {}

--- @param list blink.cmp.CompletionItem[]
--- @return blink.cmp.CompletionItem[]
function sort.sort(list)
  local config = require('blink.cmp.config').fuzzy.sorts
  local sorting_funcs = vim.tbl_map(
    function(name_or_func) return type(name_or_func) == 'string' and sort[name_or_func] or name_or_func end,
    config
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

function sort.label(a, b)
  local label_a = a.sortText or a.label
  local label_b = b.sortText or b.label
  local _, entry1_under = label_a:find('^_+')
  local _, entry2_under = label_b:find('^_+')
  entry1_under = entry1_under or 0
  entry2_under = entry2_under or 0
  if entry1_under > entry2_under then
    return false
  elseif entry1_under < entry2_under then
    return true
  end
  return a.label:lower() < b.label:lower()
end

return sort
