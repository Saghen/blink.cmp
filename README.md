> [!WARNING]
> This plugin is _beta_ quality. Expect breaking changes and many bugs

> [!NOTE]
> The configuration was recently reworked, please read the [configuration section](#configuration) for the new schema

> [!NOTE]
> If you're on a release tag, ensure you're viewing the README for [the latest release](https://github.com/Saghen/blink.cmp/tree/v0.6.1)

# Blink Completion (blink.cmp)

**blink.cmp** is a completion plugin with support for LSPs and external sources that updates on every keystroke with minimal overhead (0.5-4ms async). It use a [custom SIMD fuzzy searcher](https://github.com/saghen/frizbee) to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going.

<https://github.com/user-attachments/assets/9849e57a-3c2c-49a8-959c-dbb7fef78c80>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](./LSP_TRACKER.md))
- Native `vim.snippet` support (including `friendly-snippets`)
- External sources support ([compatibility layer for `nvim-cmp` sources](https://github.com/Saghen/blink.compat))
- Auto-bracket support based on semantic tokens (experimental, opt-in)
- Signature help (experimental, opt-in)
- [Comparison with nvim-cmp](#compared-to-nvim-cmp)

## Requirements

- Neovim 0.10+
- curl
- git

## Installation

`lazy.nvim`

```lua
{
  'saghen/blink.cmp',
  lazy = false, -- lazy loading handled internally
  -- optional: provides snippets for the snippet source
  dependencies = 'rafamadriz/friendly-snippets',

  -- use a release tag to download pre-built binaries
  version = 'v0.*',
  -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' for mappings similar to built-in completion
    -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
    -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
    -- see the "default configuration" section below for full documentation on how to define
    -- your own keymap.
    keymap = { preset = 'default' },

    appearance = {
      -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      -- Useful for when your theme doesn't support blink.cmp
      -- will be removed in a future release
      use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono'
    },

    -- default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, via `opts_extend`
    sources = {
      completion = {
        enabled_providers = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },

    -- experimental auto-brackets support
    -- completion = { accept = { auto_brackets = { enabled = true } } }

    -- experimental signature help support
    -- signature = { enabled = true }
  },
  -- allows extending the enabled_providers array elsewhere in your config
  -- without having to redefine it
  opts_extend = { "sources.completion.enabled_providers" }
},
```

Setting capabilities for `nvim-lspconfig`:

```lua
-- LSP servers and clients communicate what features they support through "capabilities".
--  By default, Neovim support a subset of the LSP specification.
--  With blink.cmp, Neovim has *more* capabilities which are communicated to the LSP servers.
--  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
--
-- This can vary by config, but in general for nvim-lspconfig:

{
  'neovim/nvim-lspconfig',
  dependencies = { 'saghen/blink.cmp' },

  -- example using `opts` for defining servers
  opts = {
    servers = {
      lua_ls = {}
    }
  },
  config = function(_, opts)
    local lspconfig = require('lspconfig')
    for server, config in pairs(opts.servers) do
      -- passing config.capabilities to blink.cmp merges with the capabilities in your 
      -- `opts[server].capabilities, if you've defined it
      config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
      lspconfig[server].setup(config)
    end
  end

 -- example calling setup directly for each LSP
  config = function()
    local capabilities = require('blink.cmp').get_lsp_capabilities()
    local lspconfig = require('lspconfig')
  
    lspconfig['lua-ls'].setup({ capabilities = capabilities })
  end
}
```

<details>
<summary><strong>mini.deps</strong></summary>

```lua
-- use a release tag to download pre-built binaries
MiniDeps.add({
  source = "saghen/blink.cmp",
  depends = {
  "rafamadriz/friendly-snippets",
  },
  checkout = "some.version", -- check releases for latest tag
})

-- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
local function build_blink(params)
  vim.notify('Building blink.cmp', vim.log.levels.INFO)
  local obj = vim.system({ 'cargo', 'build', '--release' }, { cwd = params.path }):wait()
  if obj.code == 0 then
    vim.notify('Building blink.cmp done', vim.log.levels.INFO)
  else
    vim.notify('Building blink.cmp failed', vim.log.levels.ERROR)
  end
end

MiniDeps.add({
  source = 'Saghen/blink.cmp',
  hooks = {
    post_install = build_blink,
    post_checkout = build_blink,
  },
})
```

</details>

## Configuration

<details>
<summary><strong>Default configuration</strong></summary>

<!-- config:start -->

```lua
{
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
  --   show, hide, cancel, accept, select_and_accept, select_prev, select_next, show_documentation, hide_documentation,
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
  --   you may want to set `completion.trigger.show_in_snippet = false`
  --   or use `completion.list.selection = "manual" | "auto_insert"`
  --
  --   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  --   ['<C-e>'] = { 'hide', 'fallback' },
  --
  --   ['<Tab>'] = {
  --     function(cmp)
  --       if cmp.snippet_active() then return cmp.accept()
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
  --   you may want to set `completion.list.selection = "manual" | "auto_insert"`
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

  -- Disables keymaps, completions and signature help for these filetypes
  blocked_filetypes = {},

  snippets = {
    -- Function to use when expanding LSP provided snippets
    expand = function(snippet) vim.snippet.expand(snippet) end,
    -- Function to use when checking if a snippet is active
    active = function(filter) return vim.snippet.active(filter) end,
    -- Function to use when jumping between tab stops in a snippet, where direction can be negative or positive
    jump = function(direction) vim.snippet.jump(direction) end,
  },

  completion = {
    keyword = {
      -- 'prefix' will fuzzy match on the text before the cursor
      -- 'full' will fuzzy match on the text before *and* after the cursor
      -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
      range = 'prefix',
      -- Regex used to get the text when fuzzy matching
      regex = '[%w_\\-]',
      -- After matching with regex, any characters matching this regex at the prefix will be excluded
      exclude_from_prefix_regex = '[\\-]',
    },

    trigger = {
      -- When false, will not show the completion window automatically when in a snippet
      show_in_snippet = true,
      -- LSPs can indicate when to show the completion window via trigger characters
      -- however, some LSPs (i.e. tsserver) return characters that would essentially
      -- always show the window. We block these by default.
      show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
      -- When true, will show the completion window when the cursor comes after a trigger character
      -- after accepting an item
      show_on_accept_on_trigger_character = true,
      -- When true, will show the completion window when the cursor comes after a trigger character
      -- when entering insert mode
      show_on_insert_on_trigger_character = true,
      -- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
      -- the completion window when the cursor comes after a trigger character when
      -- entering insert mode/accepting an item
      show_on_x_blocked_trigger_characters = { "'", '"', '(' },
    },

    list = {
      -- Maximum number of items to display
      max_items = 200,
      -- Controls if completion items will be selected automatically,
      -- and whether selection automatically inserts
      selection = 'preselect',
      -- Controls how the completion items are selected
      -- 'preselect' will automatically select the first item in the completion list
      -- 'manual' will not select any item by default
      -- 'auto_insert' will not select any item by default, and insert the completion items automatically
      -- when selecting them
      -- 
      -- You may want to bind a key to the `cancel` command, which will undo the selection
      -- when using 'auto_insert'
      cycle = {
        -- When `true`, calling `select_next` at the *bottom* of the completion list
        -- will select the *first* completion item.
        from_bottom = true,
        -- When `true`, calling `select_prev` at the *top* of the completion list
        -- will select the *last* completion item.
        from_top = true,
      },
    },

    accept = {
      -- Create an undo point when accepting a completion item
      create_undo_point = true,
      -- Experimental auto-brackets support
      auto_brackets = {
        -- Whether to auto-insert brackets for functions
        enabled = false,
        -- Default brackets to use for unknown languages
        default_brackets = { '(', ')' },
        -- Overrides the default blocked filetypes
        override_brackets_for_filetypes = {},
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
    },

    menu = {
      enabled = true,
      min_width = 15,
      max_height = 10,
      border = 'none',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
      -- Keep the cursor X lines away from the top/bottom of the window
      scrolloff = 2,
      -- Note that the gutter will be disabled when border ~= 'none'
      scrollbar = true,
      -- Which directions to show the window,
      -- falling back to the next direction when there's not enough space
      direction_priority = { 's', 'n' },
      -- Controls how the completion items are rendered on the popup window
      draw = {
        -- Aligns the keyword you've typed to a component in the menu
        align_to_component = 'label', -- or 'none' to disable
        -- Left and right padding, optionally { left, right } for different padding on each side
        padding = 1,
        -- Gap between columns
        gap = 1,

        -- Components to render, grouped by column
        columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
        -- for a setup similar to nvim-cmp: https://github.com/Saghen/blink.cmp/pull/245#issuecomment-2463659508
        -- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },

        -- Definitions for possible components to render. Each component defines:
        --   ellipsis: whether to add an ellipsis when truncating the text
        --   width: control the min, max and fill behavior of the component
        --   text function: will be called for each item
        --   highlight function: will be called only when the line appears on screen
        components = {
          kind_icon = {
            ellipsis = false,
            text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
            highlight = function(ctx)
              return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or 'BlinkCmpKind' .. ctx.kind
            end,
          },

          kind = {
            ellipsis = false,
            width = { fill = true },
            text = function(ctx) return ctx.kind end,
            highlight = function(ctx)
              return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or 'BlinkCmpKind' .. ctx.kind
            end,
          },

          label = {
            width = { fill = true, max = 60 },
            text = function(ctx) return ctx.label .. ctx.label_detail end,
            highlight = function(ctx)
              -- label and label details
              local highlights = {
                { 0, #ctx.label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
              }
              if ctx.label_detail then
                table.insert(highlights, { #ctx.label, #ctx.label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
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

          source_name = {
            width = { max = 30 },
            text = function(ctx) return '[' .. ctx.source_name .. ']' end,
            highlight = 'BlinkCmpSource',
          },
        },
      },
    },

    documentation = {
      -- Controls whether the documentation window will automatically show when selecting a completion item
      auto_show = false,
      -- Delay before showing the documentation window
      auto_show_delay_ms = 500,
      -- Delay before updating the documentation window when selecting a new item,
      -- while an existing item is still visible
      update_delay_ms = 50,
      -- Whether to use treesitter highlighting, disable if you run into performance issues
      treesitter_highlighting = true,
      window = {
        min_width = 10,
        max_width = 60,
        max_height = 20,
        border = 'padded',
        winblend = 0,
        winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
        -- Note that the gutter will be disabled when border ~= 'none'
        scrollbar = true,
        -- Which directions to show the documentation window,
        -- for each of the possible menu window directions,
        -- falling back to the next direction when there's not enough space
        direction_priority = {
          menu_north = { 'e', 'w', 'n', 's' },
          menu_south = { 'e', 'w', 's', 'n' },
        },
      },
    },
    -- Displays a preview of the selected item on the current line
    ghost_text = {
      enabled = false,
    },
  },
  
  -- Experimental signature help support
  signature = {
    enabled = false,
    trigger = {
      blocked_trigger_characters = {},
      blocked_retrigger_characters = {},
      -- When true, will show the signature help window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
    },
    window = {
      min_width = 1,
      max_width = 100,
      max_height = 10,
      border = 'padded',
      winblend = 0,
      winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
      scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
      -- Which directions to show the window,
      -- falling back to the next direction when there's not enough space,
      -- or another window is in the way
      direction_priority = { 'n', 's' },
      -- Disable if you run into performance issues
      treesitter_highlighting = true,
    },
  },


  fuzzy = {
    -- when enabled, allows for a number of typos relative to the length of the query
    -- disabling this matches the behavior of fzf
    use_typo_resistance = true,
    -- frencency tracks the most recently/frequently used items and boosts the score of the item
    use_frecency = true,
    -- proximity bonus boosts the score of items matching nearby words
    use_proximity = true,
    max_items = 200,
    -- controls which sorts to use and in which order, these three are currently the only allowed options
    sorts = { 'label', 'kind', 'score' },

    prebuilt_binaries = {
      -- Whether or not to automatically download a prebuilt binary from github. If this is set to `false`
      -- you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
      download = true,
      -- When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset
      -- then the downloader will attempt to infer the version from the checked out git tag (if any).
      --
      -- Beware that if the FFI ABI changes while tracking main then this may result in blink breaking.
      force_version = nil,
      -- When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset
      -- then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`.
      -- Check the latest release for all available system triples
      --
      -- Beware that if the FFI ABI changes while tracking main then this may result in blink breaking.
      force_system_triple = nil,
    },
  },

  sources = {
    completion = {
      -- Static list of providers to enable, or a function to dynamically enable/disable providers based on the context
      enabled_providers = { 'lsp', 'path', 'snippets', 'buffer' },
      -- Example dynamically picking providers based on the filetype and treesitter node:
      -- enabled_providers = function(ctx)
      --   local node = vim.treesitter.get_node()
      --   if vim.bo.filetype == 'lua' then
      --     return { 'lsp', 'path' }
      --   elseif node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }), node:type())
      --     return { 'buffer' }
      --   else
      --     return { 'lsp', 'path', 'snippets', 'buffer' }
      --   end
      -- end
    },

    -- Please see https://github.com/Saghen/blink.compat for using `nvim-cmp` sources
    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',

        --- *All* of the providers have the following options available
        --- NOTE: All of these options may be functions to get dynamic behavior
        --- See the type definitions for more information.
        --- Check the enabled_providers config for an example
        enabled = true, -- Whether or not to enable the provider
        transform_items = nil, -- Function to transform the items before they're returned
        should_show_items = true, -- Whether or not to show the items
        max_items = nil, -- Maximum number of items to display in the menu
        min_keyword_length = 0, -- Minimum number of characters in the keyword to trigger the provider
        fallback_for = {}, -- If any of these providers return 0 items, it will fallback to this provider
        score_offset = 0, -- Boost/penalize the score of the items
        override = nil, -- Override the source's functions
      },
      path = {
        name = 'Path',
        module = 'blink.cmp.sources.path',
        score_offset = 3,
        opts = {
          trailing_slash = false,
          label_trailing_slash = true,
          get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
          show_hidden_files_by_default = false,
        }
      },
      snippets = {
        name = 'Snippets',
        module = 'blink.cmp.sources.snippets',
        score_offset = -3,
        opts = {
          friendly_snippets = true,
          search_paths = { vim.fn.stdpath('config') .. '/snippets' },
          global_snippets = { 'all' },
          extended_filetypes = {},
          ignored_filetypes = {},
          get_filetype = function(context)
            return vim.bo.filetype
          end
        }

        --- Example usage for disabling the snippet provider after pressing trigger characters (i.e. ".")
        -- enabled = function(ctx)
        --   return ctx ~= nil and ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        -- end,
      },
      buffer = {
        name = 'Buffer',
        module = 'blink.cmp.sources.buffer',
        fallback_for = { 'lsp' },
      },
    },
  },

  appearance = {
    highlight_ns = vim.api.nvim_create_namespace('blink_cmp'),
    -- Sets the fallback highlight groups to nvim-cmp's highlight groups
    -- Useful for when your theme doesn't support blink.cmp
    -- Will be removed in a future release
    use_nvim_cmp_as_default = false,
    -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
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
```

<!-- config:end -->

</details>


<details>
<summary><strong>Highlight groups</strong></summary>

| Group | Default | Description |
| ----- | ------- | ----------- |
| `BlinkCmpMenu` | Pmenu | The completion menu window |
| `BlinkCmpMenuBorder` | Pmenu | The completion menu window border |
| `BlinkCmpMenuSelection` | PmenuSel | The completion menu window selected item |
| `BlinkCmpScrollBarThumb` | PmenuThumb | The scrollbar thumb |
| `BlinkCmpScrollBarGutter` | PmenuSbar | The scrollbar gutter |
| `BlinkCmpLabel` | Pmenu | Label of the completion item |
| `BlinkCmpLabelDeprecated` | Comment | Deprecated label of the completion item |
| `BlinkCmpLabelMatch` | Pmenu | (Currently unused) Label of the completion item when it matches the query |
| `BlinkCmpGhostText` | Comment | Preview item with ghost text  |
| `BlinkCmpKind` | Special | Kind icon/text of the completion item |
| `BlinkCmpKind<kind>` | Special | Kind icon/text of the completion item |
| `BlinkCmpDoc` | NormalFloat | The documentation window |
| `BlinkCmpDocBorder` | NormalFloat | The documentation window border |
| `BlinkCmpDocCursorLine` | Visual | The documentation window cursor line |
| `BlinkCmpSignatureHelp` | NormalFloat | The signature help window |
| `BlinkCmpSignatureHelpBorder` | NormalFloat | The signature help window border |
| `BlinkCmpSignatureHelpActiveParameter` | LspSignatureActiveParameter | Active parameter of the signature help |

</details>


### Community Sources

- [lazydev](https://github.com/folke/lazydev.nvim)
- [ctags](https://github.com/netmute/blink-cmp-ctags)
- [ripgrep](https://github.com/niuiic/blink-cmp-rg.nvim)
- [blink-ripgrep](https://github.com/mikavilpas/blink-ripgrep.nvim)
- [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)

### Luasnip

There's currently no `blink.cmp` native source for [luasnip](https://github.com/L3MON4D3/LuaSnip). You may use [blink.compat](https://github.com/saghen/blink.compat) plugin with the [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) nvim-cmp source in the meantime.

```lua
{
  'saghen/blink.cmp',
  version = '0.*',
  dependencies = { 
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    -- lock compat to tagged versions, if you've also locked blink.cmp to tagged versions
    { 'saghen/blink.compat', version = '*', opts = { impersonate_nvim_cmp = true } } },
  opts = {
    snippets = {
      expand = function(snippet) require('luasnip').lsp_expand(snippet) end,
      active = function(filter)
        if filter and filter.direction then
          return require('luasnip').jumpable(filter.direction)
        end
        return require('luasnip').in_snippet()
      end,
      jump = function(direction) require('luasnip').jump(direction) end,
    },
    sources = {
      completion = {
        -- WARN: add the rest of your providers here, unless you're using `opts_extend` 
        -- and defining this outside of your primary `blink.cmp` config
        -- see the default configuration for the default providers
        enabled_providers = { 'luasnip' },
      },
      providers = {
        luasnip = {
          name = 'luasnip',
          module = 'blink.compat.source',

          score_offset = -3,

          opts = {
            use_show_condition = false,
            show_autosnippets = true,
          },
        },
      },
    },
  }
}
```

### Menu Appearance/Drawing

<details>
<summary><strong>Default draw configuration</strong></summary>

<!-- config:start -->
```lua
--- @module 'blink.cmp'
--- @type blink.cmp.Draw
completion.menu.draw = {
  -- Aligns the keyword you've typed to a component in the menu
  align_to_component = 'label', -- or 'none' to disable
  -- Left and right padding, optionally { left, right } for different padding on each side
  padding = 1,
  -- Gap between columns
  gap = 1,

  -- Components to render, grouped by column
  columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
  -- for a setup similar to nvim-cmp: https://github.com/Saghen/blink.cmp/pull/245#issuecomment-2463659508
  -- columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },

  -- Definitions for possible components to render. Each component defines:
  --   ellipsis: whether to add an ellipsis when truncating the text
  --   width: control the min, max and fill behavior of the component
  --   text function: will be called for each item
  --   highlight function: will be called only when the line appears on screen
  components = {
    kind_icon = {
      ellipsis = false,
      text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
      highlight = function(ctx)
        return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or 'BlinkCmpKind' .. ctx.kind
      end,
    },

    kind = {
      ellipsis = false,
      width = { fill = true },
      text = function(ctx) return ctx.kind end,
      highlight = function(ctx)
        return require('blink.cmp.completion.windows.render.tailwind').get_hl(ctx) or 'BlinkCmpKind' .. ctx.kind
      end,
    },

    label = {
      width = { fill = true, max = 60 },
      text = function(ctx) return ctx.label .. ctx.label_detail end,
      highlight = function(ctx)
        -- label and label details
        local highlights = {
          { 0, #ctx.label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
        }
        if ctx.label_detail then
          table.insert(highlights, { #ctx.label, #ctx.label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
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
}
```

<!-- config:end -->

</details>

blink.cmp uses a grid-based layout to render the completion menu. The components, defined in `draw.components[string]`, define `text` and `highlight` functions which are called for each completion item. The `highlight` function will be called only when the item appears on screen, so expensive operations such as Treesitter highlighting may be performed (contributions welcome!, [for example](https://www.reddit.com/r/neovim/comments/1ca4gm2/colorful_cmp_menu_powered_by_treesitter/)). The components may define their min and max width, where `ellipsis = true` (enabled by default), will draw the `…` character when the text is truncated. Setting `width.fill = true` will fill the remaining space, effectively making subsequent components right aligned, with respect to their column.

Columns effectively allow you to vertically align a set of components. Each column, defined as an array in `draw.columns`, will be rendered for all of the completion items, where the longest rendered row will determine the width of the column. You may define `gap = number` in your column to insert a gap between components.

For a setup similar to nvim-cmp, use the following config:

```lua
{
  completion = {
    menu = {
      draw = {
        columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
      },
    },
  }
}
```

## How it works

The plugin use a 4 stage pipeline: trigger -> sources -> fuzzy -> render
1. **Trigger:** Controls when to request completion items from the sources and provides a context downstream with the current query (i.e. `hello.wo|`, the query would be `wo`) and the treesitter object under the cursor (i.e. for intelligently enabling/disabling sources). It respects trigger characters passed by the LSP (or any other source) and includes it in the context for sending to the LSP.
2. **Sources:** Provides a common interface for and merges the results of completion, trigger character, resolution of additional information and cancellation. Some sources are builtin: `LSP`, `buffer`, `path`, `snippets`
3. **Fuzzy:** Rust <-> Lua FFI which performs both filtering and sorting of the items
	- **Filtering:** The fuzzy matching uses smith-waterman, same as FZF, but implemented in SIMD for ~6x the performance of FZF (TODO: add benchmarks). Due to the SIMD's performance, the prefiltering phase on FZF was dropped to allow for typos. Similar to fzy/fzf, additional points are given to prefix matches, characters with capitals (to promote camelCase/PascalCase first char matching) and matches after delimiters (to promote snake_case first char matching)
	- **Sorting:** Combines fuzzy matching score with frecency and proximity bonus. Each completion item may also include a `score_offset` which will be added to this score to demote certain sources. The `snippets` source takes advantage of this to avoid taking precedence over the LSP source. The parameters here still need to be tuned, so please let me know if you find some magical parameters!
4. **Windows:** Responsible for placing the menu, documentation and function parameters windows. All of the rendering can be overridden following a syntax similar to incline.nvim. It uses the neovim window decoration provider to provide next to no overhead from highlighting.

## Compared to nvim-cmp

### Advantages

- Avoids the complexity of nvim-cmp's configuration by providing sensible defaults
- Updates on every keystroke with 0.5-4ms of overhead, versus nvim-cmp's default debounce of 60ms with 2-50ms hitches from processing
  - Setting nvim-cmp's debounce to 0ms leads to visible stuttering. If you'd like to stick with nvim-cmp, try [yioneko's fork](https://github.com/yioneko/nvim-cmp) or the more recent [magazine.nvim](https://github.com/iguanacucumber/magazine.nvim)
- Boosts completion item score via frecency _and_ proximity bonus. nvim-cmp only boosts score via proximity bonus and optionally by recency
- Typo-resistant fuzzy matching unlike nvim-cmp's fzf-style fuzzy matching
- Core sources (buffer, snippets, path, lsp) are built-in versus nvim-cmp's exclusively external sources
- Built-in auto bracket and signature help support

### Planned missing features

- Significantly more testing and documentation
- Cmdline completions

## Special Thanks

- [@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and nvim-path implementation modified for path source
- [@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source
- [@redxtech](https://github.com/redxtech) Help with design and testing
- [@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing

### Contributors

- [@stefanboca](https://github.com/stefanboca) Author of [blink.compat](https://github.com/saghen/blink.compat)
- [@lopi-py](https://github.com/lopi-py) Contributes to the windowing code
- [@scottmckendry](https://github.com/scottmckendry) Contributes to the CI and prebuilt binaries
- [@balssh](https://github.com/Balssh) Manages nixpkg and nixvim
