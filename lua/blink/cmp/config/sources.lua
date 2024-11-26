--- @class blink.cmp.SourceConfig
--- @field completion blink.cmp.SourceModeConfig
--- @field providers table<string, blink.cmp.SourceProviderConfig>

--- @class blink.cmp.SourceModeConfig
--- @field enabled_providers string[] | fun(ctx?: blink.cmp.Context): string[]

local validate = require('blink.cmp.config.utils').validate
local sources = {
  --- @type blink.cmp.SourceConfig
  default = {
    completion = {
      enabled_providers = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',
      },
      path = {
        name = 'Path',
        module = 'blink.cmp.sources.path',
        score_offset = 3,
      },
      snippets = {
        name = 'Snippets',
        module = 'blink.cmp.sources.snippets',
        score_offset = -3,
      },
      buffer = {
        name = 'Buffer',
        module = 'blink.cmp.sources.buffer',
        fallback_for = { 'lsp' },
      },
    },
  },
}

function sources.validate(config)
  validate('sources', {
    completion = { config.completion, 'table' },
    providers = { config.providers, 'table' },
  })
  validate('sources.completion', {
    enabled_providers = { config.completion.enabled_providers, 'table' },
  })
  for key, provider in pairs(config.providers) do
    validate('sources.providers.' .. key, {
      name = { provider.name, 'string' },
      module = { provider.module, 'string' },
      enabled = { provider.enabled, 'boolean', true },
      opts = { provider.opts, 'table', true },
      transform_items = { provider.transform_items, 'function', true },
      should_show_items = { provider.should_show_items, { 'boolean', 'function' }, true },
      max_items = { provider.max_items, { 'number', 'function' }, true },
      min_keyword_length = { provider.min_keyword_length, { 'number', 'function' }, true },
      fallback_for = { provider.fallback_for, { 'table', 'function' }, true },
      score_offset = { provider.score_offset, { 'number', 'function' }, true },
      deduplicate = { provider.deduplicate, 'table', true },
      override = { provider.override, 'table', true },
    })
  end
end

return sources
