-- For single-key mappings, use vim.on_key, to avoid complex fallback logic and asynchronous commands
-- For multi-key mappings, we should either error, telling the user to set it themselves with vim.keymap.set,
-- or we can do the vim.keymap.set, but only if the implementation is simple

--- @class blink.cmp.KeymapOpts
--- @field bufnr? integer
--- @field fallback? boolean

local keymap = require('blink.cmp.lib.config').new_enable(true)

--- @param mode blink.cmp.Mode | blink.cmp.Mode[] | '*'
--- @param preset blink.cmp.KeymapPreset
--- @param filter? { bufnr?: integer }
function keymap.preset(mode, preset, filter)
  for key, commands in pairs(require('blink.cmp.keymap.presets').get(preset)) do
    -- TODO: think through this more. maybe drop the idea of `string[]` commands and just use functions?
    local has_fallback = vim.tbl_contains(commands, 'fallback')
    keymap.set(
      mode,
      key,
      vim.tbl_filter(function(command) return command ~= 'fallback' end, commands),
      { bufnr = filter and filter.bufnr, fallback = has_fallback }
    )
  end
end

--- @param mode blink.cmp.Mode | blink.cmp.Mode[] | '*'
--- @param key string
--- @param callback fun() | blink.cmp.KeymapCommand | blink.cmp.KeymapCommand[]
--- @param opts? blink.cmp.KeymapOpts
function keymap.set(mode, key, callback, opts) end

--- @param mode blink.cmp.Mode | blink.cmp.Mode[] | '*'
--- @param key string
--- @param opts? blink.cmp.KeymapOpts
function keymap.del(mode, key, opts) end

--- @param mode blink.cmp.Mode | blink.cmp.Mode[] | '*'
--- @param user_mappings table<string, blink.cmp.KeymapCommand[]> | false
--- @param preset? blink.cmp.KeymapPreset
function keymap.config(mode, user_mappings, preset) end

return keymap
