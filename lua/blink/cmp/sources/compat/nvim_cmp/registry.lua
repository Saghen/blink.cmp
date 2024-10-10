local registry = {
  sources = {},
}

function registry.get_source(name) return registry.sources[name] end

function registry.register_source(name, s) registry.sources[name] = s end

function registry.unregister_source(id) registry.sources[id] = nil end

return registry
