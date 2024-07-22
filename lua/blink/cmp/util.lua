local utils = {}

-- keybindings
-- hack: should provide examples for each package manager
-- instead of doing it through config
function utils.keymap(mode, key, callback)
  vim.api.nvim_set_keymap(mode, key, '', {
    expr = true,
    noremap = true,
    silent = true,
    callback = function()
      local autocomplete = require('blink.cmp.windows.autocomplete')
      if not autocomplete.win:is_open() then return vim.api.nvim_replace_termcodes(key, true, false, true) end
      vim.schedule(callback)
    end,
  })
end

function utils.get_query()
  local bufnr = vim.api.nvim_get_current_buf()

  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local current_col = vim.api.nvim_win_get_cursor(0)[2] - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line, current_line + 1, false)[1]

  return string.sub(line, 1, current_col + 1):match('[%w_\\-]+$') or ''
end

return utils
