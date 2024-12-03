--- @class blink.cmp.SourceConfig
--- @field completion blink.cmp.SourceModeConfig
--- @field providers table<string, blink.cmp.SourceProviderConfig>

--- @class blink.cmp.SourceModeConfig
--- Static list of providers to enable, or a function to dynamically enable/disable providers based on the context
---
--- Example dynamically picking providers based on the filetype and treesitter node:
--- ```lua
---   function(ctx)
---     local node = vim.treesitter.get_node()
---     if vim.bo.filetype == 'lua' then
---       return { 'lsp', 'path' }
---     elseif node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }), node:type())
---       return { 'buffer' }
---     else
---       return { 'lsp', 'path', 'snippets', 'buffer' }
---     end
---   end
--- ```
--- @field enabled_providers string[] | fun(ctx?: blink.cmp.Context): string[]

--- @class blink.cmp.SourceProviderConfig
--- @field name? string
--- @field module? string
--- @field enabled? boolean | fun(ctx?: blink.cmp.Context): boolean Whether or not to enable the provider
--- @field opts? table
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field should_show_items? boolean | number | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether or not to show the items
--- @field max_items? number | fun(ctx: blink.cmp.Context, enabled_sources: string[], items: blink.cmp.CompletionItem[]): number Maximum number of items to display in the menu
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number Minimum number of characters in the keyword to trigger the provider
--- @field fallback_for? string[] | fun(ctx: blink.cmp.Context, enabled_sources: string[]): string[] If any of these providers return 0 items, it will fallback to this provider
--- @field score_offset? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number Boost/penalize the score of the items
--- @field deduplicate? blink.cmp.DeduplicateConfig TODO: implement
--- @field override? blink.cmp.SourceOverride Override the source's functions

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
      luasnip = {
        name = 'Luasnip',
        module = 'blink.cmp.sources.luasnip',
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
    enabled_providers = { config.completion.enabled_providers, { 'table', 'function' } },
  })
  for key, provider in pairs(config.providers) do
    validate('sources.providers.' .. key, {
      name = { provider.name, 'string' },
      module = { provider.module, 'string' },
      enabled = { provider.enabled, { 'boolean', 'function' }, true },
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
