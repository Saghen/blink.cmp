local m = {}

m.items = {}

m.setup = function(config)
  m.cmp_win = require('blink.cmp.win').new({
    cursorline = true,
    winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
  })
  m.doc_win = require('blink.cmp.win').new({
    width = 60,
    max_height = 20,
    relative = m.cmp_win,
    wrap = true,
    filetype = 'typescript', -- todo: set dynamically
    padding = true,
  })
  m.lsp = require('blink.cmp.lsp')
  m.cmp = require('blink.cmp.cmp')

  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function() last_char = vim.v.char end,
  })

  -- decide if we should show the completion window
  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      if m.cmp_win.id ~= nil then return end
      -- todo: if went from prefix to no prefix, clear the items
      if last_char ~= '' and last_char ~= ' ' and last_char ~= '\n' then m.update() end
    end,
  })

  -- update the completion window
  vim.api.nvim_create_autocmd('CursorMovedI', {
    callback = function()
      if m.cmp_win.id ~= nil then m.update() end
    end,
  })

  -- show completion windows
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, {
    callback = function()
      m.lsp.cancel_completions()
      m.cmp_win:close()
      m.doc_win:close()
      m.items = {}
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
        if m.cmp_win.id == nil then return vim.api.nvim_replace_termcodes(key, true, false, true) end
        vim.schedule(callback)
      end,
    })
  end
  keymap('i', '<Tab>', m.accept)
  keymap('i', '<C-j>', m.select_next)
  keymap('i', '<C-k>', m.select_prev)
  keymap('i', '<Up>', m.select_prev)
  keymap('i', '<Down>', m.select_next)
  vim.api.nvim_set_keymap('i', '<C-space>', '', {
    noremap = true,
    silent = true,
    callback = function() m.update({ force = true }) end,
  })
end

m.update = function(opts)
  opts = opts or { force = false }

  m.cmp_win:temp_buf_hack()
  m.doc_win:temp_buf_hack()

  -- immediately update the results
  m.cmp.update(m.cmp_win, m.doc_win, m.items, opts)
  m.cmp_win:update()
  m.doc_win:update()
  -- trigger the lsp and update the results after retrieving
  m.lsp.completions(function(items)
    m.items = items
    m.cmp.update(m.cmp_win, m.doc_win, m.items, opts)
    m.cmp_win:update()
    m.doc_win:update()
  end)
end

m.accept = function()
  if m.cmp_win.id ~= nil then m.cmp.accept(m.cmp_win) end
end

m.select_prev = function() m.cmp.select_prev(m.cmp_win, m.doc_win) end

m.select_next = function() m.cmp.select_next(m.cmp_win, m.doc_win) end

return m
