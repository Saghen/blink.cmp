local highlights = {}

function highlights.setup()
  local use_nvim_cmp = require('blink.cmp.config').highlight.use_nvim_cmp_as_default

  local set_hl = function(hl_group, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, hl_group, opts)
  end

  set_hl('BlinkCmpLabel', { link = use_nvim_cmp and 'CmpItemAbbr' or 'Pmenu' })
  set_hl('BlinkCmpLabelDeprecated', { link = use_nvim_cmp and 'CmpItemAbbrDeprecated' or 'NonText' })
  set_hl('BlinkCmpLabelMatch', { link = use_nvim_cmp and 'CmpItemAbbrMatch' or 'Pmenu' })
  set_hl('BlinkCmpLabelDetail', { link = use_nvim_cmp and 'CmpItemMenu' or 'NonText' })
  set_hl('BlinkCmpLabelDescription', { link = use_nvim_cmp and 'CmpItemMenu' or 'NonText' })
  set_hl('BlinkCmpKind', { link = use_nvim_cmp and 'CmpItemKind' or 'Special' })
  for _, kind in ipairs(require('blink.cmp.types').CompletionItemKind) do
    set_hl('BlinkCmpKind' .. kind, { link = use_nvim_cmp and 'CmpItemKind' .. kind or 'BlinkCmpKind' })
  end

  set_hl('BlinkCmpScrollBarThumb', { link = 'PmenuThumb' })
  set_hl('BlinkCmpScrollBarGutter', { link = 'PmenuSbar' })

  set_hl('BlinkCmpGhostText', { link = use_nvim_cmp and 'CmpGhostText' or 'NonText' })

  set_hl('BlinkCmpMenu', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuBorder', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuSelection', { link = 'PmenuSel' })

  set_hl('BlinkCmpDoc', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocBorder', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocCursorLine', { link = 'Visual' })

  set_hl('BlinkCmpSignatureHelp', { link = 'NormalFloat' })
  set_hl('BlinkCmpSignatureHelpBorder', { link = 'NormalFloat' })
  set_hl('BlinkCmpSignatureHelpActiveParameter', { link = 'LspSignatureActiveParameter' })
end

return highlights
