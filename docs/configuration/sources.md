---
title: Sources
---
# Sources <Badge type="info"><a href="./reference#sources">Go to default configuration</a></Badge>

> [!NOTE]
> Check out the [recipes](../recipes.md) for some common configurations

Blink provides a sources interface, modelled after LSPs, for getting completion items, trigger characters, documentation and signature help. The `lsp`, `path`, `snippets`, `luasnip`, `buffer`, and `omni` sources are built-in. You may add additional [community sources](#community-sources) as well. Check out [writing sources](../development/writing-sources.md) to learn how to write your own!

## Providers

Sources are configured via the `sources.providers` table, where each `id` (`key`) must have a `name` and `module` field. The `id` (`key`) may be used in the `sources.default/per_filetype/cmdline` to enable the source.

```lua
sources = {
  default = { 'lsp' },
  providers = {
    lsp = {
      name = 'LSP',
      module = 'blink.cmp.sources.lsp',
    }
  }
}
```

### Provider options

All of the fields shown below apply to all sources. The `opts` field is passed to the source directly, and will vary by source.

```lua
sources.providers.lsp = {
  name = 'LSP',
  module = 'blink.cmp.sources.lsp',
  opts = {} -- Passed to the source directly, varies by source

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
}
```

## Terminal and Cmdline Sources

> [!NOTE]
> Terminal completions are nightly only! Known bugs in v0.10. Cmdline completions are supported on all versions

You may use `cmdline` and `term` sources via the `sources.cmdline` and `sources.term` tables. You may see the defaults in the [reference](./reference.md#sources). There's no source for shell completions at the moment, [contributions welcome](https://github.com/Saghen/blink.cmp/issues/1149)! 

## Using `nvim-cmp` sources

Blink can use `nvim-cmp` sources through a compatibility layer developed by [stefanboca](https://github.com/stefanboca): [blink.compat](https://github.com/Saghen/blink.compat). Please open any issues with `blink.compat` in that repo

## Checking status of sources providers

The command `:BlinkCmp status` can be used to view which sources providers are enabled or not enabled.

## Community sources

- [lazydev](https://github.com/folke/lazydev.nvim)
- [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)
- [blink-ripgrep](https://github.com/mikavilpas/blink-ripgrep.nvim)
- [blink-cmp-ripgrep](https://github.com/niuiic/blink-cmp-rg.nvim)
- [blink-cmp-ctags](https://github.com/netmute/blink-cmp-ctags)
- [blink-copilot](https://github.com/fang2hou/blink-copilot)
- [blink-cmp-copilot](https://github.com/giuxtaposition/blink-cmp-copilot)
- [minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim)
- [blink-emoji.nvim](https://github.com/moyiz/blink-emoji.nvim)
- [blink-nerdfont.nvim](https://github.com/MahanRahmati/blink-nerdfont.nvim)
- [blink-cmp-dictionary](https://github.com/Kaiser-Yang/blink-cmp-dictionary)
- [blink-cmp-git](https://github.com/Kaiser-Yang/blink-cmp-git)
- [blink-cmp-spell](https://github.com/ribru17/blink-cmp-spell.git)
- [css-vars.nvim](https://github.com/jdrupal-dev/css-vars.nvim)
- [blink-cmp-env](https://github.com/bydlw98/blink-cmp-env)
