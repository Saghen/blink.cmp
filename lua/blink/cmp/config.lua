--- @class KeymapConfig
--- @field show string | string[]
--- @field accept string | string[]
--- @field select_prev string | string[]
--- @field select_next string | string[]
--- @field snippet_forward string | string[]
--- @field snippet_backward string | string[]

--- @class TriggerConfig
--- @field context_regex string
--- @field blocked_trigger_characters string[]

--- @class SourceConfig
--- @field providers SourceProviderConfig[]
---
--- @class SourceProviderConfig
--- @field module string
--- @field keyword_length number | nil
--- @field score_offset number | nil
--- @field deduplicate DeduplicateConfig | nil
--- @field trigger_characters string[] | nil
--- @field opts table | nil
--- @field override table | nil
---
--- @class DeduplicateConfig
--- @field enabled boolean
--- @field priority number
---
--- @class SourceOverrideConfig
--- @field completions fun(context: ShowContext, callback: fun(items: CompletionItem[]), orig_fn: fun(context: ShowContext, callback: fun(items: CompletionItem[])))
--- @field resolve fun(orig_fn: fun(item: CompletionItem, callback: fun(resolved_item: CompletionItem | nil)), item: CompletionItem, callback: fun(resolved_item: CompletionItem | nil))

--- @class FuzzyConfig
--- @field use_frecency boolean
--- @field use_proximity boolean
--- @field max_items number
--- @field sorts ("label" | "kind" | "score")[]

--- @class WindowConfig
--- @field autocomplete AutocompleteConfig
--- @field documentation DocumentationConfig

--- @class AutocompleteConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field order "top_down" | "bottom_up"
--- @field direction_priority ("n" | "s")[]
--- @field preselect boolean

--- @class DocumentationDirectionPriorityConfig
--- @field autocomplete_north ("n" | "s" | "e" | "w")[]
--- @field autocomplete_south ("n" | "s" | "e" | "w")[]
---
--- @class DocumentationConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field direction_priority DocumentationDirectionPriorityConfig
--- @field auto_show boolean
--- @field debounce_ms number
--- @field delay_ms number

--- @class CmpConfig
--- @field trigger TriggerConfig
--- @field fuzzy FuzzyConfig
--- @field sources SourceConfig
--- @field windows WindowConfig
--- @field highlight_ns number
--- @field kind_icons table<string, string>

--- @type CmpConfig
local config = {
  keymap = {
    show = '<C-space>',
    hide = '<C-e>',
    accept = '<Tab>',
    select_prev = { '<Up>', '<C-j>' },
    select_next = { '<Down>', '<C-k>' },
    snippet_forward = '<Tab>',
    snippet_backward = '<S-Tab>',
  },
  trigger = {
    context_regex = '[%w_\\-]',
    blocked_trigger_characters = { ' ', '\n', '\t' },
  },
  fuzzy = {
    use_frecency = true,
    use_proximity = true,
    max_items = 200,
    sorts = { 'label', 'kind', 'score' },
  },
  sources = {
    providers = {
      { module = 'blink.cmp.sources.lsp' },
      { module = 'blink.cmp.sources.buffer' },
      { module = 'blink.cmp.sources.snippets' },
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
}

--- @class CmpConfig
local M = {}

--- @param opts CmpConfig
function M.merge_with(opts) config = vim.tbl_deep_extend('force', config, opts or {}) end

return setmetatable(M, { __index = function(_, k) return config[k] end })
