--- Provides a way to enter keys in a sequence. We want to do this because it
--- also appends these keys to the `.` register, which is used with
--- dot-repeating.
--- The implementation is based on the one in nvim-cmp, except that it's using
--- blink's async utilities.
---
--- vim.api.nvim_feedkeys is blocking, but to truly wait for the keys to
--- actually have been inserted, 'x' (immediate mode) should be used.

local feedkeys = {}

---@nodiscard
feedkeys.call_async = function(keys, mode)
  local task = require('blink.cmp.lib.async').task
  return task.new(function(resolve)
    local is_insert = string.match(mode, 'i') ~= nil
    local is_immediate = string.match(mode, 'x') ~= nil

    local queue = {}
    if #keys > 0 then
      table.insert(queue, { feedkeys.t('<Cmd>setlocal lazyredraw<CR>'), 'n' })
      table.insert(queue, { feedkeys.t('<Cmd>setlocal textwidth=0<CR>'), 'n' })
      table.insert(queue, { feedkeys.t('<Cmd>setlocal backspace=nostop<CR>'), 'n' })
      table.insert(queue, { keys, string.gsub(mode, '[itx]', ''), true })
      table.insert(queue, { feedkeys.t('<Cmd>setlocal %slazyredraw<CR>'):format(vim.o.lazyredraw and '' or 'no'), 'n' })
      table.insert(queue, { feedkeys.t('<Cmd>setlocal textwidth=%s<CR>'):format(vim.bo.textwidth or 0), 'n' })
      table.insert(queue, { feedkeys.t('<Cmd>setlocal backspace=%s<CR>'):format(vim.go.backspace or 2), 'n' })
    end

    if is_insert then
      for i = #queue, 1, -1 do
        vim.api.nvim_feedkeys(queue[i][1], queue[i][2] .. 'i', queue[i][3])
      end
    else
      for i = 1, #queue do
        vim.api.nvim_feedkeys(queue[i][1], queue[i][2], queue[i][3])
      end
    end

    if is_immediate then vim.api.nvim_feedkeys('', 'x', true) end

    return resolve()
  end)
end

---Shortcut for nvim_replace_termcodes
---@param keys string
---@return string
feedkeys.t = function(keys)
  -- implementation copied from
  -- https://github.com/hrsh7th/nvim-cmp/blob/b555203ce4bd7ff6192e759af3362f9d217e8c89/lua/cmp/utils/feedkeys.lua?plain=1#L7-L14
  return (
    string.gsub(
      keys,
      "(<[A-Za-z0-9\\%-%[%]%^@;,:_']->)",
      function(match) return vim.api.nvim_eval(string.format([["\%s"]], match)) end
    )
  )
end
local t = feedkeys.t

---Create backspace keys.
---@param count string|integer
---@return string
---@nodiscard
feedkeys.backspace = function(count)
  if type(count) == 'string' then count = vim.fn.strchars(count, true) end
  if count <= 0 then return '' end
  local keys = {}
  table.insert(keys, t(string.rep('<BS>', count)))
  return table.concat(keys, '')
end

return feedkeys
