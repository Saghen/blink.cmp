if vim.fn.has('nvim-0.11') == 1 then
  vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  })
end
