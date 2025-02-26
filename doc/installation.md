# Installation

::: warning
Blink uses a prebuilt binary for the fuzzy matcher which will be downloaded automatically when on a tag.
You may build from source with rust nightly or use the lua implementation. See the [fuzzy documentation](./configuration/fuzzy.md) for more information.
:::

## Requirements

- Neovim 0.10+
- Using prebuilt binaries:
  - curl
  - git
- Building from source:
  - Rust nightly or [rustup](https://rustup.rs/)

Note: By default, Blink will attempt to use the rust implementation of the fuzzy matcher. However, the lua implementation does not require any of these dependencies. See the [fuzzy documentation](./configuration/fuzzy.md) for more information.

## `lazy.nvim`

```lua
{
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = 'rafamadriz/friendly-snippets',

  -- use a release tag to download pre-built binaries
  version = '*',
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept, C-n/C-p for up/down)
    -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys for up/down)
    -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-e: Hide menu
    -- C-k: Toggle signature help
    --
    -- See the full "keymap" documentation for information on defining your own keymap.
    keymap = { preset = 'default' },

    appearance = {
      -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      -- Useful for when your theme doesn't support blink.cmp
      -- Will be removed in a future release
      use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono'
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    -- Blink.cmp uses a Rust fuzzy matcher by default for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
```

::: warning
On Neovim 0.11+ and Blink.cmp 0.10+ with `vim.lsp.config`, you may skip this step.
This is still required when using `nvim-lspconfig` until [this issue is completed](https://github.com/neovim/nvim-lspconfig/issues/3494)
:::

Setting capabilities for `nvim-lspconfig`:

```lua
-- LSP servers and clients communicate which features they support through "capabilities".
--  By default, Neovim supports a subset of the LSP specification.
--  With blink.cmp, Neovim has _more_ capabilities which are communicated to the LSP servers.
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

    lspconfig['lua_ls'].setup({ capabilities = capabilities })
  end
}
```

## `mini.deps`

The following section includes only the installation and, optionally, building of the fuzzy matcher. Check the [lazy.nvim](#lazy.nvim) section for recommended configuration options and setting up `nvim-lspconfig`.

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
