if vim.fn.has('nvim-0.11') == 1 and vim.lsp.config then
  vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  })
end

-- Commands
local subcommands = {
  status = function() vim.cmd('checkhealth blink.cmp') end,
  build = function() require('blink.cmp.fuzzy.build').build() end,
  ['build-log'] = function() require('blink.cmp.fuzzy.build').build_log() end,
}
vim.api.nvim_create_user_command('BlinkCmp', function(cmd)
  local subcommand = subcommands[cmd.fargs[1]]
  if subcommand then
    subcommand()
  else
    vim.notify("[blink.cmp] invalid subcommand '" .. subcommand.args .. "'", vim.log.levels.ERROR)
  end
end, { nargs = 1, complete = function() vim.tbl_keys(subcommands) end, desc = 'blink.cmp' })
