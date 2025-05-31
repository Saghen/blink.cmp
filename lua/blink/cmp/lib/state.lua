local M = {}
local flag = {}

local function cur(bufnr) return bufnr or vim.api.nvim_get_current_buf() end

function M.set(bufnr, ev_name) flag[cur(bufnr)] = ev_name end

function M.get(bufnr) return flag[cur(bufnr)] end

function M.clear(bufnr) flag[cur(bufnr)] = nil end

return M
