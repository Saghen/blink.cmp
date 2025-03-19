--- @class (exact) blink.cmp.CompletionDocumentationConfig
--- @field auto_show boolean Controls whether the documentation window will automatically show when selecting a completion item
--- @field auto_show_delay_ms number Delay before showing the documentation window
--- @field update_delay_ms number Delay before updating the documentation window when selecting a new item, while an existing item is still visible
--- @field treesitter_highlighting boolean Whether to use treesitter highlighting, disable if you run into performance issues
--- @field draw fun(opts: blink.cmp.CompletionDocumentationDrawOpts): nil Renders the item in the documentation window, by default using an internal treesitter based implementation
--- @field window blink.cmp.CompletionDocumentationWindowConfig

--- @class (exact) blink.cmp.CompletionDocumentationWindowConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field desired_min_width number
--- @field desired_min_height number
--- @field border blink.cmp.WindowBorder
--- @field winblend number
--- @field winhighlight string
--- @field scrollbar boolean Note that the gutter will be disabled when border ~= 'none'
--- @field direction_priority blink.cmp.CompletionDocumentationDirectionPriorityConfig Which directions to show the window, for each of the possible menu window directions, falling back to the next direction when there's not enough space

--- @class (exact) blink.cmp.CompletionDocumentationDirectionPriorityConfig
--- @field menu_north ("n" | "s" | "e" | "w")[]
--- @field menu_south ("n" | "s" | "e" | "w")[]

--- @class blink.cmp.CompletionDocumentationDrawOpts
--- @field item blink.cmp.CompletionItem
--- @field window blink.cmp.Window
--- @field config blink.cmp.CompletionDocumentationConfig
--- @field default_implementation fun(opts?: blink.cmp.RenderDetailAndDocumentationOptsPartial)

local validate = require('blink.cmp.config.utils').validate
local documentation = {
  --- @type blink.cmp.CompletionDocumentationConfig
  default = {
    auto_show = false,
    auto_show_delay_ms = 500,
    update_delay_ms = 50,
    treesitter_highlighting = true,
    draw = function(opts) opts.default_implementation() end,
    window = {
      min_width = 10,
      max_width = 80,
      max_height = 20,
      desired_min_width = 50,
      desired_min_height = 10,
      border = nil,
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
      scrollbar = true,
      direction_priority = {
        menu_north = { 'e', 'w', 'n', 's' },
        menu_south = { 'e', 'w', 's', 'n' },
      },
    },
  },
}

function documentation.validate(config)
  assert(
    config.update_delay_ms >= 50,
    'completion.documentation.update_delay_ms must be >= 50. Setting it lower will cause noticeable lag'
  )

  validate('completion.documentation', {
    auto_show = { config.auto_show, 'boolean' },
    auto_show_delay_ms = { config.auto_show_delay_ms, 'number' },
    update_delay_ms = { config.update_delay_ms, 'number' },
    treesitter_highlighting = { config.treesitter_highlighting, 'boolean' },
    draw = { config.draw, 'function' },
    window = { config.window, 'table' },
  }, config)

  validate('completion.documentation.window', {
    min_width = { config.window.min_width, 'number' },
    max_width = { config.window.max_width, 'number' },
    max_height = { config.window.max_height, 'number' },
    desired_min_width = { config.window.desired_min_width, 'number' },
    desired_min_height = { config.window.desired_min_height, 'number' },
    border = { config.window.border, { 'string', 'table' }, true },
    winblend = { config.window.winblend, 'number' },
    winhighlight = { config.window.winhighlight, 'string' },
    scrollbar = { config.window.scrollbar, 'boolean' },
    direction_priority = { config.window.direction_priority, 'table' },
  }, config.window)

  validate('completion.documentation.window.direction_priority', {
    menu_north = {
      config.window.direction_priority.menu_north,
      function(directions)
        if type(directions) ~= 'table' or #directions == 0 then return false end
        for _, direction in ipairs(directions) do
          if not vim.tbl_contains({ 'n', 's', 'e', 'w' }, direction) then return false end
        end
        return true
      end,
      'one of: "n", "s", "e", "w"',
    },
    menu_south = {
      config.window.direction_priority.menu_south,
      function(directions)
        if type(directions) ~= 'table' or #directions == 0 then return false end
        for _, direction in ipairs(directions) do
          if not vim.tbl_contains({ 'n', 's', 'e', 'w' }, direction) then return false end
        end
        return true
      end,
      'one of: "n", "s", "e", "w"',
    },
  }, config.window.direction_priority)
end

return documentation
