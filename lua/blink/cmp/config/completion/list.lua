--- @class (exact) blink.cmp.CompletionListConfig
--- @field max_items number Maximum number of items to display
--- @field selection blink.cmp.CompletionListSelectionConfig
--- @field cycle blink.cmp.CompletionListCycleConfig

--- @class (exact) blink.cmp.CompletionListSelectionConfig
--- @field preselect boolean | fun(ctx: blink.cmp.Context): boolean When `true`, will automatically select the first item in the completion list
--- @field auto_insert boolean | fun(ctx: blink.cmp.Context): boolean When `true`, inserts the completion item automatically when selecting it. You may want to bind a key to the `cancel` command (default <C-e>) when using this option, which will both undo the selection and hide the completion menu
--- @field auto_insert_blacklist? string[] List of mixed client_names and source_names that won't auto-insert when selected, even if `auto_insert` is `true`

--- @class (exact) blink.cmp.CompletionListCycleConfig
--- @field from_bottom boolean When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
--- @field from_top boolean When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.

local validate = require('blink.cmp.config.utils').validate
local list = {
  --- @type blink.cmp.CompletionListConfig
  default = {
    max_items = 200,
    selection = {
      preselect = true,
      auto_insert = true,
      auto_insert_blacklist = {},
    },
    cycle = {
      from_bottom = true,
      from_top = true,
    },
  },
}

function list.validate(config)
  if type(config.selection) == 'function' then
    error(
      '`completion.list.selection` has been replaced with `completion.list.selection.preselect` and `completion.list.selection.auto_insert`. See the docs for more info: https://cmp.saghen.dev/configuration/completion.html#list'
    )
  end

  validate('completion.list', {
    max_items = { config.max_items, 'number' },
    selection = { config.selection, 'table' },
    cycle = { config.cycle, 'table' },
  }, config)

  validate('completion.list.selection', {
    preselect = { config.selection.preselect, { 'boolean', 'function' } },
    auto_insert = { config.selection.auto_insert, { 'boolean', 'function' } },
    auto_insert_blacklist = { config.selection.auto_insert_blacklist, 'table' },
  }, config.selection)

  validate('completion.list.cycle', {
    from_bottom = { config.cycle.from_bottom, 'boolean' },
    from_top = { config.cycle.from_top, 'boolean' },
  }, config.cycle)
end

return list
