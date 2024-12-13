local highlights = {}

--- @param hl_group string Highlight group name, e.g. 'ErrorMsg'
--- @param val vim.api.keyset.highlight Highlight definition map
--- @return nil
local set_global_hl = function(hl_group, val)
  val.default = true -- Prevents overriding existing definitions
  vim.api.nvim_set_hl(0, hl_group, val)
end

function highlights.setup()
  local use_nvim_cmp = require('blink.cmp.config').appearance.use_nvim_cmp_as_default

  if use_nvim_cmp then
    set_global_hl('BlinkCmpLabel', { link = 'CmpItemAbbr' })
    set_global_hl('BlinkCmpLabelMatch', { link = 'CmpItemAbbrMatch' })
  end

  set_global_hl('BlinkCmpLabelDeprecated', { link = use_nvim_cmp and 'CmpItemAbbrDeprecated' or 'NonText' })
  set_global_hl('BlinkCmpLabelDetail', { link = use_nvim_cmp and 'CmpItemMenu' or 'NonText' })
  set_global_hl('BlinkCmpLabelDescription', { link = use_nvim_cmp and 'CmpItemMenu' or 'NonText' })
  set_global_hl('BlinkCmpKind', { link = use_nvim_cmp and 'CmpItemKind' or 'Special' })
  set_global_hl('BlinkCmpSource', { link = use_nvim_cmp and 'CmpItemMenu' or 'NonText' })
  for _, kind in ipairs(require('blink.cmp.types').CompletionItemKind) do
    set_global_hl('BlinkCmpKind' .. kind, { link = use_nvim_cmp and 'CmpItemKind' .. kind or 'BlinkCmpKind' })
  end

  set_global_hl('BlinkCmpScrollBarThumb', { link = 'PmenuThumb' })
  set_global_hl('BlinkCmpScrollBarGutter', { link = 'PmenuSbar' })

  set_global_hl('BlinkCmpGhostText', { link = use_nvim_cmp and 'CmpGhostText' or 'NonText' })

  set_global_hl('BlinkCmpMenu', { link = 'Pmenu' })
  set_global_hl('BlinkCmpMenuBorder', { link = 'Pmenu' })
  set_global_hl('BlinkCmpMenuSelection', { link = 'PmenuSel' })

  set_global_hl('BlinkCmpDoc', { link = 'NormalFloat' })
  set_global_hl('BlinkCmpDocBorder', { link = 'NormalFloat' })
  set_global_hl('BlinkCmpDocSeparator', { link = 'NormalFloat' })
  set_global_hl('BlinkCmpDocCursorLine', { link = 'Visual' })

  set_global_hl('BlinkCmpSignatureHelp', { link = 'NormalFloat' })
  set_global_hl('BlinkCmpSignatureHelpBorder', { link = 'NormalFloat' })
  set_global_hl('BlinkCmpSignatureHelpActiveParameter', { link = 'LspSignatureActiveParameter' })
end

--- @param hex_color string Hex color (e.g. "#ff0000")
--- @return string
function highlights.get_hex_color_highlight(hex_color)
  local hl_name = 'HexColor' .. hex_color:sub(2)
  set_global_hl(hl_name, { fg = hex_color })
  return hl_name
end

return highlights
