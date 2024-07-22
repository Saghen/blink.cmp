local m = {}

m.setup = function(opts)
  require('blink.cmp.config').setup(opts)
  local utils = require('blink.cmp.util')

  -- trigger -> sources -> fuzzy (filter/sort) -> windows (render)
  --
  -- trigger controls when to show the window and the current context
  -- for caching
  m.trigger = require('blink.cmp.trigger').activate_autocmds()

  -- sources fetch autocomplete items and documentation
  m.sources = require('blink.cmp.sources')

  -- windows render and apply items
  m.windows = {
    autocomplete = require('blink.cmp.windows.autocomplete').setup(),
    documentation = require('blink.cmp.windows.documentation').setup(),
  }

  -- fuzzy combines smith waterman with frecency
  -- and bonus from proximity words but I'm still working
  -- on tuning the weights
  m.fuzzy = require('blink.cmp.fuzzy.lib')

  m.trigger.listen_on_show(function(context) m.sources.completions(context) end)
  m.trigger.listen_on_hide(function()
    m.sources.cancel_completions()
    m.windows.autocomplete.close()
  end)
  m.sources.listen_on_completions(function(items)
    -- avoid adding 1-4ms to insertion latency by scheduling for later
    vim.schedule(function()
      local filtered_items = m.fuzzy.filter_items(utils.get_query(), items)
      if #filtered_items > 0 then
        m.windows.autocomplete.open_with_items(filtered_items)
      else
        m.windows.autocomplete.close()
      end
    end)
  end)

  utils.keymap('i', '<Tab>', m.accept)
  utils.keymap('i', '<C-j>', m.select_next)
  utils.keymap('i', '<C-k>', m.select_prev)
  utils.keymap('i', '<Up>', m.select_prev)
  utils.keymap('i', '<Down>', m.select_next)
  vim.api.nvim_set_keymap('i', '<C-space>', '', {
    noremap = true,
    silent = true,
    callback = function() m.trigger.show() end,
  })
end

m.accept = function()
  local item = m.windows.autocomplete.get_selected_item()
  if item == nil then return end
  require('blink.cmp.accept')(item)
end

m.select_prev = function() m.windows.autocomplete.select_prev() end

m.select_next = function() m.windows.autocomplete.select_next() end

return m
