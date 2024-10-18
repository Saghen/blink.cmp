local utils = require('blink.cmp.utils')
local keymap = {}

local insert_commands = {
  'show',
  'hide',
  'accept',
  'select_and_accept',
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

    -- reverse the command -> key[] mapping into key -> command[]
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

  -- we set on the buffer directly to avoid buffer-local keymaps (such as from autopairs)
  -- from overriding our mappings. We also use InsertEnter to avoid conflicts with keymaps
  -- applied on other autocmds, such as LspAttach used by nvim-lspconfig and most configs
  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function()
      if utils.is_blocked_buffer() then return end
      keymap.apply_keymap_to_current_buffer(insert_keys_to_commands, snippet_keys_to_commands)
    end,
  })
end

--- Applies the keymaps to the current buffer
--- @param insert_keys_to_commands table<string, string[]>
--- @param snippet_keys_to_commands table<string, string[]>
function keymap.apply_keymap_to_current_buffer(insert_keys_to_commands, snippet_keys_to_commands)
  -- skip if we've already applied the keymaps
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, 'i')) do
    if mapping.desc == 'blink.cmp' then return end
  end

  -- insert mode: uses both snippet and insert commands
  for _, key in ipairs(utils.union_keys(insert_keys_to_commands, snippet_keys_to_commands)) do
    keymap.set('i', key, function()
      for _, command in ipairs(insert_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end
      for _, command in ipairs(snippet_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end

      return keymap.run_non_blink_keymap('i', key)
    end)
  end

  -- snippet mode
  for key, _ in pairs(snippet_keys_to_commands) do
    keymap.set('s', key, function()
      for _, command in ipairs(snippet_keys_to_commands[key] or {}) do
        local did_run = require('blink.cmp')[command]()
        if did_run then return end
      end

      return keymap.run_non_blink_keymap('s', key)
    end)
  end
end

--- Gets the first non blink.cmp keymap for the given mode and key
--- @param mode string
--- @param key string
--- @return vim.api.keyset.keymap | nil
function keymap.get_non_blink_mapping_for_key(mode, key)
  local normalized_key = vim.api.nvim_replace_termcodes(key, true, true, true)

  -- get buffer local and global mappings
  local mappings = vim.api.nvim_buf_get_keymap(0, mode)
  vim.list_extend(mappings, vim.api.nvim_get_keymap(mode))

  for _, mapping in ipairs(mappings) do
    local mapping_key = vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true)
    if mapping_key == normalized_key and mapping.desc ~= 'blink.cmp' then return mapping end
  end
end

--- Runs the first non blink.cmp keymap for the given mode and key
--- @param mode string
--- @param key string
--- @return string | nil
function keymap.run_non_blink_keymap(mode, key)
  local mapping = keymap.get_non_blink_mapping_for_key(mode, key) or {}

  -- todo: there's likely many edge cases here. the nvim-cmp version is lacking documentation
  -- and is quite complex. we should look to see if we can simplify their logic
  -- https://github.com/hrsh7th/nvim-cmp/blob/ae644feb7b67bf1ce4260c231d1d4300b19c6f30/lua/cmp/utils/keymap.lua
  if type(mapping.callback) == 'function' then
    local expr = mapping.callback()
    if mapping.replace_keycodes == 1 then expr = vim.api.nvim_replace_termcodes(expr, true, true, true) end
    if mapping.expr == 1 then return expr end
    return
  elseif mapping.rhs then
    local rhs = vim.api.nvim_replace_termcodes(mapping.rhs, true, true, true)
    if mapping.expr == 1 then rhs = vim.api.nvim_eval(rhs) end
    return rhs
  end

  -- pass the key along as usual
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end

--- @param mode string
--- @param key string
--- @param callback fun(): string | nil
function keymap.set(mode, key, callback)
  vim.api.nvim_buf_set_keymap(0, mode, key, '', {
    callback = callback,
    expr = true,
    silent = true,
    noremap = true,
    replace_keycodes = false,
    desc = 'blink.cmp',
  })
end

return keymap
