local sort = {}

--- @param list blink.cmp.CompletionItem[]
--- @param funcs ("label" | "sort_text" | "kind" | "score" | "exact" | blink.cmp.SortFunction)[]
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

function sort.exact(a, b)
  if a.exact ~= b.exact then return a.exact end
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

--- Swaps the case of a single character at index i in string s
--- @param s string
--- @param i integer
--- @return integer
local function swap_case(s, i)
  local byte = string.byte(s, i)
  if byte >= 65 and byte <= 90 then -- uppercase A-Z
    return byte + 32 -- convert to lowercase
  elseif byte >= 97 and byte <= 122 then -- lowercase a-z
    return byte - 32 -- convert to uppercase
  else
    return byte -- non-alphabetic characters
  end
end

function sort.label(a, b)
  -- prefer foo_bar over _foo_bar
  local _, entry1_under = a.label:find('^_+')
  local _, entry2_under = b.label:find('^_+')
  entry1_under = entry1_under or 0
  entry2_under = entry2_under or 0
  if entry1_under > entry2_under then
    return false
  elseif entry1_under < entry2_under then
    return true
  end

  -- prefer "a" over "A" and "a" over "b"
  -- Compare characters one by one with case flipping
  for i = 1, math.min(#a.label, #b.label) do
    local char_a = swap_case(a.label, i)
    local char_b = swap_case(b.label, i)

    if char_a ~= char_b then return char_a < char_b end
  end

  if #a.label ~= #b.label then return #a.label < #b.label end
end

return sort
