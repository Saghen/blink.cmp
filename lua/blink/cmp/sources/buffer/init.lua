-- todo: nvim-cmp only updates the lines that got changed which is better
-- but this is *speeeeeed* and simple. should add the better way
-- but ensure it doesn't add too much complexity

local async = require('blink.cmp.lib.async')
local parser = require('blink.cmp.sources.buffer.parser')
local fuzzy = require('blink.cmp.fuzzy')
local utils = require('blink.cmp.sources.lib.utils')
local dedup = require('blink.cmp.lib.utils').deduplicate

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

--- @param words string[]
--- @return blink.cmp.CompletionItem[]
local function words_to_items(words)
  local kind_text = require('blink.cmp.types').CompletionItemKind.Text
  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText

  local items = {}
  for i = 1, #words do
    items[i] = {
      label = words[i],
      kind = kind_text,
      insertTextFormat = plain_text,
      insertText = words[i],
    }
  end
  return items
end

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

--- @param bufnr integer
--- @param exclude_word_under_cursor boolean
--- @return blink.cmp.Task
function buffer:get_buf_items(bufnr, exclude_word_under_cursor)
  local changedtick = vim.b[bufnr].changedtick
  local cache = self.cache[bufnr]

  if cache and cache.changedtick == changedtick and cache.exclude_word_under_cursor == exclude_word_under_cursor then
    return async.task.identity(cache.words)
  end

  ---@param words string[]
  local function store_in_cache(words)
    self.cache[bufnr] = {
      changedtick = changedtick,
      exclude_word_under_cursor = exclude_word_under_cursor,
      words = words,
    }
    return words
  end

  local buf_text = parser.get_buf_text(bufnr, exclude_word_under_cursor)

  -- should take less than 2ms
  if #buf_text < self.opts.max_sync_buffer_size then
    return parser.run_sync(buf_text):map(store_in_cache)
  -- should take less than 10ms
  elseif #buf_text < self.opts.max_async_buffer_size then
    if fuzzy.implementation_type == 'rust' then
      return parser.run_async_rust(buf_text):map(store_in_cache)
    else
      return parser.run_async_lua(buf_text):map(store_in_cache)
    end
  else
    -- too big so ignore
    return async.task.identity({})
  end
end

--- @return boolean
function buffer:enabled() return not utils.is_command_line() or self:is_search_context() end

function buffer:get_completions(_, callback)
  vim.schedule(function()
    local is_search = self:is_search_context()
    local get_bufnrs = is_search and self.opts.get_search_bufnrs or self.opts.get_bufnrs
    local bufnrs = dedup(get_bufnrs())

    if #bufnrs == 0 then
      callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
      return
    end

    local tasks = vim.tbl_map(function(buf) return self:get_buf_items(buf, not is_search) end, bufnrs)
    async.task.all(tasks):map(function(words_per_buf)
      --- @cast words_per_buf string[][]

      local all_words = {}
      for _, buf_words in ipairs(words_per_buf) do
        vim.list_extend(all_words, buf_words)
      end
      local items = words_to_items(dedup(all_words))

      ---@diagnostic disable-next-line: missing-return
      callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
    end)
  end)
end

return buffer
