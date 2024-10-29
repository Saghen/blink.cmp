> [!WARNING]
> This plugin is _beta_ quality. Expect breaking changes and many bugs

# Blink Completion (blink.cmp)

**blink.cmp** is a completion plugin with support for LSPs and external sources while updating on every keystroke with minimal overhead (0.5-4ms async). It achieves this by writing the fuzzy searching in SIMD to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going.

<https://github.com/user-attachments/assets/9849e57a-3c2c-49a8-959c-dbb7fef78c80>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- Typo resistant fuzzy with frecency and proximity bonus
- Extensive LSP support ([tracker](./LSP_TRACKER.md))
- Native `vim.snippet` support (including `friendly-snippets`)
- External sources support (currently incompatible with `nvim-cmp` sources)
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
    -- see the "default configuration" section below for full documentation on how to define
    -- your own keymap. when defining your own, no keybinds will be assigned automatically.
    keymap = 'default',

    highlight = {
      -- sets the fallback highlight groups to nvim-cmp's highlight groups
      -- useful for when your theme doesn't support blink.cmp
      -- will be removed in a future release, assuming themes add support
      use_nvim_cmp_as_default = true,
    },
    -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'normal',

    -- experimental auto-brackets support
    -- accept = { auto_brackets = { enabled = true } }

    -- experimental signature help support
    -- trigger = { signature_help = { enabled = true } }
  }
}
```

For LazyVim/distro users, you can disable nvim-cmp via:

```lua
{ 'hrsh7th/nvim-cmp', enabled = false }
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

<details>
<summary><strong>Highlight groups</strong></summary>

| Group | Default | Description |
| ----- | ------- | ----------- |
| `BlinkCmpMenu` | Pmenu | The completion menu window |
| `BlinkCmpMenuBorder` | Pmenu | The completion menu window border |
| `BlinkCmpMenuSelection` | PmenuSel | The completion menu window selected item |
| `BlinkCmpLabel` | Pmenu | Label of the completion item |
| `BlinkCmpLabelDeprecated` | Comment | Deprecated label of the completion item |
| `BlinkCmpLabelMatch` | Pmenu | (Currently unused) Label of the completion item when it matches the query |
| `BlinkCmpKind` | Special | Kind icon/text of the completion item |
| `BlinkCmpKind<kind>` | Special | Kind icon/text of the completion item |
| `BlinkCmpDoc` | NormalFloat | The documentation window |
| `BlinkCmpDocBorder` | FloatBorder | The documentation window border |
| `BlinkCmpDocCursorLine` | Visual | The documentation window cursor line |
| `BlinkCmpSignatureHelp` | NormalFloat | The signature help window |
| `BlinkCmpSignatureHelpBorder` | FloatBorder | The signature help window border |
| `BlinkCmpSignatureHelpActiveParameter` | LspSignatureActiveParameter | Active parameter of the signature help |

</details>

<details>
<summary><strong>Default configuration</strong></summary>

<!-- config:start -->

```lua
{
  -- the keymap may be a preset ('default' | 'super-tab') OR a table of keys => command[]
  -- when defining your own, no keybinds will be assigned automatically.
  -- additionally, you may pass a function in the command array where returning true 
  -- will prevent the next command from running
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
  --   you may want to set `trigger.show_in_snippet = false` when using "super-tab"
  --   or use `window.autocomplete.selection = "manual" | "auto_insert"`
  --
  --   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
  --   ['<C-e>'] = { 'hide' },
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
  -- available commands:
  --   show, hide, accept, select_and_accept, select_prev, select_next, show_documentation, hide_documentation,
  --   scroll_documentation_up, scroll_documentation_down, snippet_forward, snippet_backward, fallback
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
      -- when true, will show the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
      -- list of additional trigger characters that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_blocked_trigger_characters = { "'", '"' },
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
    -- list of enabled providers
    completion = { 
      enabled_providers = {'lsp', 'path', 'snippets', 'buffer' },
    }

    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',

        --- *All* of the providers have the following options available
        --- NOTE: All of these options may be functions to get dynamic behavior
        --- See the type definitions for more information
        enabled = true, -- whether or not to enable the provider
        transform_items = nil, -- function to transform the items before they're returned
        should_show_items = true, -- whether or not to show the items
        max_items = nil, -- maximum number of items to return
        min_keyword_length = 0, -- minimum number of characters to trigger the provider
        fallback_for = {}, -- if any of these providers return 0 items, it will fallback to this provider
        score_offset = 0, -- boost/penalize the score of the items
        override = nil, -- override the source's functions
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
        }

        --- Example usage for disabling the snippet provider after pressing trigger characters (i.e. ".")
        -- enabled = function(ctx) return ctx ~= nil and ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter end,
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
      winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
      -- keep the cursor X lines away from the top/bottom of the window
      scrolloff = 2,
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
      -- 'simple' will render the item's kind icon the left alongside the label
      -- 'reversed' will render the label on the left and the kind icon + name on the right
      -- 'minimal' will render the label on the left and the kind name on the right
      -- 'function(blink.cmp.CompletionRenderContext): blink.cmp.Component[]' for custom rendering
      draw = 'simple',
      -- Controls the cycling behavior when reaching the beginning or end of the completion list.
      cycle = {
        -- When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
        from_bottom = true,
        -- When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.
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
      winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
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
  nerd_font_variant = 'normal',

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
```

<!-- config:end -->

</details>

<details>
<summary><strong>Community Sources</strong></summary>

- [ctags](https://github.com/netmute/blink-cmp-ctags)
- [ripgrep](https://github.com/niuiic/blink-cmp-rg.nvim)

</details>

## How it works

The plugin use a 4 stage pipeline: trigger -> sources -> fuzzy -> render

**Trigger:** Controls when to request completion items from the sources and provides a context downstream with the current query (i.e. `hello.wo|`, the query would be `wo`) and the treesitter object under the cursor (i.e. for intelligently enabling/disabling sources). It respects trigger characters passed by the LSP (or any other source) and includes it in the context for sending to the LSP.

**Sources:** Provides a common interface for and merges the results of completion, trigger character, resolution of additional information and cancellation. Some sources are builtin: `LSP`, `buffer`, `path`, `snippets`

**Fuzzy:** Rust <-> Lua FFI which performs both filtering and sorting of the items

&nbsp;&nbsp;&nbsp;&nbsp;**Filtering:** The fuzzy matching uses smith-waterman, same as FZF, but implemented in SIMD for ~6x the performance of FZF (TODO: add benchmarks). Due to the SIMD's performance, the prefiltering phase on FZF was dropped to allow for typos. Similar to fzy/fzf, additional points are given to prefix matches, characters with capitals (to promote camelCase/PascalCase first char matching) and matches after delimiters (to promote snake_case first char matching)

&nbsp;&nbsp;&nbsp;&nbsp;**Sorting:** Combines fuzzy matching score with frecency and proximity bonus. Each completion item may also include a `score_offset` which will be added to this score to demote certain sources. The `snippets` source takes advantage of this to avoid taking precedence over the LSP source. The parameters here still need to be tuned, so please let me know if you find some magical parameters!

**Windows:** Responsible for placing the autocomplete, documentation and function parameters windows. All of the rendering can be overridden following a syntax similar to incline.nvim. It uses the neovim window decoration provider to provide next to no overhead from highlighting.

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

- Significantly less testing and documentation
- Ghost text
- Matched character highlighting
- Cmdline completions

## Special Thanks

[@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and nvim-path implementation modified for path source

[@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source

[@redxtech](https://github.com/redxtech) Help with design and testing

[@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing

[@scottmckendry](https://github.com/scottmckendry) Actively contributing to the project

[@balssh](https://github.com/Balssh) Manages nixpkg and nixvim
