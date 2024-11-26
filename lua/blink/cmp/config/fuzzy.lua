--- @class (exact) blink.cmp.FuzzyConfig
--- @field use_typo_resistance boolean
--- @field use_frecency boolean
--- @field use_proximity boolean
--- @field sorts ("label" | "kind" | "score")[]
--- @field prebuilt_binaries blink.cmp.PrebuiltBinariesConfig

--- @class (exact) blink.cmp.PrebuiltBinariesConfig
--- @field download boolean
--- @field force_version? string
--- @field force_system_triple? string

local validate = require('blink.cmp.config.utils').validate
local fuzzy = {
  --- @type blink.cmp.FuzzyConfig
  default = {
    use_typo_resistance = true,
    use_frecency = true,
    use_proximity = true,
    sorts = { 'label', 'kind', 'score' },
    prebuilt_binaries = {
      download = true,
      force_version = nil,
      force_system_triple = nil,
    },
  },
}

function fuzzy.validate(config)
  validate('fuzzy', {
    use_typo_resistance = { config.use_typo_resistance, 'boolean' },
    use_frecency = { config.use_frecency, 'boolean' },
    use_proximity = { config.use_proximity, 'boolean' },
    sorts = { config.sorts, { 'string' } },
    prebuilt_binaries = { config.prebuilt_binaries, 'table' },
  })
  validate('fuzzy.prebuilt_binaries', {
    download = { config.prebuilt_binaries.download, 'boolean' },
    force_version = { config.prebuilt_binaries.force_version, { 'string', 'nil' } },
    force_system_triple = { config.prebuilt_binaries.force_system_triple, { 'string', 'nil' } },
  })
end

return fuzzy
