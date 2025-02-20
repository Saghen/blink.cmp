--- Displays a preview of the selected item on the current line
--- @class (exact) blink.cmp.CompletionGhostTextConfig
--- @field enabled boolean | fun(): boolean
--- @field show_with_selection boolean Show the ghost text when an item has been selected
--- @field show_without_selection boolean Show the ghost text when no item has been selected, defaulting to the first item
--- @field show_with_menu boolean Show the ghost text when the menu is open
--- @field show_without_menu boolean Show the ghost text when the menu is closed

local validate = require('blink.cmp.config.utils').validate
local ghost_text = {
  --- @type blink.cmp.CompletionGhostTextConfig
  default = {
    enabled = false,
    show_with_selection = true,
    show_without_selection = false,
    show_with_menu = true,
    show_without_menu = true,
  },
}

function ghost_text.validate(config)
  validate('completion.ghost_text', {
    enabled = { config.enabled, { 'boolean', 'function' } },
    show_with_selection = { config.show_with_selection, 'boolean' },
    show_without_selection = { config.show_without_selection, 'boolean' },
    show_without_menu = { config.show_without_menu, 'boolean' },
    show_with_menu = { config.show_with_menu, 'boolean' },
  }, config)
end

return ghost_text
