--- @class blink.cmp.CmdlineConfig : blink.cmp.ModeConfig
--- @field sources blink.cmp.CmdlineSourceConfig

--- @class blink.cmp.CmdlineSourceConfig
--- @field per_cmdtype table<string, string[] | fun(): string[]>

local validate = require('blink.cmp.config.utils').validate
local cmdline = {
  --- @type blink.cmp.CmdlineConfig
  default = {
    enabled = true,
    sources = {
      per_cmdtype = {
        ['/'] = { 'buffer' },
        ['?'] = { 'buffer' },
        [':'] = { 'cmdline' },
        ['@'] = { 'cmdline' },
      },
    },
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

--- @param config blink.cmp.CmdlineConfig
function cmdline.validate(config)
  validate('cmdline', {
    enabled = { config.enabled, 'boolean' },
    keymap = { config.keymap, 'table', true },
    sources = { config.sources, 'table' },
    completion = { config.completion, 'table', true },
  }, config)

  if config.keymap ~= nil then require('blink.cmp.config.keymap').validate(config.keymap) end

  if config.sources ~= nil then
    validate('cmdline.sources', {
      per_cmdtype = { config.sources.per_cmdtype, 'table' },
    }, config.sources)
  end

  if config.completion ~= nil then
    validate('cmdline.completion', {
      trigger = { config.completion.trigger, 'table', true },
      menu = { config.completion.menu, 'table', true },
    }, config.completion)

    if config.completion.trigger ~= nil then
      validate('cmdline.completion.trigger', {
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

    if config.completion.menu ~= nil then
      validate('cmdline.completion.menu', {
        auto_show = { config.completion.menu.auto_show, { 'boolean', 'function' }, true },
        draw = { config.completion.menu.draw, 'table', true },
      }, config.completion.menu)

      if config.completion.menu.draw ~= nil then
        validate('cmdline.completion.menu.draw', {
          columns = { config.completion.menu.draw.columns, { 'function', 'table' }, true },
        }, config.completion.menu.draw)
      end
    end
  end
end

return cmdline
