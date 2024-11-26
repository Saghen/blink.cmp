--- @class (exact) blink.cmp.AppearanceConfig
--- @field highlight_ns number
--- @field nerd_font_variant 'mono' | 'normal'
--- @field kind_icons table<string, string>

local validate = require('blink.cmp.config.utils').validate
local appearance = {
  --- @type blink.cmp.AppearanceConfig
  default = {
    highlight_ns = vim.api.nvim_create_namespace('blink_cmp'),
    nerd_font_variant = 'mono',
    kind_icons = {
      Text = '󰉿',
      Method = '󰊕',
      Function = '󰊕',
      Constructor = '󰒓',

      Field = '󰜢',
      Variable = '󰆦',
      Property = '󰖷',

      Class = '󱡠',
      Interface = '󱡠',
      Struct = '󱡠',
      Module = '󰅩',

      Unit = '󰪚',
      Value = '󰦨',
      Enum = '󰦨',
      EnumMember = '󰦨',

      Keyword = '󰻾',
      Constant = '󰏿',

      Snippet = '󱄽',
      Color = '󰏘',
      File = '󰈔',
      Reference = '󰬲',
      Folder = '󰉋',
      Event = '󱐋',
      Operator = '󰪚',
      TypeParameter = '󰬛',
    },
  },
}

function appearance.validate(config)
  validate('appearance', {
    highlight_ns = { config.highlight_ns, 'number' },
    nerd_font_variant = { config.nerd_font_variant, 'string' },
    kind_icons = { config.kind_icons, 'table' },
  })
end

return appearance
