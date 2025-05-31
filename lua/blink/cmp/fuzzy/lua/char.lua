-- Taken from nvim-cmp
-- https://github.com/hrsh7th/nvim-cmp/blob/b5311ab3ed9c846b585c0c15b7559be131ec4be9/lua/cmp/utils/char.lua

local alpha = {}
string.gsub('abcdefghijklmnopqrstuvwxyz', '.', function(char) alpha[string.byte(char)] = true end)

local ALPHA = {}
string.gsub('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.', function(char) ALPHA[string.byte(char)] = true end)

local digit = {}
string.gsub('1234567890', '.', function(char) digit[string.byte(char)] = true end)

local white = {}
string.gsub(' \t\n', '.', function(char) white[string.byte(char)] = true end)

local char = {}

---@param byte integer
---@return boolean
function char.is_upper(byte) return ALPHA[byte] end

---@param byte integer
---@return boolean
function char.is_alpha(byte) return alpha[byte] or ALPHA[byte] end

---@param byte integer
---@return boolean
function char.is_digit(byte) return digit[byte] end

---@param byte integer
---@return boolean
function char.is_white(byte) return white[byte] end

---@param byte integer
---@return boolean
function char.is_symbol(byte) return not (char.is_alnum(byte) or char.is_white(byte)) end

---@param byte integer
---@return boolean
function char.is_alnum(byte) return char.is_alpha(byte) or char.is_digit(byte) end

---@param text string
---@param index integer
---@return boolean
function char.is_valid_word_boundary(text, index)
  if index <= 1 then return true end

  local prev = string.byte(text, index - 1)
  local curr = string.byte(text, index)

  if not char.is_upper(prev) and char.is_upper(curr) then return true end
  if char.is_symbol(curr) or char.is_white(curr) then return true end
  if not char.is_alpha(prev) and char.is_alpha(curr) then return true end
  if not char.is_digit(prev) and char.is_digit(curr) then return true end
  return false
end

return char
