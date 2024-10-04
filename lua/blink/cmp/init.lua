local cmp = {}

--- @param opts blink.cmp.Config
cmp.setup = function(opts)
  local config = require('blink.cmp.config')
  config.merge_with(opts)

  require('blink.cmp.fuzzy.download').ensure_downloaded(function(err)
    if err then
      vim.notify('Error while downloading blink.cmp pre-built binary: ' .. err, vim.log.levels.ERROR)
      return
    end

    require('blink.cmp.keymap').setup(config.keymap)

    cmp.add_default_highlights()
    -- todo: do we need to clear first?
    vim.api.nvim_create_autocmd('ColorScheme', { callback = cmp.add_default_highlights })

    -- STRUCTURE
    -- trigger -> sources -> fuzzy (filter/sort) -> windows (render)

    -- trigger controls when to show the window and the current context for caching
    -- TODO: add first_trigger event for setting up the rest of the plugin
    cmp.trigger = require('blink.cmp.trigger').activate_autocmds()

    -- sources fetch autocomplete items and documentation
    cmp.sources = require('blink.cmp.sources.lib')
    cmp.sources.register()

    -- windows render and apply items
    cmp.windows = {
      autocomplete = require('blink.cmp.windows.autocomplete').setup(),
      documentation = require('blink.cmp.windows.documentation').setup(),
    }

    -- fuzzy combines smith waterman with frecency
    -- and bonus from proximity words but I'm still working
    -- on tuning the weights
    --- @param context blink.cmp.Context
    --- @param items blink.cmp.CompletionItem[] | nil
    local function update_completions(context, items)
      if not cmp.fuzzy then
        cmp.fuzzy = require('blink.cmp.fuzzy')
        cmp.fuzzy.init_db(vim.fn.stdpath('data') .. '/blink/cmp/fuzzy.db')
      end
      -- we avoid adding 1-4ms to insertion latency by scheduling for later
      vim.schedule(function()
        local filtered_items = cmp.fuzzy.filter_items_with_cache(cmp.fuzzy.get_query(), context, items)
        if #filtered_items > 0 then
          cmp.windows.autocomplete.open_with_items(context, filtered_items)
        else
          cmp.windows.autocomplete.close()
        end
      end)
    end

    cmp.trigger.listen_on_show(function(context)
      update_completions(context) -- immediately update via cache on keystroke
      cmp.sources.request_completions(context)
    end)
    cmp.trigger.listen_on_hide(function()
      cmp.sources.cancel_completions()
      cmp.windows.autocomplete.close()
    end)
    cmp.sources.listen_on_completions(update_completions)
  end)
end

cmp.add_default_highlights = function()
  local use_nvim_cmp = require('blink.cmp.config').highlight.use_nvim_cmp_as_default

  local set_hl = function(hl_group, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, hl_group, opts)
  end

  set_hl('BlinkCmpLabel', { link = use_nvim_cmp and 'CmpItemAbbr' or 'Pmenu' })
  set_hl('BlinkCmpLabelDeprecated', { link = use_nvim_cmp and 'CmpItemAbbrDeprecated' or 'Comment' })
  set_hl('BlinkCmpLabelMatch', { link = use_nvim_cmp and 'CmpItemAbbrMatch' or 'Pmenu' })
  set_hl('BlinkCmpKind', { link = use_nvim_cmp and 'CmpItemKind' or 'Special' })
  for _, kind in pairs(vim.lsp.protocol.CompletionItemKind) do
    set_hl('BlinkCmpKind' .. kind, { link = use_nvim_cmp and 'CmpItemKind' .. kind or 'BlinkCmpItemKind' })
  end
end

------- Public API -------

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
