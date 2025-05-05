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
    local words = require('blink.cmp.lib.utils').deduplicate(chunk_words)

    -- next iter
    if pos < total_length then return vim.schedule(next_chunk) end
    -- or finish
    vim.schedule(function() callback(words_to_items(words)) end)
  end

  next_chunk()

  return function() cancelled = true end
end

--- @class blink.cmp.BufferOpts
--- @field get_bufnrs fun(): integer[]
--- @field get_search_bufnrs fun(): integer[]

--- Public API

local buffer = {}

function buffer.new(opts)
  --- @cast opts blink.cmp.BufferOpts

  local self = setmetatable({}, { __index = buffer })
  self.get_bufnrs = opts.get_bufnrs
    or function()
      return vim
        .iter(vim.api.nvim_list_wins())
        :map(function(win) return vim.api.nvim_win_get_buf(win) end)
        :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
        :totable()
    end
  self.get_search_bufnrs = opts.get_search_bufnrs or function() return { vim.api.nvim_get_current_buf() } end
  return self
end

function buffer:get_completions(_, callback)
  local transformed_callback = function(items)
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  end

  vim.schedule(function()
    local is_search = vim.tbl_contains({ '/', '?' }, vim.fn.getcmdtype())
    local get_bufnrs = is_search and self.get_search_bufnrs or self.get_bufnrs
    local bufnrs = require('blink.cmp.lib.utils').deduplicate(get_bufnrs())

    local buf_texts = {}
    for _, buf in ipairs(bufnrs) do
      table.insert(buf_texts, get_buf_text(buf, not is_search))
    end
    local buf_text = table.concat(buf_texts, '\n')

    -- should take less than 2ms
    if #buf_text < 20000 then
      run_sync(buf_text, transformed_callback)
    -- should take less than 10ms
    elseif #buf_text < 500000 then
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
