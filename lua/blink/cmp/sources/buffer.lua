-- todo: nvim-cmp only updates the lines that got changed which is better
-- but this is *speeeeeed* and simple. should add the better way
-- but ensure it doesn't add too much complexity

local uv = vim.uv

--- @param bufnr integer
--- @return string
local function get_buf_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if bufnr ~= vim.api.nvim_get_current_buf() then return table.concat(lines, '\n') end

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

local function run_async(buf_text, callback)
  local worker = uv.new_work(
    -- must use ffi directly since the normal one requires the config which isnt present
    function(items) return table.concat(require('blink.cmp.fuzzy.rust').get_words(items), '\n') end,
    function(words)
      local items = words_to_items(vim.split(words, '\n'))
      vim.schedule(function() callback(items) end)
    end
  )
  worker:queue(buf_text)
end

--- @class blink.cmp.BufferOpts
--- @field get_bufnrs fun(): integer[]

--- Public API

local buffer = {}

function buffer.new(opts)
  opts = opts or {} ---@type blink.cmp.BufferOpts
  local self = setmetatable({}, { __index = buffer })
  self.get_bufnrs = opts.get_bufnrs
    or function()
      return vim
        .iter(vim.api.nvim_list_wins())
        :map(function(win) return vim.api.nvim_win_get_buf(win) end)
        :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
        :totable()
    end
  return self
end

function buffer:get_completions(_, callback)
  local transformed_callback = function(items)
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  end

  vim.schedule(function()
    local bufnrs = require('blink.cmp.lib.utils').deduplicate(self.get_bufnrs())
    local buf_texts = {}
    for _, buf in ipairs(bufnrs) do
      table.insert(buf_texts, get_buf_text(buf))
    end
    local buf_text = table.concat(buf_texts, '\n')

    -- should take less than 2ms
    if #buf_text < 20000 then
      run_sync(buf_text, transformed_callback)
    -- should take less than 10ms
    elseif #buf_text < 500000 then
      run_async(buf_text, transformed_callback)
    -- too big so ignore
    else
      transformed_callback({})
    end
  end)

  -- TODO: cancel run_async
  return function() end
end

return buffer
