local utils = {}

---@param path string The path to the field being validated
---@param tbl table The table to validate
---@param source table The original table that we're validating against
---@see vim.validate
function utils.validate(path, tbl, source)
  -- validate
  local _, err = pcall(vim.validate, tbl)
  if err then error(path .. '.' .. err) end

  -- check for erroneous fields
  for k, _ in pairs(source) do
    if tbl[k] == nil then error(path .. '.' .. k .. ': unexpected field found in configuration') end
  end
end

return utils
