--- @alias blink.cmp.KeymapCommand
--- | 'fallback' Fallback to the built-in behavior
--- | 'show' Show the completion window
--- | 'hide' Hide the completion window
--- | 'cancel' Cancel the current completion, undoing the preview from auto_insert
--- | 'accept' Accept the current completion item
--- | 'select_and_accept' Select the first completion item, if there's no selection, and accept
--- | 'select_prev' Select the previous completion item
--- | 'select_next' Select the next completion item
--- | 'show_documentation' Show the documentation window
--- | 'hide_documentation' Hide the documentation window
--- | 'scroll_documentation_up' Scroll the documentation window up
--- | 'scroll_documentation_down' Scroll the documentation window down
--- | 'snippet_forward' Move the cursor forward to the next snippet placeholder
--- | 'snippet_backward' Move the cursor backward to the previous snippet placeholder
--- | (fun(cmp: blink.cmp.API): boolean?) Custom function where returning true will prevent the next command from running

--- @alias blink.cmp.KeymapPreset
--- | 'none' No keymaps
--- Mappings similar to the built-in completion:
--- ```lua
--- {
---   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
---   ['<C-e>'] = { 'cancel', 'fallback' },
---   ['<C-y>'] = { 'select_and_accept' },
---
---   ['<C-p>'] = { 'select_prev', 'fallback' },
---   ['<C-n>'] = { 'select_next', 'fallback' },
---
---   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
---   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
---
---   ['<Tab>'] = { 'snippet_forward', 'fallback' },
---   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
--- }
--- ```
--- | 'default'
--- Mappings similar to VSCode.
--- You may want to set `completion.trigger.show_in_snippet = false` or use `completion.list.selection.preselect = function(ctx) return not require('blink.cmp').snippet_active({ direction = 1 }) end` when using this mapping:
--- ```lua
--- {
---   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
---   ['<C-e>'] = { 'cancel', 'fallback' },
---
---   ['<Tab>'] = {
---     function(cmp)
---       if cmp.snippet_active() then return cmp.accept()
---       else return cmp.select_and_accept() end
---     end,
---     'snippet_forward',
---     'fallback'
---   },
---   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
---
---   ['<Up>'] = { 'select_prev', 'fallback' },
---   ['<Down>'] = { 'select_next', 'fallback' },
---   ['<C-p>'] = { 'select_prev', 'fallback' },
---   ['<C-n>'] = { 'select_next', 'fallback' },
---
---   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
---   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
--- }
--- ```
--- | 'super-tab'
--- Similar to 'super-tab' but with `enter` to accept
--- You may want to set `completion.list.selection.preselect = false` when using this keymap:
--- ```lua
--- {
---   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
---   ['<C-e>'] = { 'cancel', 'fallback' },
---   ['<CR>'] = { 'accept', 'fallback' },
---
---   ['<Tab>'] = { 'snippet_forward', 'fallback' },
---   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
---
---   ['<Up>'] = { 'select_prev', 'fallback' },
---   ['<Down>'] = { 'select_next', 'fallback' },
---   ['<C-p>'] = { 'select_prev', 'fallback' },
---   ['<C-n>'] = { 'select_next', 'fallback' },
---
---   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
---   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
--- }
--- ```
--- | 'enter'

--- When specifying 'preset' in the keymap table, the custom key mappings are merged with the preset, and any conflicting keys will overwrite the preset mappings.
--- The "fallback" command will run the next non blink keymap.
---
--- Example:
---
--- ```lua
--- keymap = {
---   preset = 'default',
---   ['<Up>'] = { 'select_prev', 'fallback' },
---   ['<Down>'] = { 'select_next', 'fallback' },
---
---   -- disable a keymap from the preset
---   ['<C-e>'] = {},
---
---   -- optionally, define different keymaps for cmdline
---   cmdline = {
---     preset = 'cmdline',
---   }
--- }
--- ```
---
--- When defining your own keymaps without a preset, no keybinds will be assigned automatically.
--- @class (exact) blink.cmp.BaseKeymapConfig
--- @field preset? blink.cmp.KeymapPreset
--- @field [string] blink.cmp.KeymapCommand[] Table of keys => commands[]

--- @class (exact) blink.cmp.KeymapConfig : blink.cmp.BaseKeymapConfig
--- @field cmdline? blink.cmp.BaseKeymapConfig Optionally, define a separate keymap for cmdline

local keymap = {
  --- @type blink.cmp.KeymapConfig
  default = {
    preset = 'default',
  },
}

--- @param config blink.cmp.KeymapConfig
function keymap.validate(config)
  local commands = {
    'fallback',
    'show',
    'hide',
    'cancel',
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
  local presets = { 'default', 'super-tab', 'enter', 'none' }

  local validation_schema = {}
  for key, value in pairs(config) do
    -- nested cmdline keymap
    if key == 'cmdline' then
      keymap.validate(value)

    -- preset
    elseif key == 'preset' then
      validation_schema[key] = {
        value,
        function(preset) return vim.tbl_contains(presets, preset) end,
        'one of: ' .. table.concat(presets, ', '),
      }

    -- key
    else
      validation_schema[key] = {
        value,
        function(key_commands)
          for _, command in ipairs(key_commands) do
            if type(command) ~= 'function' and not vim.tbl_contains(commands, command) then return false end
          end
          return true
        end,
        'commands must be one of: ' .. table.concat(commands, ', '),
      }
    end
  end
  require('blink.cmp.config.utils')._validate(validation_schema)
end

return keymap
