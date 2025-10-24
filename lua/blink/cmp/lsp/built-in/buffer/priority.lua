local utils = require('blink.cmp.lsp.buffer.utils')

local priority = {
  recency_bufs = {},
}

-- Track recency of buffers
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  desc = 'Track buffer recency when entering a buffer',
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    priority.recency_bufs[bufnr] = vim.loop.hrtime()
  end,
})
vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
  desc = 'Invalidate buffer recency when buffer is deleted',
  callback = function(args) priority.recency_bufs[args.buf] = nil end,
})

function priority.focused()
  return function(bufnr) return bufnr == vim.api.nvim_win_get_buf(0) and 0 or 1 end
end

function priority.visible()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  return function(bufnr) return visible[bufnr] and 0 or 1 end
end

function priority.recency()
  local time = vim.loop.hrtime()
  return function(bufnr) return time - (priority.recency_bufs[bufnr] or 0) end
end

function priority.largest(buf_sizes)
  return function(bufnr) return -buf_sizes[bufnr] end
end

function priority.comparator(buf_sizes)
  local value_fns = {}
  for _, key in ipairs({ 'focused', 'visible', 'recency', 'largest' }) do
    if priority[key] then table.insert(value_fns, priority[key](buf_sizes)) end
  end

  return function(a, b)
    for _, fn in ipairs(value_fns) do
      local va, vb = fn(a), fn(b)
      if va ~= vb then return va < vb end
    end
    return a < b -- fallback: lower bufnr first
  end
end

--- Retain buffers up to a total size cap, in the specified retention order.
--- @param bufnrs integer[]
--- @param max_total_size integer
--- @return integer[] selected
function priority.retain_buffers(bufnrs, max_total_size)
  local buf_sizes = {}
  for _, bufnr in ipairs(bufnrs) do
    buf_sizes[bufnr] = utils.get_buffer_size(bufnr)
  end

  local sorted_bufnrs = vim.deepcopy(bufnrs)
  table.sort(sorted_bufnrs, priority.comparator(buf_sizes))
  sorted_bufnrs = vim.tbl_filter(function(bufnr) return buf_sizes[bufnr] <= 200000 end, sorted_bufnrs)

  local selected, total_size = {}, 0
  for _, bufnr in ipairs(sorted_bufnrs) do
    local size = buf_sizes[bufnr]
    if total_size + size > max_total_size then break end
    total_size = total_size + size
    table.insert(selected, bufnr)
  end

  return selected
end

return priority
