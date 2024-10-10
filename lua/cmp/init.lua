local M = {
  core = require('cmp.core'),
  lsp = require('cmp.lsp'),
}

function M.register_source(name, s)
  require('blink.cmp.sources.lib').nvim_cmp_registry:register_source(name, s)
  return name
end

function M.unregister_source(id) require('blink.cmp.sources.lib').nvim_cmp_registry:unregister_source(id) end

return M
