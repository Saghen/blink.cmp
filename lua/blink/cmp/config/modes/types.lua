--- @class blink.cmp.ModeConfig
--- @field enabled? boolean
--- @field keymap blink.cmp.KeymapConfig
--- @field sources blink.cmp.SourceList
--- @field completion? blink.cmp.ModeCompletionConfig

--- @class blink.cmp.ModeCompletionConfig
--- @field trigger? blink.cmp.ModeCompletionTriggerConfig
--- @field list? blink.cmp.ModeCompletionListConfig
--- @field menu? blink.cmp.ModeCompletionMenuConfig
--- @field ghost_text? blink.cmp.ModeCompletionGhostTextConfig

--- @class blink.cmp.ModeCompletionListConfig
--- @field selection? blink.cmp.ModeCompletionListSelectionConfig

--- @class blink.cmp.ModeCompletionListSelectionConfig
--- @field preselect? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether to preselect the first item when the list is shown
--- @field auto_insert? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean When `true`, inserts the completion item automatically when selecting it

--- @class blink.cmp.ModeCompletionTriggerConfig
--- @field show_on_blocked_trigger_characters? string[] | (fun(): string[]) LSPs can indicate when to show the completion window via trigger characters. However, some LSPs (e.g. tsserver) return characters that would essentially always show the window. We block these by default.
--- @field show_on_x_blocked_trigger_characters? string[] | (fun(): string[]) List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item

--- @class blink.cmp.ModeCompletionMenuConfig
--- @field auto_show? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether to automatically show the window when new completion items are available
--- @field draw? blink.cmp.ModeDraw Controls how the completion items are rendered on the popup window

--- @class blink.cmp.ModeDraw
--- @field columns? blink.cmp.DrawColumnDefinition[] | fun(context: blink.cmp.Context): blink.cmp.DrawColumnDefinition[] Components to render, grouped by column

--- @class blink.cmp.ModeCompletionGhostTextConfig
--- @field enabled? boolean | fun(): boolean

local validate = require('blink.cmp.config.utils').validate
local mode = {}

--- @param config blink.cmp.ModeConfig
function mode.validate(prefix, config)
  validate(prefix, {
    enabled = { config.enabled, 'boolean' },
    keymap = { config.keymap, 'table', true },
    sources = { config.sources, { 'function', 'table' } },
    completion = { config.completion, 'table', true },
  }, config)

  require('blink.cmp.config.keymap').validate(config.keymap, true)

  if config.completion ~= nil then
    validate(prefix .. '.completion', {
      trigger = { config.completion.trigger, 'table', true },
      list = { config.completion.list, 'table', true },
      menu = { config.completion.menu, 'table', true },
      ghost_text = { config.completion.ghost_text, 'table', true },
    }, config.completion)

    if config.completion.trigger ~= nil then
      validate(prefix .. '.completion.trigger', {
        show_on_blocked_trigger_characters = {
          config.completion.trigger.show_on_blocked_trigger_characters,
          { 'function', 'table' },
          true,
        },
        show_on_x_blocked_trigger_characters = {
          config.completion.trigger.show_on_x_blocked_trigger_characters,
          { 'function', 'table' },
          true,
        },
      }, config.completion.trigger)
    end

    if config.completion.list ~= nil then
      validate(prefix .. '.completion.list', {
        selection = { config.completion.list.selection, 'table', true },
      }, config.completion.list)

      if config.completion.list.selection ~= nil then
        validate(prefix .. '.completion.list.selection', {
          preselect = { config.completion.list.selection.preselect, { 'boolean', 'function' }, true },
          auto_insert = { config.completion.list.selection.auto_insert, { 'boolean', 'function' }, true },
        }, config.completion.list.selection)
      end
    end

    if config.completion.menu ~= nil then
      validate(prefix .. '.completion.menu', {
        auto_show = { config.completion.menu.auto_show, { 'boolean', 'function' }, true },
        draw = { config.completion.menu.draw, 'table', true },
      }, config.completion.menu)

      if config.completion.menu.draw ~= nil then
        validate(prefix .. '.completion.menu.draw', {
          columns = { config.completion.menu.draw.columns, { 'function', 'table' }, true },
        }, config.completion.menu.draw)
      end
    end

    if config.completion.ghost_text ~= nil then
      validate(prefix .. '.completion.ghost_text', {
        enabled = { config.completion.ghost_text.enabled, { 'boolean', 'function' }, true },
      }, config.completion.ghost_text)
    end
  end
end

return mode
