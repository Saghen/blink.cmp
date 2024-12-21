# General

Blink cmp has *a lot* of configuration options, the following code block highlights some changes you're most likely to care about. For more information, check out the additional pages.

For more common configurations, see the [recipes](../recipes.md).

```lua
{
  -- Disable for some filetypes
  enabled = function()
    return not vim.tbl_contains({ "lua", "markdown" }, vim.bo.filetype)
      and vim.bo.buftype ~= "prompt"
      and vim.b.completion ~= false
  end,

  completion = {
    -- 'prefix' will fuzzy match on the text before the cursor
    -- 'full' will fuzzy match on the text before *and* after the cursor
    -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
    keyword = { range = 'full' },

    -- Disable auto brackets
    -- NOTE: some LSPs may add auto brackets themselves anyway
    accept = { auto_brackets = { enabled = false }, }

    -- Insert completion item on selection, don't select by default
    list = { selection = 'auto_insert' },

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
    -- Disable cmdline completions
    cmdline = {},
  }

  -- Experimental signature help support
  signature = { enabled = true }
}
```
