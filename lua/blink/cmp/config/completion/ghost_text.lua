--- Displays a preview of the selected item on the current line
--- @class (exact) blink.cmp.CompletionGhostTextConfig
--- @field enabled boolean
--- @field show_on_unselected boolean

local validate = require('blink.cmp.config.utils').validate
local ghost_text = {
  --- @type blink.cmp.CompletionGhostTextConfig
  default = {
    enabled = false,
    show_on_unselected = false,
  },
}

function ghost_text.validate(config)
  validate('completion.ghost_text', {
    enabled = { config.enabled, 'boolean' },
    show_on_unselected = { config.show_on_unselected, 'boolean' },
  }, config)
end

return ghost_text
