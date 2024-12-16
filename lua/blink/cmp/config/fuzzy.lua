--- @class (exact) blink.cmp.FuzzyConfig
--- @field use_typo_resistance boolean When enabled, allows for a number of typos relative to the length of the query. Disabling this matches the behavior of fzf
--- @field use_frecency boolean Tracks the most recently/frequently used items and boosts the score of the item
--- @field use_proximity boolean Boosts the score of items matching nearby words
--- @field sorts ("label" | "sort_text" | "kind" | "score" | blink.cmp.SortFunction)[] Controls which sorts to use and in which order, these three are currently the only allowed options
--- @field prebuilt_binaries blink.cmp.PrebuiltBinariesConfig

--- @class (exact) blink.cmp.PrebuiltBinariesConfig
--- @field download boolean Whenther or not to automatically download a prebuilt binary from github. If this is set to `false` you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
--- @field force_version? string When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset then the downloader will attempt to infer the version from the checked out git tag (if any). WARN: Beware that `main` may be incompatible with the version you select
--- @field force_system_triple? string When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`. Check the latest release for all available system triples. WARN: Beware that `main` may be incompatible with the version you select
--- @field extra_curl_args? string[] Extra arguments that will be passed to curl like { 'curl', ..extra_curl_args, ..built_in_args }

--- @alias blink.cmp.SortFunction fun(a: blink.cmp.CompletionItem, b: blink.cmp.CompletionItem): boolean | nil

local validate = require('blink.cmp.config.utils').validate
local fuzzy = {
  --- @type blink.cmp.FuzzyConfig
  default = {
    use_typo_resistance = true,
    use_frecency = true,
    use_proximity = true,
    sorts = { 'score', 'sort_text' },
    prebuilt_binaries = {
      download = true,
      force_version = nil,
      force_system_triple = nil,
      extra_curl_args = {},
    },
  },
}

function fuzzy.validate(config)
  validate('fuzzy', {
    use_typo_resistance = { config.use_typo_resistance, 'boolean' },
    use_frecency = { config.use_frecency, 'boolean' },
    use_proximity = { config.use_proximity, 'boolean' },
    sorts = {
      config.sorts,
      function(sorts)
        for _, sort in ipairs(sorts) do
          if not vim.tbl_contains({ 'label', 'sort_text', 'kind', 'score' }, sort) and type(sort) ~= 'function' then
            return false
          end
        end
        return true
      end,
      'one of: "label", "sort_text", "kind", "score" or a function',
    },
    prebuilt_binaries = { config.prebuilt_binaries, 'table' },
  }, config)
  validate('fuzzy.prebuilt_binaries', {
    download = { config.prebuilt_binaries.download, 'boolean' },
    force_version = { config.prebuilt_binaries.force_version, { 'string', 'nil' } },
    force_system_triple = { config.prebuilt_binaries.force_system_triple, { 'string', 'nil' } },
    extra_curl_args = { config.prebuilt_binaries.extra_curl_args, { 'table' } },
  }, config.prebuilt_binaries)
end

return fuzzy
