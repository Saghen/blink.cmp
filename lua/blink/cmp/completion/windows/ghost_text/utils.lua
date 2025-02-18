local utils = {}

--- @param text_edit lsp.TextEdit
function utils.get_still_untyped_text(text_edit)
  local type_text_length = text_edit.range['end'].character - text_edit.range.start.character
  return text_edit.newText:sub(type_text_length + 1)
end

function utils.is_cmdline() return vim.api.nvim_get_mode().mode == 'c' end
function utils.is_noice() return utils.is_cmdline() and package.loaded['noice'] and vim.g.ui_cmdline_pos ~= nil end

function utils.redraw_if_needed()
  if utils.is_cmdline() then vim.api.nvim__redraw({ buf = utils.get_buf(), flush = true }) end
end

--- Gets the buffer to use for ghost text
--- @return integer
function utils.get_buf()
  if vim.api.nvim_get_mode().mode == 'c' then return require('noice.ui.cmdline').position.buf end
  return vim.api.nvim_get_current_buf()
end

--- Gets the offset from the cursor, primarily used for noice cmdline
--- @return integer
function utils.get_offset()
  if vim.api.nvim_get_mode().mode == 'c' then
    return require('noice.ui.cmdline').position.cursor - (vim.fn.getcmdpos() - 1)
  end
  return 0
end

return utils
