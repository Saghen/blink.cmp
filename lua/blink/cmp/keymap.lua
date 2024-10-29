local utils = require('blink.cmp.utils')
local keymap = {}

local default_keymap = {
  ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  ['<C-e>'] = { 'hide' },
  ['<C-y>'] = { 'select_and_accept' },

  ['<Up>'] = { 'select_prev', 'fallback' },
  ['<Down>'] = { 'select_next', 'fallback' },
  ['<C-p>'] = { 'select_prev', 'fallback' },
  ['<C-n>'] = { 'select_next', 'fallback' },

  ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

  ['<Tab>'] = { 'snippet_forward', 'fallback' },
  ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
}

local super_tab_keymap = {
  ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  ['<C-e>'] = { 'hide' },

  ['<Tab>'] = {
    function(cmp)
      if cmp.is_in_snippet() then
        return cmp.accept()
      else
        return cmp.select_and_accept()
      end
    end,
    'snippet_forward',
    'fallback',
  },
  ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

  ['<Up>'] = { 'select_prev', 'fallback' },
  ['<Down>'] = { 'select_next', 'fallback' },
  ['<C-p>'] = { 'select_prev', 'fallback' },
  ['<C-n>'] = { 'select_next', 'fallback' },

  ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
}

local snippet_commands = { 'snippet_forward', 'snippet_backward' }

--- @param opts blink.cmp.KeymapConfig
function keymap.setup(opts)
  local mappings = opts

  -- notice for users on old config
  if type(opts) == 'table' then
    local commands = {
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
      'snippet_forward',
      'snippet_backward',
    }
    for key, _ in pairs(opts) do
      if vim.tbl_contains(commands, key) then
        error('The blink.cmp keymap recently got reworked. Please see the README for the updated configuration')
      end
    end
  end

  -- handle presets
  if type(opts) == 'string' then
    if opts == 'default' then
      mappings = default_keymap
    elseif opts == 'super-tab' then
      mappings = super_tab_keymap
    else
      error('Invalid blink.cmp keymap preset: ' .. opts)
    end
  end

  -- we set on the buffer directly to avoid buffer-local keymaps (such as from autopairs)
  -- from overriding our mappings. We also use InsertEnter to avoid conflicts with keymaps
  -- applied on other autocmds, such as LspAttach used by nvim-lspconfig and most configs
  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function()
      if utils.is_blocked_buffer() then return end
      keymap.apply_keymap_to_current_buffer(mappings)
    end,
  })
end

--- Applies the keymaps to the current buffer
--- @param keys_to_commands table<string, blink.cmp.KeymapCommand[]>
function keymap.apply_keymap_to_current_buffer(keys_to_commands)
  -- skip if we've already applied the keymaps
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, 'i')) do
    if mapping.desc == 'blink.cmp' then return end
  end

  -- insert mode: uses both snippet and insert commands
  for key, commands in pairs(keys_to_commands) do
    keymap.set('i', key, function()
      for _, command in ipairs(commands) do
        -- special case for fallback
        if command == 'fallback' then
          return keymap.run_non_blink_keymap('i', key)

        -- run user defined functions
        elseif type(command) == 'function' then
          if command(require('blink.cmp')) then return end

        -- otherwise, run the built-in command
        elseif require('blink.cmp')[command]() then
          return
        end
      end
    end)
  end

  -- snippet mode
  for key, commands in pairs(keys_to_commands) do
    local has_snippet_command = false
    for _, command in ipairs(commands) do
      if vim.tbl_contains(snippet_commands, command) then has_snippet_command = true end
    end

    if has_snippet_command then
      keymap.set('s', key, function()
        for _, command in ipairs(keys_to_commands[key] or {}) do
          -- special case for fallback
          if command == 'fallback' then
            return keymap.run_non_blink_keymap('s', key)

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
    end
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

  -- TODO: there's likely many edge cases here. the nvim-cmp version is lacking documentation
  -- and is quite complex. we should look to see if we can simplify their logic
  -- https://github.com/hrsh7th/nvim-cmp/blob/ae644feb7b67bf1ce4260c231d1d4300b19c6f30/lua/cmp/utils/keymap.lua
  if type(mapping.callback) == 'function' then
    -- with expr = true, which we use, we can't modify the buffer without scheduling
    -- so if the keymap does not use expr, we must schedule it
    if mapping.expr ~= 1 then
      vim.schedule(mapping.callback)
      return
    end

    local expr = mapping.callback()
    if mapping.replace_keycodes == 1 then expr = vim.api.nvim_replace_termcodes(expr, true, true, true) end
    return expr
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
