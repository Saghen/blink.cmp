--- @class blink.cmp.CmdlineConfig : blink.cmp.ModeConfig

local cmdline = {
  --- @type blink.cmp.CmdlineConfig
  default = {
    enabled = true,
    keymap = { preset = 'cmdline' },
    sources = function()
      local type = vim.fn.getcmdtype()
      -- Search forward and backward
      if type == '/' or type == '?' then return { 'buffer' } end
      -- Commands
      if type == ':' or type == '@' then return { 'cmdline' } end
      return {}
    end,
    completion = {
      trigger = { show_on_blocked_trigger_characters = {}, show_on_x_blocked_trigger_characters = {} },
      list = { selection = { preselect = true, auto_insert = true } },
      menu = { auto_show = false },
      ghost_text = { enabled = true },
    },
  },
}

--- @param config blink.cmp.CmdlineConfig
function cmdline.validate(config) require('blink.cmp.config.modes.types').validate('cmdline', config) end

return cmdline
