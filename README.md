# Blink Completion (blink.cmp)

**blink.cmp** is a completion plugin with support for LSPs and external sources while updating on every keystroke with minimal overhead (0.5-4ms async). It achieves this by writing the fuzzy searching in SIMD to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going.

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms non-blocking, single core)
- Typo resistant fuzzy with frecency and proximity bonus
- Extensive LSP support ([tracker](./LSP_TRACKER.md))
- Native `vim.snippet` support (including `friendly-snippets`)
- External sources support (currently incompatible with `nvim-cmp` sources)
- Auto-bracket support based on semantic tokens (experimental, opt-in)
- Signature help (experimental, opt-in)
- [Comparison with nvim-cmp](#compared-to-nvim-cmp)

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

  opts = {
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
<summary>Default configuration</summary>

<!-- config:start -->

```lua
{
  -- for keymap, all values may be string | string[]
  -- use an empty table to disable a keymap
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

  accept = {
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
        blocked_filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'vue' },
      },
      -- Asynchronously use semantic token to determine if brackets should be added
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = {},
      },
    },
  },

  trigger = {
    completion = {
      -- regex used to get the text when fuzzy matching
      -- changing this may break some sources, so please report if you run into issues
      -- todo: shouldnt this also affect the accept command? should this also be per language?
      context_regex = '[%w_\\-]',
      -- LSPs can indicate when to show the completion window via trigger characters
      -- however, some LSPs (*cough* tsserver *cough*) return characters that would essentially
      -- always show the window. We block these by default
      blocked_trigger_characters = { ' ', '\n', '\t' },
      -- when true, will show the completion window when the cursor comes after a trigger character when entering insert mode
      show_on_insert_on_trigger_character = true,
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
  },

  sources = {
    -- similar to nvim-cmp's sources, but we point directly to the source's lua module
    -- multiple groups can be provided, where it'll fallback to the next group if the previous
    -- returns no completion items
    providers = {
      {
        { 'blink.cmp.sources.lsp' },
        { 'blink.cmp.sources.path' },
        { 'blink.cmp.sources.snippets', score_offset = -3 },
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
      -- which directions to show the window,
      -- falling back to the next direction when there's not enough space
      direction_priority = { 's', 'n' },
    },
    documentation = {
      min_width = 10,
      max_width = 60,
      max_height = 20,
      border = 'padded',
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
```

<!-- config:end -->

</details>

## How it works

The plugin use a 4 stage pipeline: trigger -> sources -> fuzzy -> render

**Trigger:** Controls when to request completion items from the sources and provides a context downstream with the current query (i.e. `hello.wo|`, the query would be `wo`) and the treesitter object under the cursor (i.e. for intelligently enabling/disabling sources). It respects trigger characters passed by the LSP (or any other source) and includes it in the context for sending to the LSP.

**Sources:** Provides a common interface for and merges the results of completion, trigger character, resolution of additional information and cancellation. Some sources are builtin: `LSP`, `buffer`, `path`, `snippets`

**Fuzzy:** Rust <-> Lua FFI which performs both filtering and sorting of the items

&nbsp;&nbsp;&nbsp;&nbsp;**Filtering:** The fuzzy matching uses smith-waterman, same as FZF, but implemented in SIMD for ~6x the performance of FZF (todo: add benchmarks). Due to the SIMD's performance, the prefiltering phase on FZF was dropped to allow for typos. Similar to fzy/fzf, additional points are given to prefix matches, characters with capitals (to promote camelCase/PascalCase first char matching) and matches after delimiters (to promote snake_case first char matching)

&nbsp;&nbsp;&nbsp;&nbsp;**Sorting:** Combines fuzzy matching score with frecency and proximity bonus. Each completion item may also include a `score_offset` which will be added to this score to demote certain sources. The `snippets` source takes advantage of this to avoid taking presedence over the LSP source. The paramaters here still need to be tuned, so please let me know if you find some magical parameters!

**Windows:** Responsible for placing the autocomplete, documentation and function parameters windows. All of the rendering can be overriden following a syntax similar to incline.nvim. It uses the neovim window decoration provider to provide next to no overhead from highlighting.

## Compared to nvim-cmp

### Advantages

- Avoids the complexity of nvim-cmp's configuration by providing sensible defaults
- Updates on every keystroke with 0.5-4ms of overhead, versus nvim-cmp's default debounce of 60ms with 2-50ms hitches from processing
    - Setting nvim-cmp's debounce to 0ms leads to visible stuttering. If you'd like to stick with nvim-cmp, try [yioneko's fork](https://github.com/yioneko/nvim-cmp)
- Boosts completion item score via frecency *and* proximity bonus. nvim-cmp only boosts score via proximity bonus and optionally by recency
- Typo-resistant fuzzy matching unlike nvim-cmp's fzf-style fuzzy matching
- Core sources (buffer, snippets, path, lsp) are built-in versus nvim-cmp's exclusively external sources

### Planned missing features

- Less customizable across the board wrt trigger, sources, sorting, filtering, and rendering
- Significantly less testing and documentation
- Ghost text
- Matched character highlighting

### Missing features, not planned

- Cmdline completions

## Special Thanks

[@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and nvim-path implementation modified for path source

[@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source

[@redxtech](https://github.com/redxtech) Help with design and testing

[@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing
