local apply = {}

local snippet_commands = { 'snippet_forward', 'snippet_backward' }

--- Applies the keymaps to the current buffer
--- @param keys_to_commands table<string, blink.cmp.KeymapCommand[]>
function apply.keymap_to_current_buffer(keys_to_commands)
  -- skip if we've already applied the keymaps
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, 'i')) do
    if mapping.desc == 'blink.cmp' then return end
  end

  -- insert mode: uses both snippet and insert commands
  for key, commands in pairs(keys_to_commands) do
    if #commands == 0 then goto continue end

    apply.set('i', key, function()
      for _, command in ipairs(commands) do
        -- special case for fallback
        if command == 'fallback' then
          return require('blink.cmp.keymap.fallback').run_non_blink_keymap('i', key)

        -- run user defined functions
        elseif type(command) == 'function' then
          if command(require('blink.cmp')) then return end

        -- otherwise, run the built-in command
        elseif require('blink.cmp')[command]() then
          return
        end
      end
    end)

    ::continue::
  end

  -- snippet mode
  for key, commands in pairs(keys_to_commands) do
    local has_snippet_command = false
    for _, command in ipairs(commands) do
      if vim.tbl_contains(snippet_commands, command) then has_snippet_command = true end
    end
    if not has_snippet_command or #commands == 0 then goto continue end

    apply.set('s', key, function()
      for _, command in ipairs(keys_to_commands[key] or {}) do
        -- special case for fallback
        if command == 'fallback' then
          return require('blink.cmp.keymap.fallback').run_non_blink_keymap('s', key)

          -- run user defined functions
        elseif type(command) == 'function' then
          if command(require('blink.cmp')) then return end

          -- only run snippet commands
        elseif vim.tbl_contains(snippet_commands, command) then
          local did_run = require('blink.cmp')[command]()
          if did_run then return end
        end
      end
    end)

    ::continue::
  end
end

--- @param mode string
--- @param key string
--- @param callback fun(): string | nil
function apply.set(mode, key, callback)
  vim.api.nvim_buf_set_keymap(0, mode, key, '', {
    callback = callback,
    expr = true,
    silent = true,
    noremap = true,
    replace_keycodes = false,
    desc = 'blink.cmp',
  })
end

return apply
