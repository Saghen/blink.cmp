--- @class (exact) blink.cmp.SignatureConfig
--- @field enabled boolean
--- @field trigger blink.cmp.SignatureTriggerConfig
--- @field window blink.cmp.SignatureWindowConfig

--- @class (exact) blink.cmp.SignatureTriggerConfig
--- @field blocked_trigger_characters string[]
--- @field blocked_retrigger_characters string[]
--- @field show_on_insert_on_trigger_character boolean When true, will show the signature help window when the cursor comes after a trigger character when entering insert mode

--- @class (exact) blink.cmp.SignatureWindowConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field border blink.cmp.WindowBorder
--- @field winblend number
--- @field winhighlight string
--- @field scrollbar boolean Note that the gutter will be disabled when border ~= 'none'
--- @field direction_priority ("n" | "s")[] Which directions to show the window, falling back to the next direction when there's not enough space, or another window is in the way.
--- @field treesitter_highlighting boolean Disable if you run into performance issues
--- @field show_documentation boolean

local validate = require('blink.cmp.config.utils').validate
local signature = {
  --- @type blink.cmp.SignatureConfig
  default = {
    enabled = false,
    trigger = {
      enabled = true,
      blocked_trigger_characters = {},
      blocked_retrigger_characters = {},
      show_on_insert_on_trigger_character = true,
    },
    window = {
      min_width = 1,
      max_width = 100,
      max_height = 10,
      border = 'padded',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
      scrollbar = false,
      direction_priority = { 'n', 's' },
      treesitter_highlighting = true,
      show_documentation = true,
    },
  },
}

function signature.validate(config)
  validate('signature', {
    enabled = { config.enabled, 'boolean' },
    trigger = { config.trigger, 'table' },
    window = { config.window, 'table' },
  }, config)
  validate('signature.trigger', {
    enabled = { config.trigger.enabled, 'boolean' },
    blocked_trigger_characters = { config.trigger.blocked_trigger_characters, 'table' },
    blocked_retrigger_characters = { config.trigger.blocked_retrigger_characters, 'table' },
    show_on_insert_on_trigger_character = { config.trigger.show_on_insert_on_trigger_character, 'boolean' },
  }, config.trigger)
  validate('signature.window', {
    min_width = { config.window.min_width, 'number' },
    max_width = { config.window.max_width, 'number' },
    max_height = { config.window.max_height, 'number' },
    border = { config.window.border, { 'string', 'table' } },
    winblend = { config.window.winblend, 'number' },
    winhighlight = { config.window.winhighlight, 'string' },
    scrollbar = { config.window.scrollbar, 'boolean' },
    direction_priority = { config.window.direction_priority, 'table' },
    treesitter_highlighting = { config.window.treesitter_highlighting, 'boolean' },
    show_documentation = { config.window.show_documentation, 'boolean' },
  }, config.window)
end

return signature
