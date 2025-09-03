# General

Blink cmp has *a lot* of configuration options, the following code block highlights some changes you're most likely to care about. For more information, check out the additional pages.

For more common configurations, see the [recipes](../recipes.md).

::: warning
**Do not copy this entire configuration! It contains only non-default options**
:::

```lua
{
  -- Enables keymaps, completions and signature help when true (doesn't apply to cmdline or term)
  --
  -- If the function returns 'force', the default conditions for disabling the plugin will be ignored
  -- Default conditions: (vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false)
  -- Note that the default conditions are ignored when `vim.b.completion` is explicitly set to `true`
  --
  -- Exceptions: vim.bo.filetype == 'dap-repl'
  enabled = function() return not vim.tbl_contains({ "lua", "markdown" }, vim.bo.filetype) end,

  -- Disable cmdline
  cmdline = { enabled = false },

  completion = {
    -- 'prefix' will fuzzy match on the text before the cursor
    -- 'full' will fuzzy match on the text before _and_ after the cursor
    -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
    keyword = { range = 'full' },

    -- Disable auto brackets
    -- NOTE: some LSPs may add auto brackets themselves anyway
    accept = { auto_brackets = { enabled = false }, },

    -- Don't select by default, auto insert on selection
    list = { selection = { preselect = false, auto_insert = true } },
    -- or set via a function
    list = { selection = { preselect = function(ctx) return vim.bo.filetype ~= 'markdown' end } },

    menu = {
      -- Don't automatically show the completion menu
      auto_show = false,

      -- nvim-cmp style menu
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind" }
        },
      }
    },

    -- Show documentation when selecting a completion item
    documentation = { auto_show = true, auto_show_delay_ms = 500 },

    -- Display a preview of the selected item on the current line
    ghost_text = { enabled = true },
  },

  sources = {
    -- Remove 'buffer' if you don't want text completions, by default it's only enabled when LSP returns no items
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  -- Use a preset for snippets, check the snippets documentation for more information
  snippets = { preset = 'default' | 'luasnip' | 'mini_snippets' | 'vsnip' },

  -- Experimental signature help support
  signature = { enabled = true }
}
```
