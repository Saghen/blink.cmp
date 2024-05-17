local M = {}

M.items = {}

M.setup = function(config)
  M.cmp_win = require('blink.cmp.win').new({
    cursorline = true,
    winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
  })
  M.doc_win = require('blink.cmp.win').new({
    width = 60,
    max_height = 20,
    relative = M.cmp_win,
    wrap = true,
    filetype = 'typescript', -- todo: set dynamically
    padding = true,
  })
  M.lsp = require('blink.cmp.lsp')
  M.cmp = require('blink.cmp.cmp')

  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function() last_char = vim.v.char end,
  })

  -- decide if we should show the completion window
  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      if M.cmp_win.id ~= nil then return end
      -- todo: if went from prefix to no prefix, clear the items
      if last_char ~= '' and last_char ~= ' ' and last_char ~= '\n' then M.update() end
    end,
  })

  -- update the completion window
  vim.api.nvim_create_autocmd('CursorMovedI', {
    callback = function()
      if M.cmp_win.id ~= nil then M.update() end
    end,
  })

  -- show completion windows
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, {
    callback = function()
      M.lsp.cancel_completions()
      M.cmp_win:close()
      M.doc_win:close()
      M.items = {}
    end,
  })

  -- keybindings
  -- todo: SCUFFED
  local keymap = function(mode, key, callback)
    vim.api.nvim_set_keymap(mode, key, '', {
      expr = true,
      noremap = true,
      silent = true,
      callback = function()
        if M.cmp_win.id == nil then return vim.api.nvim_replace_termcodes(key, true, false, true) end
        vim.schedule(callback)
      end,
    })
  end
  keymap('i', '<Tab>', M.accept)
  keymap('i', '<C-j>', M.select_next)
  keymap('i', '<C-k>', M.select_prev)
  keymap('i', '<Up>', M.select_prev)
  keymap('i', '<Down>', M.select_next)
  vim.api.nvim_set_keymap('i', '<C-space>', '', {
    noremap = true,
    silent = true,
    callback = function() M.update({ force = true }) end,
  })
end

M.update = function(opts)
  opts = opts or { force = false }

  -- immediately update the results
  M.cmp.update(M.cmp_win, M.doc_win, M.items, opts)
  M.cmp_win:update()
  M.doc_win:update()
  -- trigger the lsp and update the results after retrieving
  M.lsp.completions(function(items)
    M.items = items
    M.cmp.update(M.cmp_win, M.doc_win, M.items, opts)
    M.cmp_win:update()
    M.doc_win:update()
  end)
end

M.accept = function()
  if M.cmp_win.id ~= nil then M.cmp.accept(M.cmp_win) end
end

M.select_prev = function() M.cmp.select_prev(M.cmp_win, M.doc_win) end

M.select_next = function() M.cmp.select_next(M.cmp_win, M.doc_win) end

return M
