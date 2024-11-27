local utils = {}

---@param path string The path to the field being validated
---@param tbl table The table to validate
---@see vim.validate
---@return boolean is_valid
---@return string|nil error_message
function utils.validate(path, tbl)
  local _, err = pcall(vim.validate, tbl)
  if err then error(path .. '.' .. err) end
end

return utils
