--- @class blink.cmp.TermConfig : blink.cmp.ModeConfig

local term = {
  --- @type blink.cmp.TermConfig
  default = {
    enabled = false,
    keymap = { preset = 'inherit' },
    sources = {},
    completion = {
      trigger = {
        show_on_blocked_trigger_characters = {},
      },
      menu = {
        draw = {
          columns = { { 'label', 'label_description', gap = 1 } },
        },
      },
    },
  },
}

--- @param config blink.cmp.TermConfig
function term.validate(config) require('blink.cmp.config.modes.types').validate('term', config) end

return term
