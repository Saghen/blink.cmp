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
---
--- @field transform_items fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field min_keyword_length number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger
---
--- @field providers table<string, blink.cmp.SourceProviderConfig>

--- @class blink.cmp.SourceProviderConfig
--- @field name string
--- @field module string
--- @field enabled? boolean | fun(): boolean Whether or not to enable the provider
--- @field opts? table
--- @field async? boolean | fun(ctx: blink.cmp.Context): boolean Whether blink should wait for the source to return before showing the completions
--- @field timeout_ms? number | fun(ctx: blink.cmp.Context): number How long to wait for the provider to return before showing completions and treating it as asynchronous
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

    transform_items = function(_, items) return items end,
    min_keyword_length = 0,

    providers = {
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',
        fallbacks = { 'buffer' },
        transform_items = function(_, items)
          -- filter out text items, since we have the buffer source
          return vim.tbl_filter(
            function(item) return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text end,
            items
          )
        end,
      },
      path = {
        name = 'Path',
        module = 'blink.cmp.sources.path',
        score_offset = 3,
        fallbacks = { 'buffer' },
      },
      snippets = {
        name = 'Snippets',
        module = 'blink.cmp.sources.snippets',
        score_offset = -3,
      },
      buffer = {
        name = 'Buffer',
        module = 'blink.cmp.sources.buffer',
        score_offset = -3,
      },
      cmdline = {
        name = 'cmdline',
        module = 'blink.cmp.sources.cmdline',
      },
      omni = {
        name = 'Omni',
        module = 'blink.cmp.sources.omni',
      },
      -- NOTE: in future we may want a built-in terminal source. For now
      -- the infrastructure exists, e.g. so community terminal sources can be
      -- added, but this functionality is not baked into blink.cmp.
      -- term = {
      --   name = 'term',
      --   module = 'blink.cmp.sources.term',
      -- },
    },
  },
}

function sources.validate(config)
  assert(
    config.completion == nil,
    '`sources.completion.enabled_providers` has been replaced with `sources.default`. !!Note!! Be sure to update `opts_extend` as well if you have it set'
  )
  assert(config.cmdline == nil, '`sources.cmdline` has been replaced with `cmdline.sources`')
  assert(config.term == nil, '`sources.term` has been replaced with `term.sources`')

  validate('sources', {
    default = { config.default, { 'function', 'table' } },
    per_filetype = { config.per_filetype, 'table' },

    transform_items = { config.transform_items, 'function' },
    min_keyword_length = { config.min_keyword_length, { 'number', 'function' } },

    providers = { config.providers, 'table' },
  }, config)
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
    async = { provider.async, { 'boolean', 'function' }, true },
    timeout_ms = { provider.timeout_ms, { 'number', 'function' }, true },
    transform_items = { provider.transform_items, 'function', true },
    should_show_items = { provider.should_show_items, { 'boolean', 'function' }, true },
    max_items = { provider.max_items, { 'number', 'function' }, true },
    min_keyword_length = { provider.min_keyword_length, { 'number', 'function' }, true },
    fallbacks = { provider.fallback_for, { 'table', 'function' }, true },
    score_offset = { provider.score_offset, { 'number', 'function' }, true },
    deduplicate = { provider.deduplicate, 'table', true },
    override = { provider.override, 'table', true },
  }, provider)
end

return sources
