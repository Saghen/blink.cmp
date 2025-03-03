local fallback = {}

--- Add missing types. Remove when fixed upstream
---@class blink.cmp.Fallback : vim.api.keyset.keymap
---@field lhs string
---@field mode string
---@field rhs? string
---@field lhsraw? string
---@field buffer? number

--- Gets the non blink.cmp global keymap for the given mode and key
--- @param mode string
--- @param key string
--- @return blink.cmp.Fallback | nil
function fallback.get_non_blink_global_mapping_for_key(mode, key)
  local normalized_key = vim.api.nvim_replace_termcodes(key, true, true, true)

  -- get global mappings
  local mappings = vim.api.nvim_get_keymap(mode)

  for _, mapping in ipairs(mappings) do
    --- @cast mapping blink.cmp.Fallback
    local mapping_key = vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true)
    if mapping_key == normalized_key and mapping.desc ~= 'blink.cmp' then return mapping end
  end
end

--- Gets the non blink.cmp buffer keymap for the given mode and key
--- @param mode string
--- @param key string
--- @return blink.cmp.Fallback?
function fallback.get_non_blink_buffer_mapping_for_key(mode, key)
  local normalized_key = vim.api.nvim_replace_termcodes(key, true, true, true)

  local buffer_mappings = vim.api.nvim_buf_get_keymap(0, mode)

  for _, mapping in ipairs(buffer_mappings) do
    --- @cast mapping blink.cmp.Fallback
    local mapping_key = vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true)
    if mapping_key == normalized_key and mapping.desc ~= 'blink.cmp' then return mapping end
  end
end

--- Returns a function that will run the first non blink.cmp keymap for the given mode and key
--- @param mode string
--- @param key string
--- @return fun(mappings_only?: boolean): string?
function fallback.wrap(mode, key)
  -- In default mode, there can't be multiple mappings on a single key for buffer local mappings
  -- In cmdline mode, there can't be multiple mappings on a single key for global mappings
  local buffer_mapping = mode ~= 'c' and fallback.get_non_blink_buffer_mapping_for_key(mode, key)
    or fallback.get_non_blink_global_mapping_for_key(mode, key)
  return function(mappings_only)
    local mapping = buffer_mapping or fallback.get_non_blink_global_mapping_for_key(mode, key)
    if mapping then return fallback.run_non_blink_keymap(mapping, key) end
    if not mappings_only then return vim.api.nvim_replace_termcodes(key, true, true, true) end
  end
end

--- Runs the first non blink.cmp keymap for the given mode and key
--- @param mapping blink.cmp.Fallback
--- @param key string
--- @return string | nil
function fallback.run_non_blink_keymap(mapping, key)
  -- TODO: there's likely many edge cases here. the nvim-cmp version is lacking documentation
  -- and is quite complex. we should look to see if we can simplify their logic
  -- https://github.com/hrsh7th/nvim-cmp/blob/ae644feb7b67bf1ce4260c231d1d4300b19c6f30/lua/cmp/utils/keymap.lua
  if type(mapping.callback) == 'function' then
    -- with expr = true, which we use, we can't modify the buffer without scheduling
    -- so if the keymap does not use expr, we must schedule it
    if mapping.expr ~= 1 then
      vim.schedule(mapping.callback)
      return
    end

    local expr = mapping.callback()
    if type(expr) == 'string' and mapping.replace_keycodes == 1 then
      expr = vim.api.nvim_replace_termcodes(expr, true, true, true)
    end
    return expr
  elseif mapping.rhs then
    local rhs = vim.api.nvim_replace_termcodes(mapping.rhs, true, true, true)
    if mapping.expr == 1 then rhs = vim.api.nvim_eval(rhs) end
    return rhs
  end

  -- pass the key along as usual
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end

return fallback
