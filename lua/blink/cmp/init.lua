local cmp = {}

--- @param opts CmpConfig
cmp.setup = function(opts)
  local config = require('blink.cmp.config')
  config.merge_with(opts)

  require('blink.cmp.keymap').setup(config.keymap)

  cmp.add_default_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', { callback = cmp.add_default_highlights })

  -- STRUCTURE
  -- trigger -> sources -> fuzzy (filter/sort) -> windows (render)

  -- trigger controls when to show the window and the current context for caching
  cmp.trigger = require('blink.cmp.trigger').activate_autocmds()

  -- sources fetch autocomplete items and documentation
  cmp.sources = require('blink.cmp.sources')

  -- windows render and apply items
  cmp.windows = {
    autocomplete = require('blink.cmp.windows.autocomplete').setup(),
    documentation = require('blink.cmp.windows.documentation').setup(),
  }

  -- fuzzy combines smith waterman with frecency
  -- and bonus from proximity words but I'm still working
  -- on tuning the weights
  cmp.fuzzy = require('blink.cmp.fuzzy')
  cmp.fuzzy.init_db(vim.fn.stdpath('data') .. '/blink/cmp/fuzzy.db')

  cmp.trigger.listen_on_show(function(context) cmp.sources.completions(context) end)
  cmp.trigger.listen_on_hide(function()
    cmp.sources.cancel_completions()
    cmp.windows.autocomplete.close()
  end)
  cmp.sources.listen_on_completions(function(context, items)
    -- avoid adding 1-4ms to insertion latency by scheduling for later
    vim.schedule(function()
      local filtered_items = cmp.fuzzy.filter_items(require('blink.cmp.util').get_query(), items)
      if #filtered_items > 0 then
        cmp.windows.autocomplete.open_with_items(context, filtered_items)
      else
        cmp.windows.autocomplete.close()
      end
    end)
  end)
end

cmp.add_default_highlights = function()
  vim.api.nvim_set_hl(0, 'BlinkCmpLabel', { link = 'Pmenu', default = true })
  vim.api.nvim_set_hl(0, 'BlinkCmpLabelDeprecated', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'BlinkCmpLabelMatch', { link = 'Pmenu', default = true })
  vim.api.nvim_set_hl(0, 'BlinkCmpKind', { link = 'Special', default = true })
  for _, kind in pairs(vim.lsp.protocol.CompletionItemKind) do
    vim.api.nvim_set_hl(0, 'BlinkCmpKind' .. kind, { link = 'BlinkCmpItemKind', default = true })
  end
end

cmp.show = function()
  vim.schedule(function() cmp.trigger.show() end)
  return true
end

cmp.hide = function()
  vim.schedule(function() cmp.trigger.hide() end)
  return true
end

cmp.accept = function()
  local item = cmp.windows.autocomplete.get_selected_item()
  if item == nil then return end

  -- create an undo point
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-g>u', true, true, true), 'n', true)

  vim.schedule(function() require('blink.cmp.accept')(item) end)
  return true
end

cmp.select_prev = function()
  if not cmp.windows.autocomplete.win:is_open() then return end
  vim.schedule(cmp.windows.autocomplete.select_prev)
  return true
end

cmp.select_next = function()
  if not cmp.windows.autocomplete.win:is_open() then return end
  vim.schedule(cmp.windows.autocomplete.select_next)
  return true
end

cmp.show_documentation = function()
  local item = cmp.windows.autocomplete.get_selected_item()
  if not item then return end
  vim.schedule(function() cmp.windows.documentation.show_item(item) end)
  return true
end

cmp.hide_documentation = function()
  if not cmp.windows.documentation.win:is_open() then return end
  vim.schedule(function() cmp.windows.documentation.win:close() end)
  return true
end

cmp.scroll_documentation_up = function()
  if not cmp.windows.documentation.win:is_open() then return end
  vim.schedule(function() cmp.windows.documentation.scroll_up(4) end)
  return true
end

cmp.scroll_documentation_down = function()
  if not cmp.windows.documentation.win:is_open() then return end
  vim.schedule(function() cmp.windows.documentation.scroll_down(4) end)
  return true
end

cmp.snippet_forward = function()
  if not vim.snippet.active({ direction = 1 }) then return end
  vim.schedule(function() vim.snippet.jump(1) end)
  return true
end

cmp.snippet_backward = function()
  if not vim.snippet.active({ direction = -1 }) then return end
  vim.schedule(function() vim.snippet.jump(-1) end)
  return true
end

return cmp
