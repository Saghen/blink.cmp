local M = {}

M.default = {
  highlight_ns = vim.api.nvim_create_namespace('blink_cmp'),
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
  keymap = {
    ['<Tab>'] = 'accept',
    ['<C-j>'] = 'select_prev',
    ['<Down>'] = 'select_prev',
    ['<C-k>'] = 'select_next',
    ['<Up>'] = 'select_next',
    ['<C-space>'] = 'toggle',
  },
}

function M.setup(opts) M.config = vim.tbl_deep_extend('force', M.default, opts or {}) end

return setmetatable(M, { __index = function(_, k) return M.config[k] end })
