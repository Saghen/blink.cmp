--- @class (exact) blink.cmp.FuzzyConfig
--- @field implementation blink.cmp.FuzzyImplementationType Controls which implementation to use for the fuzzy matcher. See the documentation for the available values for more information.
--- @field max_typos number | fun(keyword: string): number Allows for a number of typos relative to the length of the query. Set this to 0 to match the behavior of fzf. Note, this does not apply when using the Lua implementation.
--- @field use_proximity boolean Boosts the score of items matching nearby words. Note, this does not apply when using the Lua implementation.
--- @field sorts blink.cmp.Sort[] Controls which sorts to use and in which order.
--- @field frecency blink.cmp.FuzzyFrecencyConfig Tracks the most recently/frequently used items and boosts the score of the item. Note, this does not apply when using the Lua implementation.

--- @class (exact) blink.cmp.FuzzyFrecencyConfig
--- @field enabled boolean Whether to enable the frecency feature
--- @field path string Location of the frecency database

--- @alias blink.cmp.FuzzyImplementationType
--- | 'prefer_rust_with_warning' (Recommended) If available, use the Rust implementation. Fallback to the Lua implementation when not available, emitting a warning message.
--- | 'prefer_rust' If available, use the Rust implementation. Fallback to the Lua implementation when not available.
--- | 'rust' Always use the Rust implementation. Error if not available.
--- | 'lua' Always use the Lua implementation

--- @alias blink.cmp.SortFunction fun(a: blink.cmp.CompletionItem, b: blink.cmp.CompletionItem): boolean | nil
--- @alias blink.cmp.Sort ("label" | "sort_text" | "kind" | "score" | "exact" | blink.cmp.SortFunction)

local validate = require('blink.cmp.config.utils').validate

local fuzzy = {
  --- @type blink.cmp.FuzzyConfig
  default = {
    implementation = 'prefer_rust_with_warning',
    max_typos = function(keyword) return math.floor(#keyword / 4) end,
    use_proximity = true,
    sorts = { 'score', 'sort_text' },
    frecency = {
      enabled = true,
      path = vim.fn.stdpath('state') .. '/blink/cmp/frecency.dat',
    },
  },
}

function fuzzy.validate(config)
  validate('fuzzy', {
    implementation = {
      config.implementation,
      function(implementation)
        return vim.tbl_contains({ 'prefer_rust', 'prefer_rust_with_warning', 'rust', 'lua' }, implementation)
      end,
      'one of: "prefer_rust", "prefer_rust_with_warning", "rust", "lua"',
    },
    max_typos = { config.max_typos, { 'number', 'function' } },
    use_proximity = { config.use_proximity, 'boolean' },
    sorts = {
      config.sorts,
      function(sorts)
        for _, sort in ipairs(sorts) do
          if
            not vim.tbl_contains({ 'label', 'sort_text', 'kind', 'score', 'exact' }, sort)
            and type(sort) ~= 'function'
          then
            return false
          end
        end
        return true
      end,
      'one of: "label", "sort_text", "kind", "score", "exact" or a function',
    },
    frecency = { config.frecency, 'table' },
  }, config)

  validate('fuzzy.frecency', {
    enabled = { config.frecency.enabled, 'boolean' },
    path = { config.frecency.path, 'string' },
  }, config.frecency)
end

return fuzzy
