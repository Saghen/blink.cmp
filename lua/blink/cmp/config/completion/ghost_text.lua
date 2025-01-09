--- Displays a preview of the selected item on the current line
--- @class (exact) blink.cmp.CompletionGhostTextConfig
--- @field enabled boolean
--- @field show_with_selection boolean Show the ghost text when an item has been selected
--- @field show_without_selection boolean Show the ghost text when no item has been selected, defaulting to the first item

local validate = require('blink.cmp.config.utils').validate
local ghost_text = {
  --- @type blink.cmp.CompletionGhostTextConfig
  default = {
    enabled = false,
    show_with_selection = true,
    show_without_selection = false,
  },
}

function ghost_text.validate(config)
  validate('completion.ghost_text', {
    enabled = { config.enabled, 'boolean' },
    show_with_selection = { config.show_with_selection, 'boolean' },
    show_without_selection = { config.show_without_selection, 'boolean' },
  }, config)
end

return ghost_text
