--- @class (exact) blink.cmp.CompletionTriggerConfig
--- @field enabled boolean
--- @field show_on_keyword boolean
--- @field show_in_snippet boolean
--- @field show_on_trigger_character boolean
--- @field show_on_blocked_trigger_characters string[]
--- @field show_on_accept_on_trigger_character boolean When true, will show the completion window when the cursor comes after a trigger character after accepting an item
--- @field show_on_insert_on_trigger_character boolean When true, will show the completion window when the cursor comes after a trigger character when entering insert mode
--- @field show_on_x_blocked_trigger_characters string[] List of trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item

local validate = require('blink.cmp.config.utils').validate
local trigger = {
  --- @type blink.cmp.CompletionTriggerConfig
  default = {
    enabled = true,
    show_on_keyword = true,
    show_in_snippet = true,
    show_on_trigger_character = true,
    show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
    show_on_accept_on_trigger_character = true,
    show_on_insert_on_trigger_character = true,
    show_on_x_blocked_trigger_characters = { ' ', '\n', '\t', "'", '"', '(' },
  },
}

function trigger.validate(config)
  validate('completion.trigger', {
    enabled = { config.enabled, 'boolean' },
    show_on_keyword = { config.show_on_keyword, 'boolean' },
    show_in_snippet = { config.show_in_snippet, 'boolean' },
    show_on_trigger_character = { config.show_on_trigger_character, 'boolean' },
    show_on_blocked_trigger_characters = { config.show_on_blocked_trigger_characters, 'table' },
    show_on_accept_on_trigger_character = { config.show_on_accept_on_trigger_character, 'boolean' },
    show_on_insert_on_trigger_character = { config.show_on_insert_on_trigger_character, 'boolean' },
    show_on_x_blocked_trigger_characters = { config.show_on_x_blocked_trigger_characters, 'table' },
  })
end

return trigger
