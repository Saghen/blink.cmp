--- @class blink.cmp.SourceConfig
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
--- @field default string[] | fun(): string[]
--- @field per_filetype table<string, string[] | fun(): string[]>
--- @field cmdline string[] | fun(): string[]
--- @field providers table<string, blink.cmp.SourceProviderConfig>

--- @class blink.cmp.SourceProviderConfig
--- @field name? string
--- @field module? string
--- @field enabled? boolean | fun(ctx?: blink.cmp.Context): boolean Whether or not to enable the provider
--- @field opts? table
--- @field async? boolean Whether blink should wait for the source to return before showing the completions
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field should_show_items? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether or not to show the items
--- @field max_items? number | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): number Maximum number of items to display in the menu
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger the provider
--- @field fallbacks? string[] | fun(ctx: blink.cmp.Context, enabled_sources: string[]): string[] If this provider returns 0 items, it will fallback to these providers
--- @field score_offset? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number Boost/penalize the score of the items
--- @field deduplicate? blink.cmp.DeduplicateConfig TODO: implement
--- @field override? blink.cmp.SourceOverride Override the source's functions

local validate = require('blink.cmp.config.utils').validate
local sources = {
  --- @type blink.cmp.SourceConfig
  default = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    per_filetype = {},
    cmdline = function()
      local type = vim.fn.getcmdtype()
      -- Search forward and backward
      if type == '/' or type == '?' then return { 'buffer' } end
      -- Commands
      if type == ':' then return { 'cmdline' } end
      return {}
    end,
    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',
        fallbacks = { 'buffer' },
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
      },
      cmdline = {
        name = 'cmdline',
        module = 'blink.cmp.sources.cmdline',
      },
    },
  },
}

function sources.validate(config)
  validate('sources', {
    default = { config.default, { 'function', 'table' } },
    per_filetype = { config.per_filetype, 'table' },
    cmdline = { config.cmdline, { 'function', 'table' } },
    providers = { config.providers, 'table' },
  })
  assert(
    config.completion == nil,
    '`sources.completion.enabled_providers` has been replaced with `sources.default`. !!Note!! Be sure to update `opts_extend` as well if you have it set'
  )
  for id, provider in pairs(config.providers) do
    sources.validate_provider(id, provider)
  end
end

function sources.validate_provider(id, provider)
  assert(
    provider.fallback_for == nil,
    '`fallback_for` has been replaced with `fallbacks` which work in the opposite direction. For example, fallback_for = { "lsp" } on "buffer" would now be "fallbacks" = { "buffer" } on "lsp"'
  )

  validate('sources.providers.' .. id, {
    name = { provider.name, 'string' },
    module = { provider.module, 'string' },
    enabled = { provider.enabled, { 'boolean', 'function' }, true },
    opts = { provider.opts, 'table', true },
    transform_items = { provider.transform_items, 'function', true },
    should_show_items = { provider.should_show_items, { 'boolean', 'function' }, true },
    max_items = { provider.max_items, { 'number', 'function' }, true },
    min_keyword_length = { provider.min_keyword_length, { 'number', 'function' }, true },
    fallbacks = { provider.fallback_for, { 'table', 'function' }, true },
    score_offset = { provider.score_offset, { 'number', 'function' }, true },
    deduplicate = { provider.deduplicate, 'table', true },
    override = { provider.override, 'table', true },
  })
end

return sources
