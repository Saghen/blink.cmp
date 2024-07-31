local path = {}

function path.completions(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_path = vim.api.nvim_buf_get_name(bufnr)

  local cwd = vim.fn.expand('%:p:h', buffer_path)
end
