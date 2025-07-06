--- @class blink.cmp.SourceConfig
--- Static list of providers to enable, or a function to dynamically enable/disable providers based on the context
---
--- Example dynamically picking providers based on the filetype and treesitter node:
--- ```lua
---   function(ctx)
---     local node = vim.treesitter.get_node()
---     if vim.bo.filetype == 'lua' then
---       return { 'lsp', 'path' }
---     elseif node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
---       return { 'buffer' }
---     else
---       return { 'lsp', 'path', 'snippets', 'buffer' }
---     end
---   end
--- ```
--- @field default blink.cmp.SourceList
--- @field per_filetype table<string, blink.cmp.SourceListPerFiletype>
---
--- @field transform_items fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field min_keyword_length number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger
---
--- @field providers table<string, blink.cmp.SourceProviderConfig>

--- @alias blink.cmp.SourceList string[] | fun(): string[]
--- @alias blink.cmp.SourceListPerFiletype { inherit_defaults?: boolean, [number]: string } | fun(): ({ inherit_defaults?: boolean, [number]: string })

--- @class blink.cmp.SourceProviderConfig
--- @field module string
--- @field name? string
--- @field enabled? boolean | fun(): boolean Whether or not to enable the provider
--- @field opts? table
--- @field async? boolean | fun(ctx: blink.cmp.Context): boolean Whether we should show the completions before this provider returns, without waiting for it
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
      },
      path = {
        module = 'blink.cmp.sources.path',
        score_offset = 3,
        fallbacks = { 'buffer' },
      },
      snippets = {
        module = 'blink.cmp.sources.snippets',
        score_offset = -1, -- receives a -3 from top level snippets.score_offset
      },
      buffer = {
        module = 'blink.cmp.sources.buffer',
        score_offset = -3,
      },
      cmdline = {
        module = 'blink.cmp.sources.cmdline',
      },
      omni = {
        module = 'blink.cmp.sources.complete_func',
        enabled = function() return vim.bo.omnifunc ~= 'v:lua.vim.lsp.omnifunc' end,
        ---@type blink.cmp.CompleteFuncOpts
        opts = {
          complete_func = function() return vim.bo.omnifunc end,
        },
      },
      -- NOTE: in the future, we may want a built-in terminal source. For now
      -- the infrastructure exists, so community terminal sources can be
      -- added, but this functionality is not baked into blink.cmp.
      -- term = { module = 'blink.cmp.sources.term' },
    },
  },
}

function sources.validate(config)
  assert(config.cmdline == nil, '`sources.cmdline` has been replaced with `cmdline.sources`')
  assert(config.term == nil, '`sources.term` has been replaced with `term.sources`')
  assert(
    config.providers.omni.module ~= 'blink.cmp.sources.omni',
    '`blink.cmp.sources.omni` has been replaced with `blink.cmp.sources.complete_func`'
  )

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
    module = { provider.module, 'string' },
    name = { provider.name, 'string', true },
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
