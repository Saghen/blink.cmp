--- @class (exact) blink.cmp.FuzzyConfig
--- @field implementation blink.cmp.FuzzyImplementationType Controls which implementation to use for the fuzzy matcher. See the documentation for the available values for more information.
--- @field max_typos fun(keyword: string): number Allows for a number of typos relative to the length of the query. Set this to 0 to match the behavior of fzf. Note, this does not apply when using the Lua implementation.
--- @field use_frecency boolean Tracks the most recently/frequently used items and boosts the score of the item. Note, this does not apply when using the Lua implementation.
--- @field use_proximity boolean Boosts the score of items matching nearby words. Note, this does not apply when using the Lua implementation.
--- @field use_unsafe_no_lock boolean UNSAFE!! When enabled, disables the lock and fsync when writing to the frecency database. This should only be used on unsupported platforms (i.e. alpine termux). Note, this does not apply when using the Lua implementation.
--- @field sorts ("label" | "sort_text" | "kind" | "score" | "exact" | blink.cmp.SortFunction)[] Controls which sorts to use and in which order, these three are currently the only allowed options
--- @field prebuilt_binaries blink.cmp.PrebuiltBinariesConfig

--- @class (exact) blink.cmp.PrebuiltBinariesConfig
--- @field download boolean Whenther or not to automatically download a prebuilt binary from github. If this is set to `false`, you will need to manually build the fuzzy binary dependencies by running `cargo build --release`. Disabled by default when `fuzzy.implementation = 'lua'`
--- @field ignore_version_mismatch boolean Ignores mismatched version between the built binary and the current git sha, when building locally
--- @field force_version? string When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset then the downloader will attempt to infer the version from the checked out git tag (if any). WARN: Beware that `main` may be incompatible with the version you select
--- @field force_system_triple? string When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`. Check the latest release for all available system triples. WARN: Beware that `main` may be incompatible with the version you select
--- @field extra_curl_args string[] Extra arguments that will be passed to curl like { 'curl', ..extra_curl_args, ..built_in_args }
--- @field proxy blink.cmp.PrebuiltBinariesProxyConfig

--- @class (exact) blink.cmp.PrebuiltBinariesProxyConfig
--- @field from_env boolean When downloading a prebuilt binary, use the HTTPS_PROXY environment variable
--- @field url? string When downloading a prebuilt binary, use this proxy URL. This will ignore the HTTPS_PROXY environment variable

--- @alias blink.cmp.FuzzyImplementationType
--- | 'prefer_rust_with_warning' (Recommended) If available, use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Fallback to the Lua implementation when not available, emitting a warning message.
--- | 'prefer_rust' If available, use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Fallback to the Lua implementation when not available.
--- | 'rust' Always use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Error if not available.
--- | 'lua' Always use the Lua implementation

--- @alias blink.cmp.SortFunction fun(a: blink.cmp.CompletionItem, b: blink.cmp.CompletionItem): boolean | nil

local validate = require('blink.cmp.config.utils').validate
local fuzzy = {
  --- @type blink.cmp.FuzzyConfig
  default = {
    implementation = 'prefer_rust_with_warning',
    max_typos = function(keyword) return math.floor(#keyword / 4) end,
    use_frecency = true,
    use_proximity = true,
    use_unsafe_no_lock = false,
    sorts = { 'score', 'sort_text' },
    prebuilt_binaries = {
      download = true,
      ignore_version_mismatch = false,
      force_version = nil,
      force_system_triple = nil,
      extra_curl_args = {},
      proxy = {
        from_env = true,
        url = nil,
      },
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
    max_typos = { config.max_typos, 'function' },
    use_frecency = { config.use_frecency, 'boolean' },
    use_proximity = { config.use_proximity, 'boolean' },
    use_unsafe_no_lock = { config.use_unsafe_no_lock, 'boolean' },
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
    prebuilt_binaries = { config.prebuilt_binaries, 'table' },
  }, config)

  validate('fuzzy.prebuilt_binaries', {
    download = { config.prebuilt_binaries.download, 'boolean' },
    ignore_version_mismatch = { config.prebuilt_binaries.ignore_version_mismatch, 'boolean' },
    force_version = { config.prebuilt_binaries.force_version, { 'string', 'nil' } },
    force_system_triple = { config.prebuilt_binaries.force_system_triple, { 'string', 'nil' } },
    extra_curl_args = { config.prebuilt_binaries.extra_curl_args, { 'table' } },
    proxy = { config.prebuilt_binaries.proxy, 'table' },
  }, config.prebuilt_binaries)

  validate('fuzzy.prebuilt_binaries.proxy', {
    from_env = { config.prebuilt_binaries.proxy.from_env, 'boolean' },
    url = { config.prebuilt_binaries.proxy.url, { 'string', 'nil' } },
  }, config.prebuilt_binaries.proxy)
end

return fuzzy
