local PAIRS_AND_INVALID_CHARS = {}
string.gsub('\'"=$()[]<>{} \t\n\r', '.', function(char) PAIRS_AND_INVALID_CHARS[string.byte(char)] = true end)

local CLOSING_PAIR = {
  [string.byte('<')] = string.byte('>'),
  [string.byte('[')] = string.byte(']'),
  [string.byte('(')] = string.byte(')'),
  [string.byte('{')] = string.byte('}'),
  [string.byte('"')] = string.byte('"'),
  [string.byte("'")] = string.byte("'"),
}

local ALPHANUMERIC = {}
string.gsub(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
  '.',
  function(char) ALPHANUMERIC[string.byte(char)] = true end
)

--- Gets the prefix of the given text, stopping at brackets and quotes
--- @param text string
--- @return string
local function get_prefix_before_brackets_and_quotes(text)
  local closing_pairs_stack = {}
  local word = ''

  local add = function(char)
    word = word .. string.char(char)

    -- if we've seen the opening pair, and we've just received the closing pair,
    -- remove it from the closing pairs stack
    if closing_pairs_stack[#closing_pairs_stack] == char then
      table.remove(closing_pairs_stack, #closing_pairs_stack)
    -- if the character is an opening pair, add it to the closing pairs stack
    elseif CLOSING_PAIR[char] ~= nil then
      table.insert(closing_pairs_stack, CLOSING_PAIR[char])
    end
  end

  local has_alphanumeric = false
  for i = 1, #text do
    local char = string.byte(text, i)
    if PAIRS_AND_INVALID_CHARS[char] == nil then
      add(char)
      has_alphanumeric = has_alphanumeric or ALPHANUMERIC[char]
    elseif not has_alphanumeric or #closing_pairs_stack ~= 0 then
      add(char)
      -- if we had an alphanumeric, and the closing pairs stack *just* emptied,
      -- because the current character is a closing pair, we exit
      if has_alphanumeric and #closing_pairs_stack == 0 then break end
    else
      break
    end
  end
  return word
end

return get_prefix_before_brackets_and_quotes
