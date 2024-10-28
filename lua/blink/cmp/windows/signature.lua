local config = require('blink.cmp.config').windows.signature_help
local sources = require('blink.cmp.sources.lib')
local autocomplete = require('blink.cmp.windows.autocomplete')
local signature = {}

function signature.setup()
  signature.win = require('blink.cmp.windows.lib').new({
    min_width = config.min_width,
    max_width = config.max_width,
    max_height = config.max_height,
    border = config.border,
    winhighlight = config.winhighlight,
    wrap = true,
    filetype = 'markdown',
  })

  autocomplete.listen_on_position_update(function()
    if signature.context then signature.update_position(signature.context) end
  end)

  return signature
end

--- @param context blink.cmp.SignatureHelpContext
--- @param signature_help lsp.SignatureHelp | nil
function signature.open_with_signature_help(context, signature_help)
  signature.context = context
  -- check if there are any signatures in signature_help, since
  -- convert_signature_help_to_markdown_lines errors with no signatures
  if
    signature_help == nil
    or #signature_help.signatures == 0
    or signature_help.signatures[(signature_help.activeSignature or 0) + 1] == nil
  then
    signature.win:close()
    return
  end

  local active_signature = signature_help.signatures[(signature_help.activeSignature or 0) + 1]

  if signature.shown_signature ~= active_signature then
    require('blink.cmp.windows.lib.docs').render_detail_and_documentation(
      signature.win:get_buf(),
      active_signature.label,
      active_signature.documentation,
      config.max_width
    )
  end
  signature.shown_signature = active_signature

  -- highlight active parameter
  local _, active_highlight = vim.lsp.util.convert_signature_help_to_markdown_lines(
    signature_help,
    vim.bo.filetype,
    sources.get_signature_help_trigger_characters().trigger_characters
  )
  if active_highlight ~= nil then
    vim.api.nvim_buf_add_highlight(
      signature.win:get_buf(),
      require('blink.cmp.config').highlight.ns,
      'BlinkCmpSignatureHelpActiveParameter',
      0,
      active_highlight[1],
      active_highlight[2]
    )
  end

  signature.win:open()
  signature.update_position(context)
end

function signature.close()
  if not signature.win:is_open() then return end
  signature.win:close()
end

function signature.scroll_up(amount)
  local winnr = signature.win:get_win()
  local top_line = math.max(1, vim.fn.line('w0', winnr) - 1)
  local desired_line = math.max(1, top_line - amount)

  vim.api.nvim_win_set_cursor(signature.win:get_win(), { desired_line, 0 })
end

function signature.scroll_down(amount)
  local winnr = signature.win:get_win()
  local line_count = vim.api.nvim_buf_line_count(signature.win:get_buf())
  local bottom_line = math.max(1, vim.fn.line('w$', winnr) + 1)
  local desired_line = math.min(line_count, bottom_line + amount)

  vim.api.nvim_win_set_cursor(signature.win:get_win(), { desired_line, 0 })
end

--- @param context blink.cmp.SignatureHelpContext
function signature.update_position()
  if not signature.win:is_open() then return end
  local winnr = signature.win:get_win()

  signature.win:update_size()

  local autocomplete_winnr = autocomplete.win:get_win()
  local autocomplete_win_config = autocomplete_winnr and vim.api.nvim_win_get_config(autocomplete_winnr)

  -- TODO: why doesnt vim.fn.screenrow work? it randomly gives a value of 1
  local cursor_screen_row = vim.fn.winline()
  local autocomplete_win_is_up = autocomplete_win_config and autocomplete_win_config.row - cursor_screen_row < 0
  local direction = autocomplete_win_is_up and 's' or 'n'

  local height = signature.win:get_height()
  local cursor_screen_position = signature.win.get_cursor_screen_position()

  -- detect if there's space above/below the cursor
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local is_space_below = cursor_screen_position.distance_from_bottom > height
  local is_space_above = cursor_screen_position.distance_from_top > height

  -- fixes issue where the signature window would cover the cursor
  if is_space_above then
    direction = 'n'
  else
    direction = 's'
  end

  -- default to the user's preference but attempt to use the other options
  local row = direction == 's' and 1 or -height
  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = -1 })
end

return signature
