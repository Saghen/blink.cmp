--- @class blink.cmp.Override : blink.cmp.Source
--- @field new fun(module: blink.cmp.Source, override_config: blink.cmp.SourceOverride): blink.cmp.Override

local override = {}

function override.new(module, override_config)
  override_config = override_config or {}

  return setmetatable({}, {
    __index = function(_, key)
      if override_config[key] ~= nil then
        return function(self, ...) return override_config[key](self.module, ...) end
      end
      return module[key]
    end,
  })
end

return override
