-- todo: nvim-cmp only updates the lines that got changed which is better
-- but this is *speeeeeed* and simple. should add the better way
-- but ensure it doesn't add too much complexity

local fuzzy = require('blink.cmp.fuzzy')
local uv = vim.uv

--- @param bufnr integer
--- @return string
local function get_buf_text(bufnr, exclude_word_under_cursor)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if bufnr ~= vim.api.nvim_get_current_buf() or not exclude_word_under_cursor then return table.concat(lines, '\n') end

  -- exclude word under the cursor for the current buffer
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local column = vim.api.nvim_win_get_cursor(0)[2]
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
local function run_sync(buf_text, callback) callback(words_to_items(require('blink.cmp.fuzzy').get_words(buf_text))) end

local function run_async_rust(buf_text, callback)
  local worker = uv.new_work(
    -- must use rust module directly since the normal one requires the config which isnt present
    function(buf_text, cpath)
      package.cpath = cpath
      return table.concat(require('blink.cmp.fuzzy.rust').get_words(buf_text), '\n')
    end,
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
    local chunk_words = require('blink.cmp.fuzzy').get_words(chunk_text)
    vim.list_extend(all_words, chunk_words)

    -- next iter
    if pos < total_length then return vim.schedule(next_chunk) end

    -- Deduplicate and finish
    local words = require('blink.cmp.lib.utils').deduplicate(all_words)
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
      if vim.fn.getcmdtype() == ':' and vim.o.inccommand ~= '' then vim.o.inccommand = '' end
    end)
  end

  self.opts = opts
  return self
end

function buffer:enabled()
  local cmdtype = vim.fn.getcmdtype()
  -- Enable in regular buffer
  if cmdtype == '' then return true end
  -- Enable in search mode
  if cmdtype == '/' or cmdtype == '?' then return true end
  -- Enable for substitute and global commands in ex mode
  if cmdtype == ':' and self.opts.enable_in_ex_commands then
    local valid_cmd, parsed = pcall(vim.api.nvim_parse_cmd, vim.fn.getcmdline(), {})
    local cmd = (valid_cmd and parsed.cmd) or ''
    if vim.tbl_contains({ 'substitute', 'global', 'vglobal' }, cmd) then return true end
  end
  return false
end

function buffer:get_completions(_, callback)
  local transformed_callback = function(items)
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  end

  vim.schedule(function()
    local is_search = vim.tbl_contains({ '/', '?', ':' }, vim.fn.getcmdtype())
    local get_bufnrs = is_search and self.opts.get_search_bufnrs or self.opts.get_bufnrs
    local bufnrs = require('blink.cmp.lib.utils').deduplicate(get_bufnrs())

    local buf_texts = {}
    for _, buf in ipairs(bufnrs) do
      table.insert(buf_texts, get_buf_text(buf, not is_search))
    end
    local buf_text = table.concat(buf_texts, '\n')

    -- should take less than 2ms
    if #buf_text < self.opts.max_sync_buffer_size then
      run_sync(buf_text, transformed_callback)
    -- should take less than 10ms
    elseif #buf_text < self.opts.max_async_buffer_size then
      if fuzzy.implementation_type == 'rust' then
        return run_async_rust(buf_text, transformed_callback)
      else
        return run_async_lua(buf_text, transformed_callback)
      end
    -- too big so ignore
    else
      transformed_callback({})
    end
  end)
end

return buffer
