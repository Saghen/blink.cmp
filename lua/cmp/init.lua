local M = {
  core = require('cmp.core'),
  types = require('cmp.types'),
  lsp = require('cmp.types.lsp'),
}

function M.register_source(name, s)
  require('blink.cmp.sources.compat.nvim_cmp.registry').register_source(name, s)
  -- use name as id
  return name
end

function M.unregister_source(id) require('blink.cmp.sources.compat.nvim_cmp.registry').unregister_source(id) end

return M
