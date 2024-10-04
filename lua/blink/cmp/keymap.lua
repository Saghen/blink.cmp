local keymap = {}

local insert_commands = {
  'show',
  'hide',
  'accept',
  'select_prev',
  'select_next',
  'show_documentation',
  'hide_documentation',
  'scroll_documentation_up',
  'scroll_documentation_down',
}
local snippet_commands = { 'snippet_forward', 'snippet_backward' }

--- @param opts blink.cmp.KeymapConfig
function keymap.setup(opts)
  local insert_keys_to_commands = {}
  local snippet_keys_to_commands = {}
  for command, keys in pairs(opts) do
    local is_snippet_command = vim.tbl_contains(snippet_commands, command)
    local is_insert_command = vim.tbl_contains(insert_commands, command)
    if not is_snippet_command and not is_insert_command then error('Invalid command in keymap config: ' .. command) end

    -- convert string to string[] for consistency
    if type(keys) == 'string' then keys = { keys } end

    -- add keymaps
    for _, key in ipairs(keys) do
      if is_insert_command then
        if insert_keys_to_commands[key] == nil then insert_keys_to_commands[key] = {} end
        table.insert(insert_keys_to_commands[key], command)
      end
      if is_snippet_command then
        if snippet_keys_to_commands[key] == nil then snippet_keys_to_commands[key] = {} end
        table.insert(snippet_keys_to_commands[key], command)
      end
    end
  end

  for key, _ in pairs(insert_keys_to_commands) do
    vim.keymap.set('i', key, function()
      for _, command in ipairs(insert_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end
      for _, command in ipairs(snippet_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end
      return key
    end, { expr = true, silent = true })
  end
  for key, _ in pairs(snippet_keys_to_commands) do
    vim.keymap.set('s', key, function()
      for _, command in ipairs(snippet_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end
      return key
    end, { expr = true, silent = true })
  end
end

return keymap
