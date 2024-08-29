local keymap = {}

local insert_commands = { 'show', 'hide', 'accept', 'select_prev', 'select_next' }
local snippet_commands = { 'snippet_forward', 'snippet_backward' }

--- @param opts KeymapConfig
function keymap.setup(opts)
  for command, keys in pairs(opts) do
    local is_snippet_command = vim.tbl_contains(snippet_commands, command)
    local is_insert_command = vim.tbl_contains(insert_commands, command)
    if not is_snippet_command and not is_insert_command then error('Invalid command in keymap config: ' .. command) end

    -- convert string to string[] for consistency
    if type(keys) == 'string' then keys = { keys } end

    -- add keymaps
    for _, key in ipairs(keys) do
      local mode = is_snippet_command and 's' or 'i'
      vim.keymap.set(mode, key, function()
        local did_run = require('blink.cmp')[command]()
        if not did_run then return key end
      end, { expr = true, silent = true })
    end
  end
end

return keymap
