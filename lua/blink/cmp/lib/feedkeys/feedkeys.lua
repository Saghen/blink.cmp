local feedkeys = {}

feedkeys.call = setmetatable({
  callbacks = {},
}, {
  __call = function(self, keys, mode, callback)
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

    if callback then
      -- since we run inserting keys in a queue, we need to run the callback in
      -- a queue as well so it runs after the keys have been inserted
      local id = feedkeys.id('blink.feedkeys.call')
      self.callbacks[id] = callback
      table.insert(
        queue,
        { feedkeys.t('<Cmd>lua require"blink.cmp.lib.feedkeys.feedkeys".run(%s)<CR>'):format(id), 'n', true }
      )
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
  end,
})

feedkeys.run = function(id)
  if feedkeys.call.callbacks[id] then
    local ok, err = pcall(feedkeys.call.callbacks[id])
    if not ok then vim.notify(err, vim.log.levels.ERROR) end
    feedkeys.call.callbacks[id] = nil
  end
  return ''
end

---Generate id for group name
feedkeys.id = setmetatable({
  group = {},
}, {
  __call = function(_, group)
    feedkeys.id.group[group] = feedkeys.id.group[group] or 0
    feedkeys.id.group[group] = feedkeys.id.group[group] + 1
    return feedkeys.id.group[group]
  end,
})

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
