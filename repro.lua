-- Run with `nvim -u repro.lua`
--
-- Please update the code below to reproduce your issue and send the updated code, with reproduction
--  steps, in your issue report
--
-- If you get warnings about prebuilt binaries, you may use `fuzzy.implementation = 'lua'`
--  but note this has caveats: https://cmp.saghen.dev/configuration/fuzzy#rust-vs-lua-implementation

vim.env.LAZY_STDPATH = '.repro'
load(vim.fn.system('curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'))()

---@diagnostic disable-next-line: missing-fields
require('lazy.minit').repro({
  spec = {
    {
      'saghen/blink.cmp',
      -- please test on `main` if possible
      -- otherwise, remove this line and set `version = '*'`
      build = 'cargo build --release',
      opts = {},
    },
    {
      'mason-org/mason.nvim',
      build = ':MasonUpdate',
      opts = {},
    },
    {
      'mason-org/mason-lspconfig.nvim',
      dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
      opts = {
        ensure_installed = { 'lua_ls' },
      },
    },
  },
})
