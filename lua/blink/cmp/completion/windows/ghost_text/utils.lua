local utils = {}

function utils.is_cmdline() return vim.api.nvim_get_mode().mode == 'c' end
function utils.is_cmdwin() return vim.fn.win_gettype() == 'command' end

function utils.is_noice()
  return utils.is_cmdline()
    and package.loaded['noice']
    and vim.g.ui_cmdline_pos ~= nil
    and require('noice.ui.cmdline').position ~= nil
    and require('noice.ui.cmdline').position.buf ~= nil
end

function utils.redraw_if_needed()
  if utils.is_cmdline() then vim.api.nvim__redraw({ buf = utils.get_buf(), flush = true }) end
end

--- Gets the buffer to use for ghost text
--- @return integer?
function utils.get_buf()
  if utils.is_cmdline() then
    if not utils.is_noice() then return end
    return require('noice.ui.cmdline').position.buf
  end
  return vim.api.nvim_get_current_buf()
end

--- Gets the offset from the cursor, primarily used for noice cmdline
--- @return integer
function utils.get_offset()
  if utils.is_cmdline() then
    if not utils.is_noice() then return 0 end
    return require('noice.ui.cmdline').position.cursor - (vim.fn.getcmdpos() - 1)
  end
  return 0
end

return utils
