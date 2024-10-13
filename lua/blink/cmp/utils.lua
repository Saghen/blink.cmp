local utils = {}

--- Shallow copy table
--- @generic T
--- @param t T
--- @return T
function utils.shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--- Returns the union of the keys of two tables
--- @generic T
--- @param t1 T[]
--- @param t2 T[]
--- @return T[]
function utils.union_keys(t1, t2)
  local t3 = {}
  for k, _ in pairs(t1) do
    t3[k] = true
  end
  for k, _ in pairs(t2) do
    t3[k] = true
  end
  return vim.tbl_keys(t3)
end

--- Determines whether the current buffer is a "special" buffer or if the filetype is in the list of ignored filetypes
--- @return boolean
function utils.is_ignored_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  local blocked_filetypes = require('blink.cmp.config').blocked_filetypes or {}
  local buf_filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

  if vim.tbl_contains(blocked_filetypes, buf_filetype) then return true end
  return buftype ~= ''
end

return utils
