--- @class blink.cmp.KeymapConfig
--- @field show string | string[]
--- @field accept string | string[]
--- @field select_prev string | string[]
--- @field select_next string | string[]
--- @field show_documentation string | string[]
--- @field hide_documentation string | string[]
--- @field scroll_documentation_up string | string[]
--- @field scroll_documentation_down string | string[]
--- @field snippet_forward string | string[]
--- @field snippet_backward string | string[]

--- @class blink.cmp.TriggerConfig
--- @field context_regex string
--- @field blocked_trigger_characters string[]
--- @field show_on_insert_on_trigger_character boolean When true, will show the completion window when the cursor comes after a trigger character when entering insert mode

--- @class blink.cmp.SourceConfig
--- @field providers blink.cmp.SourceProviderConfig[][]
---
--- @class blink.cmp.SourceProviderConfig
--- @field [1] string
--- @field keyword_length number | nil
--- @field score_offset number | nil
--- @field deduplicate blink.cmp.DeduplicateConfig | nil
--- @field trigger_characters string[] | nil
--- @field opts table | nil
---
--- @class blink.cmp.DeduplicateConfig
--- @field enabled boolean
--- @field priority number

--- @class blink.cmp.FuzzyConfig
--- @field use_frecency boolean
--- @field use_proximity boolean
--- @field max_items number
--- @field sorts ("label" | "kind" | "score")[]

--- @class blink.cmp.WindowConfig
--- @field autocomplete blink.cmp.AutocompleteConfig
--- @field documentation blink.cmp.DocumentationConfig

--- @class blink.cmp.HighlightConfig
--- @field ns number
--- @field use_nvim_cmp_as_default boolean

--- @class blink.cmp.AutocompleteConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field order "top_down" | "bottom_up"
--- @field direction_priority ("n" | "s")[]
--- @field preselect boolean

--- @class blink.cmp.DocumentationDirectionPriorityConfig
--- @field autocomplete_north ("n" | "s" | "e" | "w")[]
--- @field autocomplete_south ("n" | "s" | "e" | "w")[]
---
--- @class blink.cmp.DocumentationConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field direction_priority blink.cmp.DocumentationDirectionPriorityConfig
--- @field auto_show boolean
--- @field debounce_ms number
--- @field delay_ms number

--- @class blink.cmp.CmpConfig
--- @field trigger blink.cmp.TriggerConfig
--- @field fuzzy blink.cmp.FuzzyConfig
--- @field sources blink.cmp.SourceConfig
--- @field windows blink.cmp.WindowConfig
--- @field highlight blink.cmp.HighlightConfig
--- @field kind_icons table<string, string>

--- @type blink.cmp.CmpConfig
local config = {
  keymap = {
    show = '<C-space>',
    hide = '<C-e>',
    accept = '<Tab>',
    select_prev = { '<Up>', '<C-j>' },
    select_next = { '<Down>', '<C-k>' },

    show_documentation = {},
    hide_documentation = {},
    scroll_documentation_up = '<C-b>',
    scroll_documentation_down = '<C-f>',

    snippet_forward = '<Tab>',
    snippet_backward = '<S-Tab>',
  },
  trigger = {
    context_regex = '[%w_\\-]',
    blocked_trigger_characters = { ' ', '\n', '\t' },
    show_on_insert_on_trigger_character = true,
  },
  fuzzy = {
    use_frecency = true,
    use_proximity = true,
    max_items = 200,
    sorts = { 'label', 'kind', 'score' },
  },
  sources = {
    providers = {
      {
        { 'blink.cmp.sources.lsp' },
        { 'blink.cmp.sources.path' },
        { 'blink.cmp.sources.snippets', score_offset = -3 },
      },
      { { 'blink.cmp.sources.buffer', score_offset = -9 } },
    },
  },
  windows = {
    autocomplete = {
      min_width = 30,
      max_width = 60,
      max_height = 10,
      order = 'top_down',
      direction_priority = { 'n', 's' },
      preselect = true,
    },
    documentation = {
      min_width = 10,
      max_width = 60,
      max_height = 20,
      direction_priority = {
        autocomplete_north = { 'e', 'w', 'n', 's' },
        autocomplete_south = { 'e', 'w', 's', 'n' },
      },
      auto_show = true,
      delay_ms = 0,
      debounce_ms = 100,
    },
  },

  highlight = {
    ns = vim.api.nvim_create_namespace('blink_cmp'),
    use_nvim_cmp_as_default = false,
  },
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
}

--- @class blink.cmp.CmpConfig
local M = {}

--- @param opts blink.cmp.CmpConfig
function M.merge_with(opts) config = vim.tbl_deep_extend('force', config, opts or {}) end

return setmetatable(M, { __index = function(_, k) return config[k] end })
