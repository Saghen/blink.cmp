local nvim_cmp_registry = {}

function nvim_cmp_registry.new()
  local self = setmetatable(nvim_cmp_registry, { _index = nvim_cmp_registry })
  self.sources = {}

  return self
end

function nvim_cmp_registry:get_source(name) return self.sources[name] end

function nvim_cmp_registry:register_source(name, s) self.sources[name] = s end

function nvim_cmp_registry:unregister_source(id) self.sources[id] = nil end

return nvim_cmp_registry
