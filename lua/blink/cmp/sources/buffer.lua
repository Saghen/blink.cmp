-- todo: nvim-cmp only updates the lines that got changed which is better
-- but this is *speeeeeed* and simple. should add the better way
-- but ensure it doesn't add too much complexity

local fuzzy = require('blink.cmp.fuzzy')
local utils = require('blink.cmp.sources.lib.utils')
local dedup = require('blink.cmp.lib.utils').deduplicate
local uv = vim.uv

--- @param bufnr integer
--- @return string
local function get_buf_text(bufnr, exclude_word_under_cursor)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if bufnr ~= vim.api.nvim_get_current_buf() or not exclude_word_under_cursor then return table.concat(lines, '\n') end

  -- exclude word under the cursor for the current buffer
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_number = cursor[1]
  local column = cursor[2]
  local line = lines[line_number]
  local start_col = column
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match('[%w_\\-]') == nil then break end
    start_col = start_col - 1
  end
  local end_col = column
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match('[%w_\\-]') == nil then break end
    end_col = end_col + 1
  end
  lines[line_number] = line:sub(1, start_col) .. ' ' .. line:sub(end_col + 1)

  return table.concat(lines, '\n')
end

--- @param words string[]
--- @return blink.cmp.CompletionItem[]
local function words_to_items(words)
  local items = {}
  for _, word in ipairs(words) do
    table.insert(items, {
      label = word,
      kind = require('blink.cmp.types').CompletionItemKind.Text,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      insertText = word,
    })
  end
  return items
end

--- @param buf_text string
--- @param callback fun(items: blink.cmp.CompletionItem[])
local function run_sync(buf_text, callback)
  local words = fuzzy.get_words(buf_text)
  callback(words_to_items(words))
end

local function run_async_rust(buf_text, callback)
  local worker = uv.new_work(
    -- must use rust module directly since the normal one requires the config which isn't present
    function(buf_text, cpath)
      package.cpath = cpath
      ---@diagnostic disable-next-line: redundant-return-value
      return table.concat(require('blink.cmp.fuzzy.rust').get_words(buf_text), '\n')
    end,
    ---@param words string
    function(words)
      local items = words_to_items(vim.split(words, '\n'))
      vim.schedule(function() callback(items) end)
    end
  )
  worker:queue(buf_text, package.cpath)
end

local function run_async_lua(buf_text, callback)
  local min_chunk_size = 2000 -- Min chunk size in bytes
  local max_chunk_size = 4000 -- Max chunk size in bytes
  local total_length = #buf_text

  local cancelled = false
  local pos = 1
  local all_words = {}

  local function next_chunk()
    if cancelled then return end

    local start_pos = pos
    local end_pos = math.min(start_pos + min_chunk_size - 1, total_length)

    -- Ensure we don't break in the middle of a word
    if end_pos < total_length then
      while
        end_pos < total_length
        and (end_pos - start_pos) < max_chunk_size
        and not string.match(string.sub(buf_text, end_pos, end_pos), '%s')
      do
        end_pos = end_pos + 1
      end
    end

    pos = end_pos + 1

    local chunk_text = string.sub(buf_text, start_pos, end_pos)
    local chunk_words = fuzzy.get_words(chunk_text)
    vim.list_extend(all_words, chunk_words)

    -- next iter
    if pos < total_length then return vim.schedule(next_chunk) end

    -- Deduplicate and finish
    local words = dedup(all_words)
    vim.schedule(function() callback(words_to_items(words)) end)
  end

  next_chunk()

  return function() cancelled = true end
end

--- @class blink.cmp.BufferOpts
--- @field get_bufnrs fun(): integer[]
--- @field get_search_bufnrs fun(): integer[]
--- @field max_sync_buffer_size integer Maximum buffer text size for sync processing
--- @field max_async_buffer_size integer Maximum buffer text size for async processing
--- @field enable_in_ex_commands boolean Whether to enable buffer source in substitute (:s) and global (:g) commands

---@class blink.cmp.BufferCacheEntry
---@field changedtick integer
---@field exclude_word_under_cursor boolean
---@field items blink.cmp.CompletionItem[]

--- Public API

local buffer = {}

function buffer.new(opts)
  local self = setmetatable({}, { __index = buffer })

  --- @type blink.cmp.BufferOpts
  opts = vim.tbl_deep_extend('keep', opts or {}, {
    get_bufnrs = function()
      return vim
        .iter(vim.api.nvim_list_wins())
        :map(function(win) return vim.api.nvim_win_get_buf(win) end)
        :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
        :totable()
    end,
    get_search_bufnrs = function() return { vim.api.nvim_get_current_buf() } end,
    max_sync_buffer_size = 20000,
    max_async_buffer_size = 500000,
    enable_in_ex_commands = false,
  })
  require('blink.cmp.config.utils').validate('sources.providers.buffer', {
    get_bufnrs = { opts.get_bufnrs, 'function' },
    get_search_bufnrs = { opts.get_search_bufnrs, 'function' },
    max_sync_buffer_size = { opts.max_sync_buffer_size, 'number' },
    max_async_buffer_size = { opts.max_async_buffer_size, 'number' },
    enable_in_ex_commands = { opts.enable_in_ex_commands, 'boolean' },
  }, opts)

  -- HACK: When using buffer completion sources in ex commands
  -- while 'inccommand' is active, Neovim's UI redraw is delayed by one frame.
  -- This causes completion popups to appear out of sync with user input,
  -- due to a known Neovim limitation (see neovim/neovim#9783).
  -- To work around this, temporarily disable 'inccommand'.
  -- This sacrifice live substitution previews, but restores correct redraw.
  if opts.enable_in_ex_commands then
    vim.on_key(function()
      if utils.is_command_line({ ':' }) and vim.o.inccommand ~= '' then vim.o.inccommand = '' end
    end)
  end

  self.opts = opts

  ---@type table<integer, blink.cmp.BufferCacheEntry>
  self.cache = {}

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    desc = 'Invalidate buffer cache items when buffer is deleted',
    callback = function(args) self.cache[args.buf] = nil end,
  })

  return self
end

--- @return boolean
function buffer:is_search_context()
  -- In search mode
  if utils.is_command_line({ '/', '?' }) then return true end
  -- In specific ex commands, if user opts in
  if self.opts.enable_in_ex_commands and utils.in_ex_context({ 'substitute', 'global', 'vglobal' }) then return true end

  return false
end

---@param bufnr integer
---@param exclude_word_under_cursor boolean
---@param callback fun(items: blink.cmp.CompletionItem[])
function buffer:get_buf_items(bufnr, exclude_word_under_cursor, callback)
  local changedtick = vim.b[bufnr].changedtick
  local cache = self.cache[bufnr]

  if cache and cache.changedtick == changedtick and cache.exclude_word_under_cursor == exclude_word_under_cursor then
    callback(cache.items)
    return
  end

  ---@param items blink.cmp.CompletionItem[]
  local function cache_and_callback(items)
    self.cache[bufnr] = {
      changedtick = changedtick,
      exclude_word_under_cursor = exclude_word_under_cursor,
      items = items,
    }
    callback(items)
  end

  local buf_text = get_buf_text(bufnr, exclude_word_under_cursor)

  -- should take less than 2ms
  if #buf_text < self.opts.max_sync_buffer_size then
    run_sync(buf_text, cache_and_callback)
  -- should take less than 10ms
  elseif #buf_text < self.opts.max_async_buffer_size then
    if fuzzy.implementation_type == 'rust' then
      run_async_rust(buf_text, cache_and_callback)
    else
      run_async_lua(buf_text, cache_and_callback)
    end
  else
    -- too big so ignore
    cache_and_callback({})
  end
end

--- @return boolean
function buffer:enabled()
  -- Enable in regular buffer
  if not utils.is_command_line() then return true end
  -- Enable in search context
  if self:is_search_context() then return true end

  return false
end

function buffer:get_completions(_, callback)
  vim.schedule(function()
    local is_search = self:is_search_context()
    local get_bufnrs = is_search and self.opts.get_search_bufnrs or self.opts.get_bufnrs
    local bufnrs = dedup(get_bufnrs())

    if #bufnrs == 0 then
      callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
      return
    end

    ---@type blink.cmp.CompletionItem[]
    local items = {}
    local queued = #bufnrs

    for _, buf in ipairs(bufnrs) do
      self:get_buf_items(buf, not is_search, function(buf_items)
        vim.list_extend(items, buf_items)
        queued = queued - 1
        if queued == 0 then
          callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
        end
      end)
    end
  end)
end

return buffer
