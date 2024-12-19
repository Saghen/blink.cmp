--- @class (exact) blink.cmp.CompletionListConfig
--- @field max_items number Maximum number of items to display
--- @field selection blink.cmp.CompletionListSelection Controls if completion items will be selected automatically, and whether selection automatically inserts
--- @field cycle blink.cmp.CompletionListCycleConfig

--- @alias blink.cmp.CompletionListSelection
--- | 'preselect' Select the first item in the completion list
--- | 'manual' Don't select any item by default
--- | 'auto_insert' Don't select any item by default, and insert the completion items automatically when selecting them. You may want to bind a key to the `cancel` command when using this option, which will undo the selection and hide the completion menu

--- @class (exact) blink.cmp.CompletionListCycleConfig
--- @field from_bottom boolean When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
--- @field from_top boolean When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.

local validate = require('blink.cmp.config.utils').validate
local list = {
  --- @type blink.cmp.CompletionListConfig
  default = {
    max_items = 200,
    selection = 'preselect',
    cycle = {
      from_bottom = true,
      from_top = true,
    },
  },
}

function list.validate(config)
  validate('completion.list', {
    max_items = { config.max_items, 'number' },
    selection = {
      config.selection,
      function() return vim.tbl_contains({ 'preselect', 'manual', 'auto_insert' }, config.selection) end,
      'one of: preselect, manual, auto_insert',
    },
    cycle = { config.cycle, 'table' },
  }, config)

  validate('completion.list.cycle', {
    from_bottom = { config.cycle.from_bottom, 'boolean' },
    from_top = { config.cycle.from_top, 'boolean' },
  }, config.cycle)
end

return list
