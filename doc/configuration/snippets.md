---
title: Snippets
---
# Snippets<!-- panvimdoc-ignore-start --> <Badge type="info"><a href="./reference#snippets">Go to default configuration</a></Badge><!-- panvimdoc-ignore-end -->

Blink uses the `vim.snippet` API by default for expanding and navigating snippets. The built-in `snippets` source will load [friendly-snippets](https://github.com/rafamadriz/friendly-snippets), if available, and load any snippets found at `~/.config/nvim/snippets/`. For use with Luasnip, see the [Luasnip section](#luasnip).

## Custom snippets

By default, the `snippets` source will check `~/.config/nvim/snippets` for your custom snippets, but you may add additional folders via `sources.providers.snippets.opts.search_paths`. Currently, only VSCode style snippets are supported, but you may look into [Luasnip](https://github.com/L3MON4D3/LuaSnip) if you'd like more advanced functionality. If you're coming from snipmate snippets, [nadiamoe](https://github.com/nadiamoe) wrote [a small tool for converting them to JSON](https://github.com/nadiamoe/snipmate-to-json) (here be dragons! [original discussion](https://github.com/Saghen/blink.cmp/discussions/654#discussioncomment-12083447))

There's a great introduction to writing custom snippets [in the nvim-scissors repo](https://github.com/chrisgrieser/nvim-scissors?tab=readme-ov-file#cookbook--faq). Here's an example, using the linux/mac path for the neovim configuration:

```jsonc
// ~/.config/nvim/snippets/package.json
{
  "name": "personal-snippets",
  "contributes": {
    "snippets": [
      { "language": "lua", "path": "./lua.json" }
      { "language": ["typescriptreact", "javascriptreact"], "path": "./react.json" }
      { "language": "all", "path": "./all.json" }
    ]
  }
}
```

```jsonc
// ~/.config/nvim/snippets/lua.json
{
  "foo": {
    "prefix": "foo",
    "body": [
      "local ${1:foo} = ${2:bar}",
      "return ${3:baz}"
    ]
  }
}
```

## Luasnip

```lua
{
  'saghen/blink.cmp',
  version = '1.*',
  -- `main` is untested, please open a PR if you've confirmed it works as expected
  dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },
  opts = {
    snippets = { preset = 'luasnip' },
    -- ensure you have the `snippets` source (enabled by default)
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  }
}
```

## `mini.snippets`

```lua
{
  'saghen/blink.cmp',
  dependencies = 'echasnovski/mini.snippets',
  opts = {
    snippets = { preset = 'mini_snippets' },
    -- ensure you have the `snippets` source (enabled by default)
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  }
}
```

## Disable all snippets

```lua
sources.transform_items = function(_, items)
  return vim.tbl_filter(function(item)
    return item.kind ~= require('blink.cmp.types').CompletionItemKind.Snippet
  end, items)
end
```

When setting up your capabilities with `lspconfig`, add the following:

```lua
capabilities = require('blink.cmp').get_lsp_capabilities({
  textDocument = { completion = { completionItem = { snippetSupport = false } } },
})
```

Some LSPs may ignore the `snippetSupport` field, in which case, you need to set LSP specific options while setting them up. Some examples:

```lua
-- If you're using `opts = { ['rust-analyzer'] = { } }` in your lspconfig configuration, simply put these options in there instead

-- For `rust-analyzer`
lspconfig['rust-analyzer'].setup({
  completion = {
    capable = {
      snippets = 'add_parenthesis'
    }
  }
})

-- For `lua_ls`
lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Disable',
        keywordSnippet = 'Disable',
      }
    }
  }
})
```

Please open a PR if you know of any other LSPs that require special configuration!
