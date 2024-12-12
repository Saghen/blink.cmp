--- Displays a preview of the selected item on the current line
--- @class (exact) blink.cmp.CompletionGhostTextConfig
--- @field enabled boolean

local validate = require('blink.cmp.config.utils').validate
local ghost_text = {
  --- @type blink.cmp.CompletionGhostTextConfig
  default = {
    enabled = false,
  },
}

function ghost_text.validate(config)
  validate('completion.ghost_text', {
    enabled = { config.enabled, 'boolean' },
  }, config)
end

return ghost_text
