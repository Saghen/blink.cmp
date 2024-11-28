--- @class (exact) blink.cmp.CompletionTriggerConfig
--- @field show_in_snippet boolean When false, will not show the completion window when in a snippet
--- @field show_on_keyword boolean When true, will show the completion window after typing a character that matches the `keyword.regex`
--- @field show_on_trigger_character boolean When true, will show the completion window after typing a trigger character
--- @field show_on_blocked_trigger_characters string[] LSPs can indicate when to show the completion window via trigger characters. However, some LSPs (i.e. tsserver) return characters that would essentially always show the window. We block these by default.
--- @field show_on_accept_on_trigger_character boolean When both this and show_on_trigger_character are true, will show the completion window when the cursor comes after a trigger character after accepting an item
--- @field show_on_insert_on_trigger_character boolean When both this and show_on_trigger_character are true, will show the completion window when the cursor comes after a trigger character when entering insert mode
--- @field show_on_x_blocked_trigger_characters string[] List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item

local validate = require('blink.cmp.config.utils').validate
local trigger = {
  --- @type blink.cmp.CompletionTriggerConfig
  default = {
    show_in_snippet = true,
    show_on_keyword = true,
    show_on_trigger_character = true,
    show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
    show_on_accept_on_trigger_character = true,
    show_on_insert_on_trigger_character = true,
    show_on_x_blocked_trigger_characters = { "'", '"', '(' },
  },
}

function trigger.validate(config)
  validate('completion.trigger', {
    show_in_snippet = { config.show_in_snippet, 'boolean' },
    show_on_keyword = { config.show_on_keyword, 'boolean' },
    show_on_trigger_character = { config.show_on_trigger_character, 'boolean' },
    show_on_blocked_trigger_characters = { config.show_on_blocked_trigger_characters, 'table' },
    show_on_accept_on_trigger_character = { config.show_on_accept_on_trigger_character, 'boolean' },
    show_on_insert_on_trigger_character = { config.show_on_insert_on_trigger_character, 'boolean' },
    show_on_x_blocked_trigger_characters = { config.show_on_x_blocked_trigger_characters, 'table' },
  })
end

return trigger
