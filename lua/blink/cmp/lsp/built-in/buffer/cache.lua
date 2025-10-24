--- @class blink.cmp.BufferCacheEntry
--- @field changedtick integer
--- @field exclude_word_under_cursor boolean
--- @field words string[]

--- @class blink.cmp.BufferCache
local cache = {}

local store = {}
vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  desc = 'Invalidate buffer cache items when buffer is deleted',
  callback = function(args) store[args.buf] = nil end,
})

--- Get the cache entry for a buffer.
--- @param bufnr integer
--- @return blink.cmp.BufferCacheEntry|nil
function cache.get(bufnr) return store[bufnr] end

--- Set the cache entry for a buffer.
--- @param bufnr integer
--- @param value blink.cmp.BufferCacheEntry
function cache.set(bufnr, value) store[bufnr] = value end

--- Remove cache entries for buffers not in the given list.
--- @param valid_bufnrs integer[]
function cache.keep(valid_bufnrs)
  local keep = {}
  for _, k in ipairs(valid_bufnrs) do
    keep[k] = true
  end
  for k in pairs(store) do
    if not keep[k] then store[k] = nil end
  end
end

return cache
