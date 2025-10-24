local cmp = require('blink.cmp')

-- LSP capabilities/commands
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
vim.lsp.commands['editor.action.triggerParameterHints'] = function() cmp.show_signature() end
vim.lsp.commands['editor.action.triggerSuggest'] = function() cmp.show() end

-- LSP configs
cmp.lsp.config('clangd', {
  transform_items = function(_, items)
    for _, item in ipairs(items) do
      if item.score ~= nil then item.blink_cmp.score_offset = item.score end
    end
  end,
})
cmp.lsp.config('emmet_ls', { score_offset = -6 })
cmp.lsp.config('emmet-language-server', { score_offset = -6 })
cmp.lsp.config('lua_ls', {
  transform_items = function(_, items)
    return vim.tbl_filter(
      function(item) return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text end,
      items
    )
  end,
})
-- TODO: tailwind hack

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

-- Highlights
--- @param hl_group string Highlight group name, e.g. 'ErrorMsg'
--- @param opts vim.api.keyset.highlight Highlight definition map
local set_hl = function(hl_group, opts)
  opts.default = true -- Prevents overriding existing definitions
  vim.api.nvim_set_hl(0, hl_group, opts)
end

local function apply_highlights()
  set_hl('BlinkCmpLabelDeprecated', { link = 'PmenuExtra' })
  set_hl('BlinkCmpLabelDetail', { link = 'PmenuExtra' })
  set_hl('BlinkCmpLabelDescription', { link = 'PmenuExtra' })
  set_hl('BlinkCmpSource', { link = 'PmenuExtra' })
  set_hl('BlinkCmpKind', { link = 'PmenuKind' })
  for _, kind in ipairs(require('blink.cmp.types').CompletionItemKind) do
    set_hl('BlinkCmpKind' .. kind, { link = 'BlinkCmpKind' })
  end

  set_hl('BlinkCmpScrollBarThumb', { link = 'PmenuThumb' })
  set_hl('BlinkCmpScrollBarGutter', { link = 'PmenuSbar' })

  set_hl('BlinkCmpGhostText', { link = 'NonText' })

  set_hl('BlinkCmpMenu', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuBorder', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuSelection', { link = 'PmenuSel' })

  set_hl('BlinkCmpDoc', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocBorder', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocSeparator', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocCursorLine', { link = 'Visual' })

  set_hl('BlinkCmpSignatureHelp', { link = 'NormalFloat' })
  set_hl('BlinkCmpSignatureHelpBorder', { link = 'NormalFloat' })
  set_hl('BlinkCmpSignatureHelpActiveParameter', { link = 'LspSignatureActiveParameter' })
end

apply_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = apply_highlights })
