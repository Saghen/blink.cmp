local keymap = {}

function keymap.setup()
  local mappings = vim.deepcopy(require('blink.cmp.config').keymap)

  -- Handle preset
  if mappings.preset then
    local preset_keymap = require('blink.cmp.keymap.presets').get(mappings.preset)

    -- Remove 'preset' key from opts to prevent it from being treated as a keymap
    mappings.preset = nil

    -- Merge the preset keymap with the user-defined keymaps
    -- User-defined keymaps overwrite the preset keymaps
    mappings = vim.tbl_extend('force', preset_keymap, mappings)
  end

  local snippet_commands = { 'snippet_forward', 'snippet_backward' }

  -- We listen to every key and return an empty string when blink handles the key,
  -- to tell neovim not to run the default keymaps
  -- TODO: handle multiple keys like <C-g><C-o>
  vim.on_key(function(original_key, key)
    if not require('blink.cmp.config').enabled() then return original_key end

    local mode = vim.api.nvim_get_mode().mode
    if mode ~= 'i' and mode ~= 's' then return original_key end

    for command_key, commands in pairs(mappings) do
      if vim.api.nvim_replace_termcodes(command_key, true, true, true) == key then
        for _, command in ipairs(commands) do
          -- ignore snippet commands for insert mode
          if vim.tbl_contains(snippet_commands, command) and mode == 'i' then goto continue end

          -- special case for fallback, return the key so that neovim continues like normal
          if command == 'fallback' then
            return original_key

          -- run user defined functions
          elseif type(command) == 'function' then
            if command(require('blink.cmp')) then return '' end

          -- otherwise, run the built-in command
          elseif require('blink.cmp')[command]() then
            return ''
          end

          ::continue::
        end
      end
    end

    return original_key
  end)
end

return keymap
