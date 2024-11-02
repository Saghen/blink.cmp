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
    winblend = config.winblend,
    winhighlight = config.winhighlight,
    wrap = true,
    filetype = 'markdown',
  })

  -- todo: deduplicate this
  autocomplete.listen_on_position_update(function()
    if signature.context then signature.update_position(signature.context) end
  end)

  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'WinScrolled', 'WinResized' }, {
    callback = function()
      if signature.context then signature.update_position(signature.context) end
    end,
  })

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
  local win = signature.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local direction_priority = config.direction_priority

  -- if the autocomplete window is open, we want to place the signature window on the opposite side
  local autocomplete_win_config = autocomplete.win:get_win() and vim.api.nvim_win_get_config(autocomplete.win:get_win())
  if autocomplete.win:is_open() then
    local cursor_screen_row = vim.fn.winline()
    local autocomplete_win_is_up = autocomplete_win_config.row - cursor_screen_row < 0
    direction_priority = autocomplete_win_is_up and { 's' } or { 'n' }
  end

  local height = win:get_height()
  local pos = win:get_vertical_direction_and_height(direction_priority)

  -- couldn't find anywhere to place the window
  if not pos then
    win:close()
    return
  end

  -- default to the user's preference but attempt to use the other options
  local row = pos.direction == 's' and 1 or -height
  local screenpos = vim.fn.screenpos(0, unpack(vim.api.nvim_win_get_cursor(0)))
  local col = autocomplete_win_config and (autocomplete_win_config.col - screenpos.col) or 0
  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col })
  vim.api.nvim_win_set_height(winnr, pos.height)
end

return signature
