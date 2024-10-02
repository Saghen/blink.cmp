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
  local function handle_key(mode, key)
    local key_insert_commands = {}
    local key_snippet_commands = {}

    for command, keys in pairs(opts) do
      keys = type(keys) == 'string' and { keys } or keys
      if vim.tbl_contains(keys, key) then
        if vim.tbl_contains(snippet_commands, command) then
          table.insert(key_snippet_commands, command)
        elseif mode == 'i' and vim.tbl_contains(insert_commands, command) then
          table.insert(key_insert_commands, command)
        else
          error('Invalid command in keymap config: ' .. command)
        end
      end
    end

    for _, command in ipairs(key_insert_commands) do
      local did_run = require('blink.cmp')[command]()
      if did_run then return end
    end

    for _, command in ipairs(key_snippet_commands) do
      local did_run = require('blink.cmp')[command]()
      if did_run then return end
    end

    return key
  end

  local snippet_keys = {}
  local insert_keys = {}
  for command, keys in pairs(opts) do
    local is_snippet_command = vim.tbl_contains(snippet_commands, command)
    local is_insert_command = vim.tbl_contains(insert_commands, command)
    if not is_snippet_command and not is_insert_command then error('Invalid command in keymap config: ' .. command) end

    -- convert string to string[] for consistency
    if type(keys) == 'string' then keys = { keys } end

    -- add keymaps
    for _, key in ipairs(keys) do
      insert_keys[key] = true
      if is_snippet_command then snippet_keys[key] = true end
    end
  end

  for key, _ in pairs(insert_keys) do
    vim.keymap.set('i', key, function() return handle_key('i', key) end, { expr = true, silent = true })
  end
  for key, _ in pairs(snippet_keys) do
    vim.keymap.set('s', key, function() return handle_key('s', key) end, { expr = true, silent = true })
  end
end

return keymap
