local MATCH_SCORE = 7
local GAP_PENALTY = -1

-- bonus for matching the first character of the haystack
local PREFIX_BONUS = 6
-- bonus for matching character after a delimiter in the haystack (e.g. space, comma, underscore, slash, etc)
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
--- @return number?, boolean?
local function match(needle, haystack)
  local score = 0
  local haystack_idx = 1

  for needle_idx = 1, #needle do
    local needle_char = string.byte(needle, needle_idx)
    local is_upper = needle_char >= 65 and needle_char <= 90
    local is_lower = needle_char >= 97 and needle_char <= 122

    local needle_lower_char = is_upper and needle_char + 32 or needle_char
    local needle_upper_char = is_lower and needle_char - 32 or needle_char

    local haystack_start_idx = haystack_idx
    while haystack_idx <= (#haystack - #needle + needle_idx) do
      local haystack_char = string.byte(haystack, haystack_idx)

      if needle_lower_char == haystack_char or needle_upper_char == haystack_char then
        score = score + MATCH_SCORE

        -- gap penalty
        if needle_idx ~= 1 then score = score + GAP_PENALTY * (haystack_idx - haystack_start_idx) end

        -- bonuses
        if needle_char == haystack_char then score = score + MATCHING_CASE_BONUS end
        if haystack_idx == 1 then score = score + PREFIX_BONUS end
        if DELIMITERS[string.byte(haystack, haystack_idx - 1)] then score = score + DELIMITER_BONUS end

        haystack_idx = haystack_idx + 1
        goto continue
      end

      haystack_idx = haystack_idx + 1
    end

    -- didn't find a match, so return nil
    if true then return end

    ::continue::
  end

  local exact = needle == haystack
  if exact then score = score + EXACT_MATCH_BONUS end

  return score, exact
end

assert(match('fbb', 'barbazfoobarbaz') == 20, 'fbb should match barbazfoobarbaz with score 18')
assert(match('foo', '_foobar') == 28, 'foo should match foobar with score 29')
assert(match('Foo', 'foobar') == 29, 'foo should match foobar with score 29')
assert(match('foo', 'foobar') == 30, 'foo should match foobar with score 30')
assert(match('foo', 'fobar') == nil, 'foo should not match fobar')

return match
