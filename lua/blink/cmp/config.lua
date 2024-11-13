--- @alias blink.cmp.KeymapCommand
--- | 'fallback' Fallback to the built-in behavior
--- | 'show' Show the completion window
--- | 'hide' Hide the completion window
--- | 'accept' Accept the current completion item
--- | 'select_and_accept' Select the current completion item and accept it
--- | 'select_prev' Select the previous completion item
--- | 'select_next' Select the next completion item
--- | 'show_documentation' Show the documentation window
--- | 'hide_documentation' Hide the documentation window
--- | 'scroll_documentation_up' Scroll the documentation window up
--- | 'scroll_documentation_down' Scroll the documentation window down
--- | 'snippet_forward' Move the cursor forward to the next snippet placeholder
--- | 'snippet_backward' Move the cursor backward to the previous snippet placeholder
--- | (fun(cmp: table): boolean?) Custom function where returning true will prevent the next command from running

--- @alias blink.cmp.KeymapPreset
--- | 'default' mappings similar to built-in completion
--- | 'super-tab' mappings similar to vscode (tab to accept, arrow keys to navigate)
--- | 'enter' mappings similar to 'super-tab' but with 'enter' to accept

--- @class blink.cmp.KeymapConfig
--- @field preset? blink.cmp.KeymapPreset
--- @field [string]? blink.cmp.KeymapCommand[]> Table of keys => commands[]

--- @class blink.cmp.AcceptConfig
--- @field expand_snippet? fun(string)
--- @field create_undo_point? boolean Create an undo point when accepting a completion item
--- @field auto_brackets? blink.cmp.AutoBracketsConfig

--- @class blink.cmp.AutoBracketsConfig
--- @field enabled? boolean
--- @field default_brackets? string[]
--- @field override_brackets_for_filetypes? table<string, string[] | fun(item: blink.cmp.CompletionItem): string[]>
--- @field force_allow_filetypes? string[] Overrides the default blocked filetypes
--- @field blocked_filetypes? string[]
--- @field kind_resolution? blink.cmp.AutoBracketResolutionConfig Synchronously use the kind of the item to determine if brackets should be added
--- @field semantic_token_resolution? blink.cmp.AutoBracketSemanticTokenResolutionConfig Asynchronously use semantic token to determine if brackets should be added

--- @class blink.cmp.AutoBracketResolutionConfig
--- @field enabled? boolean
--- @field blocked_filetypes? string[]
---
--- @class blink.cmp.AutoBracketSemanticTokenResolutionConfig : blink.cmp.AutoBracketResolutionConfig
--- @field timeout_ms? number How long to wait for semantic tokens to return before assuming no brackets should be added

--- @class blink.cmp.CompletionTriggerConfig
--- @field keyword_range? 'prefix' | 'full'
--- @field keyword_regex? string
--- @field exclude_from_prefix_regex? string
--- @field blocked_trigger_characters? string[]
--- @field show_on_accept_on_trigger_character? boolean When true, will show the completion window when the cursor comes after a trigger character after accepting an item
--- @field show_on_insert_on_trigger_character? boolean When true, will show the completion window when the cursor comes after a trigger character when entering insert mode
--- @field show_on_x_blocked_trigger_characters? string[] List of additional trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item
--- @field show_in_snippet? boolean When false, will not show the completion window when in a snippet
---
--- @class blink.cmp.SignatureHelpTriggerConfig
--- @field enabled? boolean
--- @field blocked_trigger_characters? string[]
--- @field blocked_retrigger_characters? string[]
--- @field show_on_insert_on_trigger_character? boolean When true, will show the signature help window when the cursor comes after a trigger character when entering insert mode
---
--- @class blink.cmp.TriggerConfig
--- @field completion? blink.cmp.CompletionTriggerConfig
--- @field signature_help? blink.cmp.SignatureHelpTriggerConfig

--- @class blink.cmp.SourceConfig
--- @field completion? blink.cmp.SourceModeConfig
--- @field providers? table<string, blink.cmp.SourceProviderConfig>
---
--- @class blink.cmp.SourceModeConfig
--- @field enabled_providers? string[] | fun(ctx?: blink.cmp.Context): string[]
---
--- @class blink.cmp.SourceProviderConfig
--- @field name string
--- @field module? string
--- @field enabled? boolean | fun(ctx?: blink.cmp.Context): boolean
--- @field opts? table
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
--- @field should_show_items? boolean | number | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean
--- @field max_items? number | fun(ctx: blink.cmp.Context, enabled_sources: string[], items: blink.cmp.CompletionItem[]): number
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number
--- @field fallback_for? string[] | fun(ctx: blink.cmp.Context, enabled_sources: string[]): string[]
--- @field score_offset? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number
--- @field deduplicate? blink.cmp.DeduplicateConfig
--- @field override? blink.cmp.SourceOverride
---
--- @class blink.cmp.DeduplicateConfig
--- @field enabled? boolean
--- @field priority? number

--- @class blink.cmp.PrebuiltBinariesConfig
--- @field download? boolean
--- @field force_version? string | nil
--- @field force_system_triple? string | nil

--- @class blink.cmp.FuzzyConfig
--- @field use_typo_resistance? boolean
--- @field use_frecency? boolean
--- @field use_proximity? boolean
--- @field max_items? number
--- @field sorts? ("label" | "kind" | "score")[]
--- @field prebuilt_binaries? blink.cmp.PrebuiltBinariesConfig

--- @class blink.cmp.WindowConfig
--- @field autocomplete? blink.cmp.AutocompleteConfig
--- @field documentation? blink.cmp.DocumentationConfig
--- @field signature_help? blink.cmp.SignatureHelpConfig
--- @field ghost_text? GhostTextConfig

--- @class blink.cmp.HighlightConfig
--- @field ns? number
--- @field use_nvim_cmp_as_default? boolean

--- @class blink.cmp.AutocompleteConfig
--- @field min_width? number
--- @field max_height? number
--- @field border? blink.cmp.WindowBorder
--- @field scrollbar? boolean
--- @field order? "top_down" | "bottom_up"
--- @field direction_priority? ("n" | "s")[]
--- @field auto_show? boolean
--- @field selection? "preselect" | "manual" | "auto_insert"
--- @field winblend? number
--- @field winhighlight? string
--- @field scrolloff? number
--- @field draw? blink.cmp.Draw
--- @field cycle? blink.cmp.AutocompleteConfig.CycleConfig

--- @class blink.cmp.AutocompleteConfig.CycleConfig
--- @field from_bottom? boolean When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
--- @field from_top? boolean When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.

--- @class blink.cmp.DocumentationDirectionPriorityConfig
--- @field autocomplete_north? ("n" | "s" | "e" | "w")[]
--- @field autocomplete_south? ("n" | "s" | "e" | "w")[]
---
--- @alias blink.cmp.WindowBorderChar string | table
--- @alias blink.cmp.WindowBorder 'single' | 'double' | 'rounded' | 'solid' | 'shadow' | 'padded' | 'none' | blink.cmp.WindowBorderChar[]
---
--- @class blink.cmp.DocumentationConfig
--- @field max_width? number
--- @field max_height? number
--- @field desired_min_width? number
--- @field desired_min_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrollbar? boolean
--- @field direction_priority? blink.cmp.DocumentationDirectionPriorityConfig
--- @field auto_show? boolean
--- @field auto_show_delay_ms? number Delay before showing the documentation window
--- @field update_delay_ms? number Delay before updating the documentation window

--- @class blink.cmp.SignatureHelpConfig
--- @field min_width? number
--- @field max_width? number
--- @field max_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrollbar? boolean
--- @field direction_priority? ("n" | "s")[]

--- @class GhostTextConfig
--- @field enabled? boolean

--- @class blink.cmp.Config
--- @field keymap? blink.cmp.KeymapConfig | blink.cmp.KeymapPreset
--- @field accept? blink.cmp.AcceptConfig
--- @field trigger? blink.cmp.TriggerConfig
--- @field fuzzy? blink.cmp.FuzzyConfig
--- @field sources? blink.cmp.SourceConfig
--- @field windows? blink.cmp.WindowConfig
--- @field highlight? blink.cmp.HighlightConfig
--- @field nerd_font_variant? 'mono' | 'normal'
--- @field kind_icons? table<string, string>
--- @field blocked_filetypes? string[]

local utils = require('blink.cmp.utils')

--- @type blink.cmp.Config
local config = {
  -- The keymap can be:
  --   - A preset ('default' | 'super-tab' | 'enter')
  --   - A table of keys => command[] (optionally with a "preset" key to merge with a preset)
  --
  -- When specifying 'preset' in the keymap table, the custom key mappings are merged with the preset,
  -- and any conflicting keys will overwrite the preset mappings.
  -- The "fallback" command will run the next non blink keymap.
  --
  -- Example:
  --
  -- keymap = {
  --   preset = 'default',
  --   ['<Up>'] = { 'select_prev', 'fallback' },
  --   ['<Down>'] = { 'select_next', 'fallback' },
  --
  --   -- disable a keymap from the preset
  --   ['<C-e>'] = {},
  -- },
  --
  -- When defining your own keymaps without a preset, no keybinds will be assigned automatically.
  --
  -- Available commands:
  --   show, hide, accept, select_and_accept, select_prev, select_next, show_documentation, hide_documentation,
  --   scroll_documentation_up, scroll_documentation_down, snippet_forward, snippet_backward, fallback
  --
  -- "default" keymap
  --   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  --   ['<C-e>'] = { 'hide' },
  --   ['<C-y>'] = { 'select_and_accept' },
  --
  --   ['<C-p>'] = { 'select_prev', 'fallback' },
  --   ['<C-n>'] = { 'select_next', 'fallback' },
  --
  --   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  --   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  --
  --   ['<Tab>'] = { 'snippet_forward', 'fallback' },
  --   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  --
  -- "super-tab" keymap
  --   you may want to set `trigger.completion.show_in_snippet = false`
  --   or use `window.autocomplete.selection = "manual" | "auto_insert"`
  --
  --   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  --   ['<C-e>'] = { 'hide', 'fallback' },
  --
  --   ['<Tab>'] = {
  --     function(cmp)
  --       if cmp.is_in_snippet() then return cmp.accept()
  --       else return cmp.select_and_accept() end
  --     end,
  --     'snippet_forward',
  --     'fallback'
  --   },
  --   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  --
  --   ['<Up>'] = { 'select_prev', 'fallback' },
  --   ['<Down>'] = { 'select_next', 'fallback' },
  --   ['<C-p>'] = { 'select_prev', 'fallback' },
  --   ['<C-n>'] = { 'select_next', 'fallback' },
  --
  --   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  --   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  --
  -- "enter" keymap
  --   you may want to set `window.autocomplete.selection = "manual" | "auto_insert"`
  --
  --   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  --   ['<C-e>'] = { 'hide', 'fallback' },
  --   ['<CR>'] = { 'accept', 'fallback' },
  --
  --   ['<Tab>'] = { 'snippet_forward', 'fallback' },
  --   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  --
  --   ['<Up>'] = { 'select_prev', 'fallback' },
  --   ['<Down>'] = { 'select_next', 'fallback' },
  --   ['<C-p>'] = { 'select_prev', 'fallback' },
  --   ['<C-n>'] = { 'select_next', 'fallback' },
  --
  --   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
  --   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  keymap = 'default',

  accept = {
    create_undo_point = true,
    auto_brackets = {
      enabled = false,
      default_brackets = { '(', ')' },
      override_brackets_for_filetypes = {},
      -- Overrides the default blocked filetypes
      force_allow_filetypes = {},
      blocked_filetypes = {},
      -- Synchronously use the kind of the item to determine if brackets should be added
      kind_resolution = {
        enabled = true,
        blocked_filetypes = { 'typescriptreact', 'javascriptreact', 'vue' },
      },
      -- Asynchronously use semantic token to determine if brackets should be added
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = {},
        -- How long to wait for semantic tokens to return before assuming no brackets should be added
        timeout_ms = 400,
      },
    },
    expand_snippet = vim.snippet.expand,
  },

  trigger = {
    completion = {
      -- 'prefix' will fuzzy match on the text before the cursor
      -- 'full' will fuzzy match on the text before *and* after the cursor
      -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
      keyword_range = 'prefix',
      -- regex used to get the text when fuzzy matching
      -- changing this may break some sources, so please report if you run into issues
      -- TODO: shouldnt this also affect the accept command? should this also be per language?
      keyword_regex = '[%w_\\-]',
      -- after matching with keyword_regex, any characters matching this regex at the prefix will be excluded
      exclude_from_prefix_regex = '[\\-]',
      -- LSPs can indicate when to show the completion window via trigger characters
      -- however, some LSPs (*cough* tsserver *cough*) return characters that would essentially
      -- always show the window. We block these by default
      blocked_trigger_characters = { ' ', '\n', '\t' },
      -- when true, will show the completion window when the cursor comes after a trigger character after accepting an item
      show_on_accept_on_trigger_character = true,
      -- when true, will show the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
      -- list of additional trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item
      show_on_x_blocked_trigger_characters = { "'", '"', '(' },
      -- when false, will not show the completion window when in a snippet
      show_in_snippet = true,
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
    -- when enabled, allows for a number of typos relative to the length of the query
    -- disabling this matches the behavior of fzf
    use_typo_resistance = true,
    -- frencency tracks the most recently/frequently used items and boosts the score of the item
    use_frecency = true,
    -- proximity bonus boosts the score of items with a value in the buffer
    use_proximity = true,
    max_items = 200,
    -- controls which sorts to use and in which order, these three are currently the only allowed options
    sorts = { 'label', 'kind', 'score' },

    prebuilt_binaries = {
      -- Whether or not to automatically download a prebuilt binary from github. If this is set to `false`
      -- you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
      download = true,
      -- When downloading a prebuilt binary force the downloader to resolve this version. If this is uset
      -- then the downloader will attempt to infer the version from the checked out git tag (if any).
      --
      -- Beware that if the FFI ABI changes while tracking main then this may result in blink breaking.
      force_version = nil,
      -- When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset
      -- then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`.
      --
      -- Beware that if the FFI ABI changes while tracking main then this may result in blink breaking.
      force_system_triple = nil,
    },
  },

  sources = {
    -- list of enabled providers
    completion = {
      enabled_providers = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    -- table of providers to configure
    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',
      },
      path = {
        name = 'Path',
        module = 'blink.cmp.sources.path',
        score_offset = 3,
      },
      snippets = {
        name = 'Snippets',
        module = 'blink.cmp.sources.snippets',
        score_offset = -3,
      },
      buffer = {
        name = 'Buffer',
        module = 'blink.cmp.sources.buffer',
        fallback_for = { 'lsp' },
      },
    },
  },

  windows = {
    autocomplete = {
      min_width = 15,
      max_height = 10,
      border = 'none',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
      -- keep the cursor X lines away from the top/bottom of the window
      scrolloff = 2,
      -- note that the gutter will be disabled when border ~= 'none'
      scrollbar = true,
      -- TODO: implement
      order = 'top_down',
      -- which directions to show the window,
      -- falling back to the next direction when there's not enough space
      direction_priority = { 's', 'n' },
      -- Controls whether the completion window will automatically show when typing
      auto_show = true,
      -- Controls how the completion items are selected
      -- 'preselect' will automatically select the first item in the completion list
      -- 'manual' will not select any item by default
      -- 'auto_insert' will not select any item by default, and insert the completion items automatically when selecting them
      selection = 'preselect',
      -- Controls how the completion items are rendered on the popup window
      draw = {
        align_to_component = 'label', -- or 'none' to disable
        -- Left and right padding, optionally { left, right } for different padding on each side
        padding = 1,
        -- Gap between columns
        gap = 1,
        -- Components to render, grouped by column
        columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
        -- Definitions for possible components to render. Each component defines:
        --   ellipsis: whether to add an ellipsis when truncating the text
        --   width: control the min, max and fill behavior of the component
        --   text function: will be called for each item
        --   highlight function: will be called only when the line appears on screen
        components = {
          kind_icon = {
            ellipsis = false,
            text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
            highlight = function(ctx) return utils.get_tailwind_hl(ctx) or 'BlinkCmpKind' .. ctx.kind end,
          },

          kind = {
            ellipsis = false,
            width = { fill = true },
            text = function(ctx) return ctx.kind end,
            highlight = function(ctx) return utils.get_tailwind_hl(ctx) or 'BlinkCmpKind' .. ctx.kind end,
          },

          label = {
            width = { fill = true, max = 60 },
            text = function(ctx) return ctx.label .. ctx.label_detail end,
            highlight = function(ctx)
              -- label and label details
              local label = ctx.label
              local highlights = {
                { 0, #label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
              }
              if ctx.label_detail then
                table.insert(highlights, { #label, #label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
              end

              -- characters matched on the label by the fuzzy matcher
              for _, idx in ipairs(ctx.label_matched_indices) do
                table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
              end

              return highlights
            end,
          },

          label_description = {
            width = { max = 30 },
            text = function(ctx) return ctx.label_description end,
            highlight = 'BlinkCmpLabelDescription',
          },
        },
      },
      -- Controls the cycling behavior when reaching the beginning or end of the completion list.
      cycle = {
        -- When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
        from_bottom = true,
        -- When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.
        from_top = true,
      },
    },
    documentation = {
      max_width = 80,
      max_height = 20,
      desired_min_width = 50,
      desired_min_height = 10,
      border = 'padded',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
      -- note that the gutter will be disabled when border ~= 'none'
      scrollbar = true,
      -- which directions to show the documentation window,
      -- for each of the possible autocomplete window directions,
      -- falling back to the next direction when there's not enough space
      direction_priority = {
        autocomplete_north = { 'e', 'w', 'n', 's' },
        autocomplete_south = { 'e', 'w', 's', 'n' },
      },
      -- Controls whether the documentation window will automatically show when selecting a completion item
      auto_show = false,
      auto_show_delay_ms = 500,
      update_delay_ms = 50,
    },
    signature_help = {
      min_width = 1,
      max_width = 100,
      max_height = 10,
      border = 'padded',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
      -- note that the gutter will be disabled when border ~= 'none'
      scrollbar = false,

      -- which directions to show the window,
      -- falling back to the next direction when there's not enough space
      direction_priority = { 'n', 's' },
    },
    ghost_text = {
      enabled = false,
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
  nerd_font_variant = 'mono',

  -- don't show completions or signature help for these filetypes. Keymaps are also disabled.
  blocked_filetypes = {},

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
function M.merge_with(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- TODO: remove on 1.0
  if type(config.windows.autocomplete.draw) == 'string' or type(config.windows.autocomplete.draw) == 'function' then
    error('The blink.cmp autocomplete draw has been rewritten, please see the README for the new configuration')
  end
end

return setmetatable(M, { __index = function(_, k) return config[k] end })
