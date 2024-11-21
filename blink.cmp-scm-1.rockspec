local MODREV, SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'blink.cmp'
version = MODREV .. SPECREV

description = {
  summary = 'Performant, batteries-included completion plugin for Neovim',
  labels = { 'neovim' },
  homepage = 'https://github.com/Saghen/blink.cmp',
  license = 'MIT',
}

source = {
  url = 'https://github.com/Saghen/blink.cmp/archive/v' .. MODREV .. '.zip',
}

if MODREV == 'scm' then source = {
  url = 'git://github.com/Saghen/blink.cmp',
} end

dependencies = {
  'lua == 5.1',
}

test_dependencies = {
  'nlua', -- neovim lua interpreter
}

build_dependencies = {
  'luarocks-build-rust-mlua',
}

build = {
  type = 'rust-mlua',
  modules = {
    'blink_cmp_fuzzy',
  },
  install = {
    lua = {
      ['blink-cmp.init'] = 'lua/blink-cmp.lua',
    },
  },
  default_features = false,
  features = { 'lua51' },
}
