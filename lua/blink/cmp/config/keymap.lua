--- @alias blink.cmp.KeymapCommand
--- | 'fallback' Fallback to the built-in behavior
--- | 'show' Show the completion window
--- | 'hide' Hide the completion window
--- | 'cancel' Cancel the current completion, undoing the preview from auto_insert
--- | 'accept' Accept the current completion item
--- | 'select_and_accept' Select the current completion item and accept it
--- | 'select_prev' Select the previous completion item
--- | 'select_next' Select the next completion item
--- | 'show_documentation' Show the documentation window
--- | 'hide_documentation' Hide the documentation window
--- | 'scroll_documentation_up' Scroll the documentation window up
--- | 'scroll_documentation_down' Scroll the documentation window down
--- | 'snippet_forward' Move the cursor forward to the next snippet placeholder
--- | 'snippet_backward' Move the cursor backward to the previous snippet placeholder
--- | (fun(cmp: table): boolean?) Custom function where returning true will prevent the next command from running

--- @alias blink.cmp.KeymapPreset
--- | 'default' mappings similar to built-in completion
--- | 'super-tab' mappings similar to vscode (tab to accept, arrow keys to navigate)
--- | 'enter' mappings similar to 'super-tab' but with 'enter' to accept

--- @class (exact) blink.cmp.KeymapConfig
--- @field preset? blink.cmp.KeymapPreset
--- @field [string] blink.cmp.KeymapCommand[]> Table of keys => commands[]

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
  local presets = { 'default', 'super-tab', 'enter' }

  vim.validate({ preset = {} })
  local validation_schema = {}
  for key, command_or_preset in pairs(config) do
    if key == 'preset' then
      validation_schema[key] = {
        command_or_preset,
        function(preset) return vim.tbl_contains(presets, preset) end,
        '"preset" must be one of: ' .. table.concat(presets, ', '),
      }
    else
      validation_schema[key] = {
        command_or_preset,
        function(command) return vim.tbl_contains(commands, command) end,
        '"' .. key .. '" must be one of: ' .. table.concat(commands, ', '),
      }
    end
  end
  vim.validate(validation_schema)
end

return keymap
