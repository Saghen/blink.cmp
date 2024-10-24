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

    cmp.add_default_highlights()

    require('blink.cmp.keymap').setup(config.keymap)

    -- STRUCTURE
    -- trigger -> sources -> fuzzy (filter/sort) -> windows (render)

    -- trigger controls when to show the window and the current context for caching
    -- TODO: add first_trigger event for setting up the rest of the plugin
    cmp.trigger = require('blink.cmp.trigger.completion').activate_autocmds()

    -- sources fetch autocomplete items, documentation and signature help
    cmp.sources = require('blink.cmp.sources.lib')
    cmp.sources.register()

    -- windows render and apply completion items and signature help
    cmp.windows = {
      autocomplete = require('blink.cmp.windows.autocomplete').setup(),
      documentation = require('blink.cmp.windows.documentation').setup(),
    }

    cmp.trigger.listen_on_show(function(context) cmp.sources.request_completions(context) end)
    cmp.trigger.listen_on_hide(function()
      cmp.sources.cancel_completions()
      cmp.windows.autocomplete.close()
    end)
    cmp.sources.listen_on_completions(function(context, items)
      -- fuzzy combines smith waterman with frecency
      -- and bonus from proximity words but I'm still working
      -- on tuning the weights
      if not cmp.fuzzy then
        cmp.fuzzy = require('blink.cmp.fuzzy')
        cmp.fuzzy.init_db(vim.fn.stdpath('data') .. '/blink/cmp/fuzzy.db')
      end

      -- we avoid adding 0.5-4ms to insertion latency by scheduling for later
      vim.schedule(function()
        if cmp.trigger.context == nil or cmp.trigger.context.id ~= context.id then return end

        local filtered_items = cmp.fuzzy.filter_items(cmp.fuzzy.get_query(), items)
        filtered_items = cmp.sources.apply_max_items_for_completions(context, filtered_items)
        if #filtered_items > 0 then
          cmp.windows.autocomplete.open_with_items(context, filtered_items)
        else
          cmp.windows.autocomplete.close()
        end
      end)
    end)

    -- setup signature help if enabled
    if config.trigger.signature_help.enabled then cmp.setup_signature_help() end
  end)
end

cmp.setup_signature_help = function()
  local signature_trigger = require('blink.cmp.trigger.signature').activate_autocmds()
  local signature_window = require('blink.cmp.windows.signature').setup()

  signature_trigger.listen_on_show(function(context)
    cmp.sources.cancel_signature_help()
    cmp.sources.get_signature_help(context, function(signature_help)
      if signature_help ~= nil and signature_trigger.context ~= nil and signature_trigger.context.id == context.id then
        signature_trigger.set_active_signature_help(signature_help)
        signature_window.open_with_signature_help(context, signature_help)
      else
        signature_trigger.hide()
      end
    end)
  end)
  signature_trigger.listen_on_hide(function() signature_window.close() end)
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
  for _, kind in ipairs(require('blink.cmp.types').CompletionItemKind) do
    set_hl('BlinkCmpKind' .. kind, { link = use_nvim_cmp and 'CmpItemKind' .. kind or 'BlinkCmpKind' })
  end

  set_hl('BlinkCmpMenu', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuBorder', { link = 'Pmenu' })
  set_hl('BlinkCmpMenuSelection', { link = 'PmenuSel' })

  set_hl('BlinkCmpDoc', { link = 'NormalFloat' })
  set_hl('BlinkCmpDocBorder', { link = 'FloatBorder' })
  set_hl('BlinkCmpDocCursorLine', { link = 'Visual' })

  set_hl('BlinkCmpSignatureHelp', { link = 'NormalFloat' })
  set_hl('BlinkCmpSignatureHelpBorder', { link = 'FloatBorder' })
  set_hl('BlinkCmpSignatureHelpActiveParameter', { link = 'LspSignatureActiveParameter' })
end

------- Public API -------

cmp.show = function()
  if cmp.windows.autocomplete.win:is_open() then return end
  vim.schedule(function()
    cmp.windows.autocomplete.auto_show = true
    cmp.trigger.show({ force = true })
  end)
  return true
end

cmp.hide = function()
  if not cmp.windows.autocomplete.win:is_open() then return end
  vim.schedule(cmp.trigger.hide)
  return true
end

--- @param callback fun(context: blink.cmp.Context)
cmp.on_open = function(callback) cmp.windows.autocomplete.listen_on_open(callback) end

--- @param callback fun()
cmp.on_close = function(callback) cmp.windows.autocomplete.listen_on_close(callback) end

cmp.accept = function()
  local item = cmp.windows.autocomplete.get_selected_item()
  if item == nil then return end

  vim.schedule(function() cmp.windows.autocomplete.accept() end)
  return true
end

cmp.select_and_accept = function()
  if not cmp.windows.autocomplete.win:is_open() then return end

  vim.schedule(function()
    -- select an item if none is selected
    if not cmp.windows.autocomplete.get_selected_item() then
      -- avoid running auto_insert since we're about to accept anyway
      cmp.windows.autocomplete.select_next({ skip_auto_insert = true })
    end

    local item = cmp.windows.autocomplete.get_selected_item()
    if item ~= nil then require('blink.cmp.accept')(item) end
  end)
  return true
end

cmp.select_prev = function()
  if not cmp.windows.autocomplete.win:is_open() then
    if cmp.windows.autocomplete.auto_show then return end
    cmp.show()
    return true
  end
  vim.schedule(cmp.windows.autocomplete.select_prev)
  return true
end

cmp.select_next = function()
  if not cmp.windows.autocomplete.win:is_open() then
    if cmp.windows.autocomplete.auto_show then return end
    cmp.show()
    return true
  end
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
