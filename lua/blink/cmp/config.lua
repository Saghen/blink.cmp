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

--- @class blink.cmp.AcceptConfig
--- @field create_undo_point boolean Create an undo point when accepting a completion item
--- @field auto_brackets blink.cmp.AutoBracketsConfig

--- @class blink.cmp.AutoBracketsConfig
--- @field enabled boolean
--- @field default_brackets string[]
--- @field override_brackets_for_filetypes table<string, string[] | function(item: blink.cmp.CompletionItem): string[]>
--- @field force_allow_filetypes string[] Overrides the default blocked filetypes
--- @field blocked_filetypes string[]
--- @field kind_resolution blink.cmp.AutoBracketResolutionConfig Synchronously use the kind of the item to determine if brackets should be added
--- @field semantic_token_resolution blink.cmp.AutoBracketSemanticTokenResolutionConfig Asynchronously use semantic token to determine if brackets should be added

--- @class blink.cmp.AutoBracketResolutionConfig
--- @field enabled boolean
--- @field blocked_filetypes string[]
---
--- @class blink.cmp.AutoBracketSemanticTokenResolutionConfig : blink.cmp.AutoBracketResolutionConfig
--- @field timeout_ms number How long to wait for semantic tokens to return before assuming no brackets should be added

--- @class blink.cmp.CompletionTriggerConfig
--- @field keyword_regex string
--- @field blocked_trigger_characters string[]
--- @field show_on_insert_on_trigger_character boolean When true, will show the completion window when the cursor comes after a trigger character when entering insert mode
--- @field show_on_insert_blocked_trigger_characters string[] List of additional trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode
---
--- @class blink.cmp.SignatureHelpTriggerConfig
--- @field enabled boolean
--- @field blocked_trigger_characters string[]
--- @field blocked_retrigger_characters string[]
--- @field show_on_insert_on_trigger_character boolean When true, will show the signature help window when the cursor comes after a trigger character when entering insert mode
---
--- @class blink.cmp.TriggerConfig
--- @field completion blink.cmp.CompletionTriggerConfig
--- @field signature_help blink.cmp.SignatureHelpTriggerConfig

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

--- @class blink.cmp.PrebuiltBinariesConfig
--- @field download boolean
--- @field forceVersion string | nil

--- @class blink.cmp.FuzzyConfig
--- @field use_frecency boolean
--- @field use_proximity boolean
--- @field max_items number
--- @field sorts ("label" | "kind" | "score")[]
--- @field prebuiltBinaries blink.cmp.PrebuiltBinariesConfig

--- @class blink.cmp.WindowConfig
--- @field autocomplete blink.cmp.AutocompleteConfig
--- @field documentation blink.cmp.DocumentationConfig
--- @field signature_help blink.cmp.SignatureHelpConfig

--- @class blink.cmp.HighlightConfig
--- @field ns number
--- @field use_nvim_cmp_as_default boolean

--- @class blink.cmp.AutocompleteConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field border blink.cmp.WindowBorder
--- @field order "top_down" | "bottom_up"
--- @field direction_priority ("n" | "s")[]
--- @field preselect boolean
--- @field winhighlight string
--- @field scrolloff number
--- @field draw 'simple' | 'reversed' | function(blink.cmp.CompletionRenderContext): blink.cmp.Component[]
--- @field cycle blink.cmp.AutocompleteConfig.CycleConfig

--- @class blink.cmp.AutocompleteConfig.CycleConfig
--- @field from_bottom boolean When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
--- @field from_top boolean When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.

--- @class blink.cmp.DocumentationDirectionPriorityConfig
--- @field autocomplete_north ("n" | "s" | "e" | "w")[]
--- @field autocomplete_south ("n" | "s" | "e" | "w")[]
---
--- @alias blink.cmp.WindowBorder 'single' | 'double' | 'rounded' | 'solid' | 'shadow' | 'padded' | 'none' | string[]
---
--- @class blink.cmp.DocumentationConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field border blink.cmp.WindowBorder
--- @field direction_priority blink.cmp.DocumentationDirectionPriorityConfig
--- @field auto_show boolean
--- @field auto_show_delay_ms number Delay before showing the documentation window
--- @field update_delay_ms number Delay before updating the documentation window
--- @field winhighlight string

--- @class blink.cmp.SignatureHelpConfig
--- @field min_width number
--- @field max_width number
--- @field max_height number
--- @field border blink.cmp.WindowBorder
--- @field winhighlight string

--- @class blink.cmp.Config
--- @field keymap blink.cmp.KeymapConfig
--- @field accept blink.cmp.AcceptConfig
--- @field trigger blink.cmp.TriggerConfig
--- @field fuzzy blink.cmp.FuzzyConfig
--- @field sources blink.cmp.SourceConfig
--- @field windows blink.cmp.WindowConfig
--- @field highlight blink.cmp.HighlightConfig
--- @field nerd_font_variant 'mono' | 'normal'
--- @field kind_icons table<string, string>

--- @type blink.cmp.Config
local config = {
  -- for keymap, all values may be string | string[]
  -- use an empty table to disable a keymap
  keymap = {
    show = '<C-space>',
    hide = '<C-e>',
    accept = '<Tab>',
    select_prev = { '<Up>', '<C-k>' },
    select_next = { '<Down>', '<C-j>' },

    show_documentation = {},
    hide_documentation = {},
    scroll_documentation_up = '<C-b>',
    scroll_documentation_down = '<C-f>',

    snippet_forward = '<Tab>',
    snippet_backward = '<S-Tab>',
  },

  accept = {
    create_undo_point = true,
    auto_brackets = {
      enabled = false,
      default_brackets = { '(', ')' },
      override_brackets_for_filetypes = {},
      force_allow_filetypes = {},
      blocked_filetypes = {},
      kind_resolution = {
        enabled = true,
        blocked_filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'vue' },
      },
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = {},
        timeout_ms = 400,
      },
    },
  },

  trigger = {
    completion = {
      -- regex used to get the text when fuzzy matching
      -- changing this may break some sources, so please report if you run into issues
      -- todo: shouldnt this also affect the accept command? should this also be per language?
      keyword_regex = '[%w_\\-]',
      -- LSPs can indicate when to show the completion window via trigger characters
      -- however, some LSPs (*cough* tsserver *cough*) return characters that would essentially
      -- always show the window. We block these by default
      blocked_trigger_characters = { ' ', '\n', '\t' },
      -- when true, will show the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
      -- list of additional trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_blocked_trigger_characters = { "'", '"' },
    },

    signature_help = {
      enabled = false,
      blocked_trigger_characters = {},
      blocked_retrigger_characters = {},
      -- when true, will show the signature help window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
    },
  },

  fuzzy = {
    -- frencency tracks the most recently/frequently used items and boosts the score of the item
    use_frecency = true,
    -- proximity bonus boosts the score of items with a value in the buffer
    use_proximity = true,
    max_items = 200,
    -- controls which sorts to use and in which order, these three are currently the only allowed options
    sorts = { 'label', 'kind', 'score' },
    prebuiltBinaries = {
      -- Whether or not to automatically download a prebuilt binary from github. If this is set to `false`
      -- you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
      download = true,
      -- When downloading a prebuilt binary force the downloader to resolve this version. If this is uset
      -- then the downloader will attempt to infer the version from the checked out git tag (if any).
      --
      -- Beware that if the FFI ABI changes while tracking main then this may result in blink breaking.
      forceVersion = nil,
    },
  },

  sources = {
    -- similar to nvim-cmp's sources, but we point directly to the source's lua module
    -- multiple groups can be provided, where it'll fallback to the next group if the previous
    -- returns no completion items
    providers = {
      {
        { 'blink.cmp.sources.lsp' },
        { 'blink.cmp.sources.path' },
        { 'blink.cmp.sources.snippets', score_offset = -2 },
      },
      { { 'blink.cmp.sources.buffer' } },
    },
  },

  windows = {
    autocomplete = {
      min_width = 30,
      max_width = 60,
      max_height = 10,
      border = 'none',
      winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
      -- keep the cursor X lines away from the top/bottom of the window
      scrolloff = 2,
      -- todo: implement
      order = 'top_down',
      -- which directions to show the window,
      -- falling back to the next direction when there's not enough space
      direction_priority = { 's', 'n' },
      -- todo: implement
      preselect = true,
      -- Controls how the completion items are rendered on the popup window
      -- 'simple' will render the item's kind icon the left alongside the label
      -- 'reversed' will render the label on the left and the kind icon + name on the right
      -- 'function(blink.cmp.CompletionRenderContext): blink.cmp.Component[]' for custom rendering
      draw = 'simple',
      cycle = {
        from_bottom = true,
        from_top = true,
      },
    },
    documentation = {
      min_width = 10,
      max_width = 60,
      max_height = 20,
      border = 'padded',
      winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
      -- which directions to show the documentation window,
      -- for each of the possible autocomplete window directions,
      -- falling back to the next direction when there's not enough space
      direction_priority = {
        autocomplete_north = { 'e', 'w', 'n', 's' },
        autocomplete_south = { 'e', 'w', 's', 'n' },
      },
      auto_show = true,
      auto_show_delay_ms = 500,
      update_delay_ms = 100,
    },
    signature_help = {
      min_width = 1,
      max_width = 100,
      max_height = 10,
      border = 'padded',
      winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
    },
  },

  highlight = {
    ns = vim.api.nvim_create_namespace('blink_cmp'),
    -- sets the fallback highlight groups to nvim-cmp's highlight groups
    -- useful for when your theme doesn't support blink.cmp
    -- will be removed in a future release, assuming themes add support
    use_nvim_cmp_as_default = false,
  },

  -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
  -- adjusts spacing to ensure icons are aligned
  nerd_font_variant = 'normal',

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

--- @class blink.cmp.Config
local M = {}

--- @param opts blink.cmp.Config
function M.merge_with(opts) config = vim.tbl_deep_extend('force', config, opts or {}) end

return setmetatable(M, { __index = function(_, k) return config[k] end })
