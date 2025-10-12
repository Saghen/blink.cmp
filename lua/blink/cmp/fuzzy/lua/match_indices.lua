local MATCH_SCORE = 7
local GAP_PENALTY = -1

-- bonus for matching the first character of the haystack
local PREFIX_BONUS = 6
-- bonus for matching character after a delimiter in the haystack (e.g. space, comma, underscore, slash)
local DELIMITER_BONUS = 4
-- bonus for haystack == needle
local EXACT_MATCH_BONUS = 4
-- bonus for matching the case (upper or lower) of the haystack
local MATCHING_CASE_BONUS = 1

local DELIMITERS = {
  [string.byte(' ', 1)] = true,
  [string.byte('/', 1)] = true,
  [string.byte('.', 1)] = true,
  [string.byte(',', 1)] = true,
  [string.byte('_', 1)] = true,
  [string.byte('-', 1)] = true,
  [string.byte(':', 1)] = true,
}

--- @param needle string
--- @param haystack string
--- @return number[]
local function match_indices(needle, haystack)
  local matched_indices = {}

  local haystack_idx = 1
  for needle_idx = 1, #needle do
    local needle_char = string.byte(needle, needle_idx)
    local is_upper = needle_char >= 65 and needle_char <= 90
    local is_lower = needle_char >= 97 and needle_char <= 122

    local needle_lower_char = is_upper and needle_char + 32 or needle_char
    local needle_upper_char = is_lower and needle_char - 32 or needle_char

    while haystack_idx <= (#haystack - #needle + needle_idx) do
      local haystack_char = string.byte(haystack, haystack_idx)

      if needle_lower_char == haystack_char or needle_upper_char == haystack_char then
        table.insert(matched_indices, haystack_idx - 1)
        haystack_idx = haystack_idx + 1
        break
      end

      haystack_idx = haystack_idx + 1
    end
  end

  return matched_indices
end

return match_indices
