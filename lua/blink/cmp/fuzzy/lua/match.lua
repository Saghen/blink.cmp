local MATCH_SCORE = 12
local GAP_OPEN_PENALTY = -5
local GAP_EXTEND_PENALTY = -1

-- bonus for matching the first character of the haystack
local PREFIX_BONUS = 12
-- bonus for matching the second character of the haystack, if the first character is not a letter (e.g. "h" on "_hello_world")
local OFFSET_PREFIX_BONUS = 8
-- bonus for matching character after a delimiter in the haystack (e.g. space, comma, underscore, slash)
local DELIMITER_BONUS = 4
-- bonus for haystack == needle
local EXACT_MATCH_BONUS = 4
-- bonus for matching the case (upper or lower) of the haystack
local MATCHING_CASE_BONUS = 4

local DELIMITERS = {
  [string.byte(' ', 1)] = true,
  [string.byte('/', 1)] = true,
  [string.byte('.', 1)] = true,
  [string.byte(',', 1)] = true,
  [string.byte('_', 1)] = true,
  [string.byte('-', 1)] = true,
  [string.byte(':', 1)] = true,
}

local function is_letter(char) return char >= 65 and char <= 90 or char >= 97 and char <= 122 end

--- @param needle string
--- @param haystack string
--- @return number?, boolean?
local function match(needle, haystack)
  local score = 0
  local haystack_idx = 1
  local has_matched = false

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
        if needle_idx ~= 1 then
          local gap_length = haystack_idx - haystack_start_idx
          if gap_length > 0 then score = score + GAP_OPEN_PENALTY + GAP_EXTEND_PENALTY * (gap_length - 1) end
        end

        -- bonuses
        if needle_char == haystack_char then score = score + MATCHING_CASE_BONUS end
        if haystack_idx == 1 then
          score = score + PREFIX_BONUS
        elseif haystack_idx == 2 and not has_matched and not is_letter(string.byte(haystack, 1)) then
          score = score + OFFSET_PREFIX_BONUS
        elseif DELIMITERS[string.byte(haystack, haystack_idx - 1)] then
          score = score + DELIMITER_BONUS
        end

        has_matched = true
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

assert(match('fbb', 'barbazfoobarbaz') == 36, 'fbb should match barbazfoobarbaz with score 36')
assert(match('foo', '_foobar') == 56, 'foo should match _foobar with score 56')
assert(match('foo', '__foobar') == 52, 'foo should match __foobar with score 52')
assert(match('Foo', 'foobar') == 56, 'foo should match foobar with score 56')
assert(match('foo', 'foobar') == 60, 'foo should match foobar with score 60')
assert(match('foo', 'fobar') == nil, 'foo should not match fobar')

return match
