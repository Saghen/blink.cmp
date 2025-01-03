local utils = {}

-- Code taken from @MariaSolOs in a indent-blankline.nvim PR:
-- https://github.com/lukas-reineke/indent-blankline.nvim/pull/934/files#diff-09ebcaa8c75cd1e92d25640e377ab261cfecaf8351c9689173fd36c2d0c23d94R16
-- According to https://github.com/neovim/neovim/pull/28977 it's ~ 39 000% faster

-- Use the faster validate version if available.
-- NOTE: We disable some Lua diagnostics here since lua_ls isn't smart enough to
-- realize that we're using an overloaded function.
---@param spec table<string, {[1]:any, [2]:function|string, [3]:string|true|nil}>
function utils.fastValidate(spec)
  if vim.fn.has "nvim-0.11" == 1 then
    for key, key_spec in pairs(spec) do
      local message = type(key_spec[3]) == "string" and key_spec[3] or nil --[[@as string?]]
      local optional = type(key_spec[3]) == "boolean" and key_spec[3] or nil --[[@as boolean?]]
      ---@diagnostic disable-next-line:param-type-mismatch, redundant-parameter
      vim.validate(key, key_spec[1], key_spec[2], optional, message)
      end
  else
    ---@diagnostic disable-next-line:param-type-mismatch
    vim.validate(spec)
  end
end

---@param path string The path to the field being validated
---@param tbl table The table to validate
---@param source table The original table that we're validating against
---@see vim.validate
function utils.validate(path, tbl, source)
  -- validate
  local _, err = pcall(utils.fastValidate, tbl)
  if err then error(path .. '.' .. err) end

  -- check for erroneous fields
  for k, _ in pairs(source) do
    if tbl[k] == nil then error(path .. '.' .. k .. ': unexpected field found in configuration') end
  end
end

return utils
