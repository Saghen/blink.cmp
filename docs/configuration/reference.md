# Reference

> [!IMPORTANT]
> Do not copy the default configuration! Only include options you want to change in your configuration
```lua
-- Enables keymaps, completions and signature help when true
enabled = function() return vim.bo.buftype ~= "prompt" and vim.b.completion ~= false end,

-- See the "keymap" page for more information
keymap = 'default',
```

## Snippets

```lua
snippets = {
  -- Function to use when expanding LSP provided snippets
  expand = function(snippet) vim.snippet.expand(snippet) end,
  -- Function to use when checking if a snippet is active
  active = function(filter) return vim.snippet.active(filter) end,
  -- Function to use when jumping between tab stops in a snippet, where direction can be negative or positive
  jump = function(direction) vim.snippet.jump(direction) end,
}
```

## Completion

### Completion Keyword

```lua
completion.keyword = {
  -- 'prefix' will fuzzy match on the text before the cursor
  -- 'full' will fuzzy match on the text before *and* after the cursor
  -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
  range = 'prefix',
  -- Regex used to get the text when fuzzy matching
  regex = '[-_]\\|\\k',
  -- After matching with regex, any characters matching this regex at the prefix will be excluded
  exclude_from_prefix_regex = '[\\-]',
}
```

### Completion Trigger

```lua
completion.trigger = {
  -- When true, will prefetch the completion items when entering insert mode
  prefetch_on_insert = false,

  -- When false, will not show the completion window automatically when in a snippet
  show_in_snippet = true,

  -- When true, will show the completion window after typing any of alphanumerics, `-` or `_`
  show_on_keyword = true,

  -- When true, will show the completion window after typing a trigger character
  show_on_trigger_character = true,
  
  -- LSPs can indicate when to show the completion window via trigger characters
  -- however, some LSPs (i.e. tsserver) return characters that would essentially
  -- always show the window. We block these by default.
  show_on_blocked_trigger_characters = function()
    if vim.api.nvim_get_mode().mode == 'c' then return {} end

    -- you can also block per filetype, for example:
    -- if vim.bo.filetype == 'markdown' then
    --   return { ' ', '\n', '\t', '.', '/', '(', '[' }
    -- end

    return { ' ', '\n', '\t' }
  end,

  -- When both this and show_on_trigger_character are true, will show the completion window
  -- when the cursor comes after a trigger character after accepting an item
  show_on_accept_on_trigger_character = true,

  -- When both this and show_on_trigger_character are true, will show the completion window
  -- when the cursor comes after a trigger character when entering insert mode
  show_on_insert_on_trigger_character = true,

  -- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
  -- the completion window when the cursor comes after a trigger character when
  -- entering insert mode/accepting an item
  show_on_x_blocked_trigger_characters = { "'", '"', '(' },
  -- or a function, similar to show_on_blocked_trigger_character
}
```

### Completion List

```lua
completion.list = {
  -- Maximum number of items to display
  max_items = 200,

  -- Controls if completion items will be selected automatically,
  -- and whether selection automatically inserts
  selection = 'preselect',
  -- selection = function(ctx) return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect' end,

  -- Controls how the completion items are selected
  -- 'preselect' will automatically select the first item in the completion list
  -- 'manual' will not select any item by default
  -- 'auto_insert' will not select any item by default, and insert the completion items automatically when selecting them
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
```

### Completion Accept

```lua
completion.accept = {
  -- Create an undo point when accepting a completion item
  create_undo_point = true,
  -- Experimental auto-brackets support
  auto_brackets = {
    -- Whether to auto-insert brackets for functions
    enabled = true,
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
      blocked_filetypes = { 'java' },
      -- How long to wait for semantic tokens to return before assuming no brackets should be added
      timeout_ms = 400,
    },
  },
},
```

### Completion Menu

```lua
completion.menu = {
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

  -- Whether to automatically show the window when new completion items are available
  auto_show = true,

  -- Screen coordinates of the command line
  cmdline_position = function()
    if vim.g.ui_cmdline_pos ~= nil then
      local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
      return { pos[1] - 1, pos[2] }
    end
    local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
    return { vim.o.lines - height, 0 }
  end,
}
```

### Completion Menu Draw

```lua
-- Controls how the completion items are rendered on the popup window
completion.menu.draw = {
  -- Aligns the keyword you've typed to a component in the menu
  align_to = 'label', -- or 'none' to disable, or 'cursor' to align to the cursor
  -- Left and right padding, optionally { left, right } for different padding on each side
  padding = 1,
  -- Gap between columns
  gap = 1,
  -- Use treesitter to highlight the label text for the given list of sources
  treesitter = {},
  -- treesitter = { 'lsp' }

  -- Components to render, grouped by column
  columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },

  -- Definitions for possible components to render. Each defines:
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
      text = function(ctx) return ctx.source_name end,
      highlight = 'BlinkCmpSource',
    },
  },
},
```

### Completion Documentation

```lua
completion.documentation = {
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
    max_width = 80,
    max_height = 20,
    border = 'padded',
    winblend = 0,
    winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
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
}
```

### Completion Ghost Text

```lua
-- Displays a preview of the selected item on the current line
completion.ghost_text = {
  enabled = false,
},
```

## Signature

```lua
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
}
```

## Fuzzy

```lua
fuzzy = {
  -- When enabled, allows for a number of typos relative to the length of the query
  -- Disabling this matches the behavior of fzf
  use_typo_resistance = true,
  -- Frecency tracks the most recently/frequently used items and boosts the score of the item
  use_frecency = true,
  -- Proximity bonus boosts the score of items matching nearby words
  use_proximity = true,
  -- UNSAFE!! When enabled, disables the lock and fsync when writing to the frecency database. This should only be used on unsupported platforms (i.e. alpine termux)
  use_unsafe_no_lock = false,
  -- Controls which sorts to use and in which order, falling back to the next sort if the first one returns nil
  -- You may pass a function instead of a string to customize the sorting
  sorts = { 'score', 'sort_text' },

  prebuilt_binaries = {
    -- Whether or not to automatically download a prebuilt binary from github. If this is set to `false`
    -- you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
    download = true,
    -- Ignores mismatched version between the built binary and the current git sha, when building locally
    ignore_version_mismatch = false,
    -- When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset
    -- then the downloader will attempt to infer the version from the checked out git tag (if any).
    --
    -- Beware that if the fuzzy matcher changes while tracking main then this may result in blink breaking.
    force_version = nil,
    -- When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset
    -- then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`.
    -- Check the latest release for all available system triples
    --
    -- Beware that if the fuzzy matcher changes while tracking main then this may result in blink breaking.
    force_system_triple = nil,
    -- Extra arguments that will be passed to curl like { 'curl', ..extra_curl_args, ..built_in_args }
    extra_curl_args = {}
  },
}
```

## Sources

```lua
sources = {
  -- Static list of providers to enable, or a function to dynamically enable/disable providers based on the context
  default = { 'lsp', 'path', 'snippets', 'buffer' },
  
  -- You may also define providers per filetype
  per_filetype = {
    -- lua = { 'lsp', 'path' },
  },

  -- By default, we choose providers for the cmdline based on the current cmdtype
  -- You may disable cmdline completions by replacing this with an empty table
  cmdline = function()
    local type = vim.fn.getcmdtype()
    -- Search forward and backward
    if type == '/' or type == '?' then return { 'buffer' } end
    -- Commands
    if type == ':' or type == '@' then return { 'cmdline' } end
    return {}
  end,

  -- Function to use when transforming the items before they're returned for all providers
  -- The default will lower the score for snippets to sort them lower in the list
  transform_items = function(_, items) return items end,

  -- Minimum number of characters in the keyword to trigger all providers
  -- May also be `function(ctx: blink.cmp.Context): number`
  min_keyword_length = 0,
}
```

### Providers

```lua
-- Please see https://github.com/Saghen/blink.compat for using `nvim-cmp` sources
sources.providers = {
  lsp = {
    name = 'LSP',
    module = 'blink.cmp.sources.lsp',
    fallbacks = { 'buffer' },
    -- Filter text items from the LSP provider, since we have the buffer provider for that
    transform_items = function(_, items)
      for _, item in ipairs(items) do
        if item.kind == require('blink.cmp.types').CompletionItemKind.Snippet then
          item.score_offset = item.score_offset - 3
        end
      end

      return vim.tbl_filter(
        function(item) return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text end,
        items
      )
    end,

    --- NOTE: All of these options may be functions to get dynamic behavior
    --- See the type definitions for more information
    enabled = true, -- Whether or not to enable the provider
    async = false, -- Whether we should wait for the provider to return before showing the completions
    timeout_ms = 2000, -- How long to wait for the provider to return before showing completions and treating it as asynchronous
    transform_items = nil, -- Function to transform the items before they're returned
    should_show_items = true, -- Whether or not to show the items
    max_items = nil, -- Maximum number of items to display in the menu
    min_keyword_length = 0, -- Minimum number of characters in the keyword to trigger the provider
    -- If this provider returns 0 items, it will fallback to these providers.
    -- If multiple providers falback to the same provider, all of the providers must return 0 items for it to fallback
    fallbacks = {},
    score_offset = 0, -- Boost/penalize the score of the items
    override = nil, -- Override the source's functions
  },
  path = {
    name = 'Path',
    module = 'blink.cmp.sources.path',
    score_offset = 3,
    fallbacks = { 'buffer' },
    opts = {
      trailing_slash = true,
      label_trailing_slash = true,
      get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
      show_hidden_files_by_default = false,
    }
  },
  snippets = {
    name = 'Snippets',
    module = 'blink.cmp.sources.snippets',
    opts = {
      friendly_snippets = true,
      search_paths = { vim.fn.stdpath('config') .. '/snippets' },
      global_snippets = { 'all' },
      extended_filetypes = {},
      ignored_filetypes = {},
      get_filetype = function(context)
        return vim.bo.filetype
      end
      -- Set to '+' to use the system clipboard, or '"' to use the unnamed register
      clipboard_register = nil,
    }
  },
  luasnip = {
    name = 'Luasnip',
    module = 'blink.cmp.sources.luasnip',
    opts = {
      -- Whether to use show_condition for filtering snippets
      use_show_condition = true,
      -- Whether to show autosnippets in the completion list
      show_autosnippets = true,
    }
  },
  buffer = {
    name = 'Buffer',
    module = 'blink.cmp.sources.buffer',
    opts = {
      -- default to all visible buffers
      get_bufnrs = function()
        return vim
          .iter(vim.api.nvim_list_wins())
          :map(function(win) return vim.api.nvim_win_get_buf(win) end)
          :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
          :totable()
      end,
    }
  },
}
```

## Appearance

```lua
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
}
```
