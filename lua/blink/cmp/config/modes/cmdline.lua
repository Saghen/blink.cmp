--- @class blink.cmp.CmdlineConfig : blink.cmp.ModeConfig

local cmdline = {
  --- @type blink.cmp.CmdlineConfig
  default = {
    enabled = true,
    keymap = { preset = 'cmdline' },
    sources = { 'buffer', 'cmdline' },
    completion = {
      trigger = { show_on_blocked_trigger_characters = {}, show_on_x_blocked_trigger_characters = {} },
      list = { selection = { preselect = true, auto_insert = true } },
      menu = { auto_show = function(ctx, _) return ctx.mode == 'cmdwin' end },
      ghost_text = { enabled = true },
    },
  },
}

--- @param config blink.cmp.CmdlineConfig
function cmdline.validate(config) require('blink.cmp.config.modes.types').validate('cmdline', config) end

return cmdline
