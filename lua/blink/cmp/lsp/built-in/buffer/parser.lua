local async = require('blink.cmp.lib.async')
local fuzzy = require('blink.cmp.fuzzy')

local parser = {}

--- @param bufnr integer
--- @param exclude_word_under_cursor boolean
--- @return blink.cmp.Task
function parser.get_buf_words(bufnr, exclude_word_under_cursor)
  local cache = require('blink.cmp.sources.buffer.cache')

  local cached_item = cache.get(bufnr)
  if
    cached_item
    and cached_item.changedtick == vim.b[bufnr].changedtick
    and cached_item.exclude_word_under_cursor == exclude_word_under_cursor
  then
    return async.task.identity(cached_item.words)
  end

  return parser.get_buf_words(bufnr, exclude_word_under_cursor):map(function(words)
    cache:set(bufnr, {
      changedtick = vim.b[bufnr].changedtick,
      exclude_word_under_cursor = exclude_word_under_cursor,
      words = words,
    })
    return words
  end)
end

function parser._get_buf_words(bufnr, exclude_word_under_cursor)
  local buf_text = parser.get_buf_text(bufnr, exclude_word_under_cursor)
  local len = #buf_text

  local can_use_rust = package.loaded['blink.cmp.fuzzy.rust'] ~= nil

  -- should take less than 2ms
  if len < 20000 then
    return parser.run_sync(buf_text)
  -- should take less than 10ms
  elseif len < 200000 then
    if can_use_rust then
      return parser.run_async_rust(buf_text)
    else
      return parser.run_async_lua(buf_text)
    end
  else
    -- Too big, skip
    return async.task.identity({})
  end
end

--- @param bufnr integer
--- @return string
function parser.get_buf_text(bufnr, exclude_word_under_cursor)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- exclude word under the cursor for the current buffer
  if exclude_word_under_cursor then
    local line_number, column = unpack(vim.api.nvim_win_get_cursor(0))
    local line = lines[line_number]

    local before = line:sub(1, column):gsub('%k+$', '')
    local after = line:sub(column + 1):gsub('^%k+', '')

    lines[line_number] = before .. ' ' .. after
  end

  return table.concat(lines, '\n')
end

--- @param text string
--- @return blink.cmp.Task
function parser.run_sync(text) return async.task.identity(fuzzy.get_words(text)) end

--- @param text string
--- @return blink.cmp.Task
function parser.run_async_rust(text)
  return async.task.new(function(resolve)
    local worker = vim.uv.new_work(
      -- must use rust module directly since the normal one requires the config which isn't present
      function(text, cpath)
        package.cpath = cpath
        --- @diagnostic disable-next-line: redundant-return-value
        return table.concat(require('blink.cmp.fuzzy.rust').get_words(text), '\n')
      end,
      --- @param words string
      function(words)
        vim.schedule(function() resolve(vim.split(words, '\n')) end)
      end
    )
    worker:queue(text, package.cpath)
  end)
end

--- @param text string
--- @return blink.cmp.Task
function parser.run_async_lua(text)
  local min_chunk_size = 2000 -- Min chunk size in bytes
  local max_chunk_size = 4000 -- Max chunk size in bytes
  local total_length = #text

  local cancelled = false
  local pos = 1
  local all_words = {}

  return async.task
    .new(function(resolve)
      local function next_chunk()
        if cancelled then return end

        local start_pos = pos
        local end_pos = math.min(start_pos + min_chunk_size - 1, total_length)

        -- Ensure we don't break in the middle of a word
        if end_pos < total_length then
          while
            end_pos < total_length
            and (end_pos - start_pos) < max_chunk_size
            and not string.match(string.sub(text, end_pos, end_pos), '%s')
          do
            end_pos = end_pos + 1
          end
        end

        pos = end_pos + 1

        local chunk_text = string.sub(text, start_pos, end_pos)
        local chunk_words = fuzzy.get_words(chunk_text)
        vim.list_extend(all_words, chunk_words)

        -- next iter
        if pos < total_length then return vim.schedule(next_chunk) end

        resolve(all_words)
      end

      next_chunk()
    end)
    :on_cancel(function() cancelled = true end)
end

return parser
