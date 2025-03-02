local keymap = {}

--- Lowercases all keys in the mappings table
--- @param existing_mappings table<string, blink.cmp.KeymapCommand[]>
--- @param new_mappings table<string, blink.cmp.KeymapCommand[]>
--- @return table<string, blink.cmp.KeymapCommand[]>
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

---@param keymap_config blink.cmp.KeymapConfig
function keymap.get_mappings(keymap_config)
  local mappings = vim.deepcopy(keymap_config)

  -- Handle preset
  if mappings.preset then
    local preset_keymap = require('blink.cmp.keymap.presets').get(mappings.preset)

    -- Remove 'preset' key from opts to prevent it from being treated as a keymap
    mappings.preset = nil

    -- Merge the preset keymap with the user-defined keymaps
    -- User-defined keymaps overwrite the preset keymaps
    mappings = keymap.merge_mappings(preset_keymap, mappings)
  end
  return mappings
end

function keymap.setup()
  local config = require('blink.cmp.config')
  local mappings = keymap.get_mappings(config.keymap)
  -- We set on the buffer directly to avoid buffer-local keymaps (such as from autopairs)
  -- from overriding our mappings. We also use InsertEnter to avoid conflicts with keymaps
  -- applied on other autocmds, such as LspAttach used by nvim-lspconfig and most configs
  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function()
      if not require('blink.cmp.config').enabled() then return end
      require('blink.cmp.keymap.apply').keymap_to_current_buffer(mappings)
    end,
  })

  -- This is not called when the plugin loads since it first checks if the binary is
  -- installed. As a result, when lazy-loaded on InsertEnter, the event may be missed
  if vim.api.nvim_get_mode().mode == 'i' and require('blink.cmp.config').enabled() then
    require('blink.cmp.keymap.apply').keymap_to_current_buffer(mappings)
  end

  -- Apply cmdline keymaps
  if config.cmdline.enabled then
    local cmdline_mappings =
      keymap.get_mappings(config.cmdline.keymap.preset == 'inherit' and config.keymap or config.cmdline.keymap)
    require('blink.cmp.keymap.apply').cmdline_keymaps(cmdline_mappings)
  end

  -- Apply term keymaps
  if config.term.enabled then
    local term_mappings =
      keymap.get_mappings(config.term.keymap.preset == 'inherit' and config.keymap or config.term.keymap)
    require('blink.cmp.keymap.apply').term_keymaps(term_mappings)
  end
end

return keymap
