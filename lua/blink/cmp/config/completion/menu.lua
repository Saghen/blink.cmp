--- @class (exact) blink.cmp.CompletionMenuConfig
--- @field enabled boolean
--- @field min_width number
--- @field max_height number
--- @field border blink.cmp.WindowBorder
--- @field scrollbar boolean Note that the gutter will be disabled when border ~= 'none'
--- @field order blink.cmp.CompletionMenuOrderConfig TODO: implement
--- @field direction_priority ("n" | "s")[] Which directions to show the window, falling back to the next direction when there's not enough space
--- @field winblend number
--- @field winhighlight string
--- @field scrolloff number Keep the cursor X lines away from the top/bottom of the window
--- @field draw blink.cmp.Draw Controls how the completion items are rendered on the popup window

--- @class (exact) blink.cmp.CompletionMenuOrderConfig
--- @field n 'top_down' | 'bottom_up'
--- @field s 'top_down' | 'bottom_up'

local validate = require('blink.cmp.config.utils').validate
local window = {
  --- @type blink.cmp.CompletionMenuConfig
  default = {
    enabled = true,
    min_width = 15,
    max_height = 10,
    border = 'none',
    winblend = 0,
    winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
    -- keep the cursor X lines away from the top/bottom of the window
    scrolloff = 2,
    -- note that the gutter will be disabled when border ~= 'none'
    scrollbar = true,
    -- which directions to show the window,
    -- falling back to the next direction when there's not enough space
    direction_priority = { 's', 'n' },
    -- which direction previous/next items show up
    -- TODO: implement
    order = { n = 'bottom_up', s = 'top_down' },

    -- Controls how the completion items are rendered on the popup window
    draw = {
      -- Aligns the keyword you've typed to a component in the menu
      align_to_component = 'label', -- or 'none' to disable
      -- Left and right padding, optionally { left, right } for different padding on each side
      padding = 1,
      -- Gap between columns
      gap = 1,
      treesitter = false, -- Use treesitter to highlight the label text
      -- Components to render, grouped by column
      columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
      -- Definitions for possible components to render. Each component defines:
      --   ellipsis: whether to add an ellipsis when truncating the text
      --   width: control the min, max and fill behavior of the component
      --   text function: will be called for each item
      --   highlight function: will be called only when the line appears on screen
      components = {
        kind_icon = {
          ellipsis = false,
          text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
          highlight = function(ctx)
            return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or ('BlinkCmpKind' .. ctx.kind)
          end,
        },

        kind = {
          ellipsis = false,
          width = { fill = true },
          text = function(ctx) return ctx.kind end,
          highlight = function(ctx)
            return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or ('BlinkCmpKind' .. ctx.kind)
          end,
        },

        label = {
          width = { fill = true, max = 60 },
          text = function(ctx) return ctx.label .. ctx.label_detail end,
          highlight = function(ctx)
            -- label and label details
            local label = ctx.label
            local highlights = {
              { 0, #label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
            }
            if ctx.label_detail then
              table.insert(highlights, { #label, #label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
            end

            if ctx.self.treesitter then
              -- add treesitter highlights
              vim.list_extend(highlights, require('blink.cmp.completion.windows.render.treesitter').highlight(ctx))
            end

            -- characters matched on the label by the fuzzy matcher
            for _, idx in ipairs(ctx.label_matched_indices) do
              table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
            end

            return highlights
          end,
        },

        label_description = {
          width = { max = 30 },
          text = function(ctx) return ctx.label_description end,
          highlight = 'BlinkCmpLabelDescription',
        },

        source_name = {
          width = { max = 30 },
          -- source_name or source_id are supported
          text = function(ctx) return ctx.source_name end,
          highlight = 'BlinkCmpSource',
        },
      },
    },
  },
}

function window.validate(config)
  validate('completion.window', {
    enabled = { config.enabled, 'boolean' },
    min_width = { config.min_width, 'number' },
    max_height = { config.max_height, 'number' },
    border = { config.border, { 'string', 'table' } },
    scrollbar = { config.scrollbar, 'boolean' },
    order = { config.order, 'table' },
    direction_priority = { config.direction_priority, 'table' },
    winblend = { config.winblend, 'number' },
    winhighlight = { config.winhighlight, 'string' },
    scrolloff = { config.scrolloff, 'number' },
    draw = { config.draw, 'table' },
  })
  validate('completion.window.order', {
    n = { config.order.n, { 'string', 'nil' } },
    s = { config.order.s, { 'string', 'nil' } },
  })
  validate('completion.window.direction_priority', {
    n = { config.direction_priority.n, { 'string', 'nil' } },
    s = { config.direction_priority.s, { 'string', 'nil' } },
  })

  validate('completion.window.draw', {
    align_to_component = {
      config.draw.align_to_component,
      function(align)
        if align == 'none' then return true end
        for _, column in ipairs(config.draw.columns) do
          for _, component in ipairs(column) do
            if component == align then return true end
          end
        end
        return false
      end,
      '"none" or one of the components defined in the "columns"',
    },
    padding = {
      config.draw.padding,
      function(padding)
        if type(padding) == 'number' then return true end
        if type(padding) ~= 'table' or #padding ~= 2 then return false end
        if type(padding[1]) == 'number' and type(padding[2]) == 'number' then return true end
        return false
      end,
      'a number or a tuple of 2 numbers (i.e. [1, 2])',
    },
    gap = { config.draw.gap, 'number' },
    columns = {
      config.draw.columns,
      function(columns)
        local available_components = vim.tbl_keys(config.draw.components)

        if type(columns) ~= 'table' or #columns == 0 then return false end
        for _, column in ipairs(columns) do
          if #column == 0 then return false end
          for _, component in ipairs(column) do
            if not vim.tbl_contains(available_components, component) then return false end
          end
          if column.gap ~= nil and type(column.gap) ~= 'number' then return false end
        end
        return true
      end,
      'a table of tables, where each table contains a list of components and an optional gap. List of available components: '
        .. table.concat(vim.tbl_keys(config.draw.components), ', '),
    },
    components = { config.draw.components, 'table' },
  })

  for component, definition in pairs(config.draw.components) do
    validate('completion.window.draw.components.' .. component, {
      ellipsis = { definition.ellipsis, 'boolean', true },
      width = { definition.width, 'table', true },
      text = { definition.text, 'function' },
      highlight = { definition.highlight, { 'string', 'function' }, true },
    })
  end
end

return window
