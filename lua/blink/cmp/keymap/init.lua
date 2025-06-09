local keymap = {}

--- Lowercases all keys in the mappings table
--- @param existing_mappings table<string, blink.cmp.KeymapCommand[] | false>
--- @param new_mappings table<string, blink.cmp.KeymapCommand[] | false>
--- @return table<string, blink.cmp.KeymapCommand[] | false>
function keymap.merge_mappings(existing_mappings, new_mappings)
  local merged_mappings = vim.deepcopy(existing_mappings)
  for new_key, new_mapping in pairs(new_mappings) do
    -- normalize the keys and replace, since naively merging would not handle <C-a> == <c-a>
    for existing_key, _ in pairs(existing_mappings) do
      if
        vim.api.nvim_replace_termcodes(existing_key, true, true, true)
        == vim.api.nvim_replace_termcodes(new_key, true, true, true)
      then
        merged_mappings[existing_key] = new_mapping
        goto continue
      end
    end

    -- key wasn't found, add it as per usual
    merged_mappings[new_key] = new_mapping

    ::continue::
  end
  return merged_mappings
end

--- @param keymap_config blink.cmp.KeymapConfig
--- @param mode blink.cmp.Mode
--- @return table<string, blink.cmp.KeymapCommand[]>
function keymap.get_mappings(keymap_config, mode)
  local mappings = vim.deepcopy(keymap_config)

  -- Remove unused keys, but keep keys set to false or empty tables (to disable them)
  if mode ~= 'default' then
    for key, commands in pairs(mappings) do
      if
        key ~= 'preset'
        and commands ~= false
        and #commands ~= 0
        and not require('blink.cmp.keymap.apply').has_insert_command(commands)
      then
        mappings[key] = nil
      end
    end
  end

  -- Handle preset
  if mappings.preset then
    local preset_keymap = require('blink.cmp.keymap.presets').get(mappings.preset)

    -- Remove 'preset' key from opts to prevent it from being treated as a keymap
    mappings.preset = nil

    -- Merge the preset keymap with the user-defined keymaps
    -- User-defined keymaps overwrite the preset keymaps
    mappings = keymap.merge_mappings(preset_keymap, mappings)
  end
  --- @cast mappings table<string, blink.cmp.KeymapCommand[] | false>

  -- Remove keys explicitly disabled by user (set to false or no commands)
  for key, commands in pairs(mappings) do
    if commands == false or #commands == 0 then mappings[key] = nil end
  end
  --- @cast mappings table<string, blink.cmp.KeymapCommand[]>

  return mappings
end

function keymap.setup()
  local config = require('blink.cmp.config')
  local apply = require('blink.cmp.keymap.apply')

  local mappings = keymap.get_mappings(config.keymap, 'default')

  -- We set on the buffer directly to avoid buffer-local keymaps (such as from autopairs)
  -- from overriding our mappings. We also use InsertEnter to avoid conflicts with keymaps
  -- applied on other autocmds, such as LspAttach used by nvim-lspconfig and most configs
  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function()
      if not require('blink.cmp.config').enabled() then return end
      apply.keymap_to_current_buffer(mappings)
    end,
  })

  -- This is not called when the plugin loads since it first checks if the binary is
  -- installed. As a result, when lazy-loaded on InsertEnter, the event may be missed
  if vim.api.nvim_get_mode().mode == 'i' and require('blink.cmp.config').enabled() then
    apply.keymap_to_current_buffer(mappings)
  end

  -- Apply cmdline and term keymaps
  for _, mode in ipairs({ 'cmdline', 'term' }) do
    local mode_config = config[mode]
    if mode_config.enabled then
      local mode_keymap = vim.deepcopy(mode_config.keymap)

      if mode_config.keymap.preset == 'inherit' then
        mode_keymap = vim.tbl_deep_extend('force', config.keymap, mode_config.keymap)
        mode_keymap.preset = config.keymap.preset
      end

      local mode_mappings = keymap.get_mappings(mode_keymap, mode)
      apply[mode .. '_keymaps'](mode_mappings)
    end
  end
end

return keymap
