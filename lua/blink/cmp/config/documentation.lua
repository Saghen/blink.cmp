--- @class (exact) blink.cmp.DocumentationConfig
--- @field trigger blink.cmp.DocumentationTriggerConfig
--- @field window blink.cmp.DocumentationWindowConfig

--- @class (exact) blink.cmp.DocumentationTriggerConfig
--- @field auto_show boolean
--- @field auto_show_delay_ms number Delay before showing the documentation window
--- @field update_delay_ms number Delay before updating the documentation window

--- @class (exact) blink.cmp.DocumentationWindowConfig
--- @field min_width? number
--- @field max_width? number
--- @field max_height? number
--- @field desired_min_width? number
--- @field desired_min_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrollbar? boolean
--- @field direction_priority? blink.cmp.DocumentationDirectionPriorityConfig
--- @field treesitter_highlighting? boolean Whether to use treesitter highlighting, disable if you run into performance issues

--- @class (exact) blink.cmp.DocumentationDirectionPriorityConfig
--- @field autocomplete_north? ("n" | "s" | "e" | "w")[]
--- @field autocomplete_south? ("n" | "s" | "e" | "w")[]

local validate = require('blink.cmp.config.utils').validate
local documentation = {
  --- @type blink.cmp.DocumentationConfig
  default = {
    trigger = {
      auto_show = false,
      auto_show_delay_ms = 500,
      update_delay_ms = 50,
    },
    window = {
      min_width = 10,
      max_width = 60,
      max_height = 20,
      border = 'padded',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder',
      scrollbar = true,
      direction_priority = {
        autocomplete_north = { 'e', 'w', 'n', 's' },
        autocomplete_south = { 'e', 'w', 's', 'n' },
      },
    },
  },
}

function documentation.validate(config)
  validate('documentation', {
    trigger = { config.trigger, 'table' },
    window = { config.window, 'table' },
  })
  validate('documentation.trigger', {
    auto_show = { config.trigger.auto_show, 'boolean' },
    auto_show_delay_ms = { config.trigger.auto_show_delay_ms, 'number' },
    update_delay_ms = { config.trigger.update_delay_ms, 'number' },
  })
  validate('documentation.window', {
    min_width = { config.window.min_width, 'number' },
    max_width = { config.window.max_width, 'number' },
    max_height = { config.window.max_height, 'number' },
    border = { config.window.border, 'string' },
    winblend = { config.window.winblend, 'number' },
    winhighlight = { config.window.winhighlight, 'string' },
    scrollbar = { config.window.scrollbar, 'boolean' },
    direction_priority = { config.window.direction_priority, 'table' },
  })
end

return documentation
