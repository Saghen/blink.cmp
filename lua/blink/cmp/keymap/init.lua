local keymap = {}

---@param keymap_config blink.cmp.BaseKeymapConfig
function keymap.get_mappings(keymap_config)
  local mappings = vim.deepcopy(keymap_config)

  -- Handle preset
  if mappings.preset then
    local preset_keymap = require('blink.cmp.keymap.presets').get(mappings.preset)

    -- Remove 'preset' key from opts to prevent it from being treated as a keymap
    mappings.preset = nil

    -- Merge the preset keymap with the user-defined keymaps
    -- User-defined keymaps overwrite the preset keymaps
    mappings = vim.tbl_extend('force', preset_keymap, mappings)
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

  -- Apply cmdline keymaps since they're global, if any sources are defined
  local cmdline_sources = require('blink.cmp.config').sources.cmdline
  if type(cmdline_sources) ~= 'table' or #cmdline_sources > 0 then
    local cmdline_mappings = keymap.get_mappings(config.keymap.cmdline or config.keymap)
    require('blink.cmp.keymap.apply').cmdline_keymaps(cmdline_mappings)
  end
end

return keymap
