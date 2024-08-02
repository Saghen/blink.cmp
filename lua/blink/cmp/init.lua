local cmp = {}

--- @param opts CmpConfig
cmp.setup = function(opts)
  require('blink.cmp.config').merge_with(opts)

  cmp.add_default_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', { callback = cmp.add_default_highlights })

  -- trigger -> sources -> fuzzy (filter/sort) -> windows (render)
  --
  -- trigger controls when to show the window and the current context
  -- for caching
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

  local start_time = vim.loop.hrtime()
  cmp.trigger.listen_on_show(function(context)
    start_time = vim.loop.hrtime()
    cmp.sources.completions(context)
  end)
  cmp.trigger.listen_on_hide(function()
    cmp.sources.cancel_completions()
    cmp.windows.autocomplete.close()
  end)
  cmp.sources.listen_on_completions(function(context, items)
    local duration = vim.loop.hrtime() - start_time
    print('cmp.sources.listen_on_completions duration: ' .. duration / 1000000 .. 'ms')
    -- avoid adding 1-4ms to insertion latency by scheduling for later
    vim.schedule(function()
      local filtered_items = cmp.fuzzy.filter_items(require('blink.cmp.util').get_query(), items)
      if #filtered_items > 0 then
        cmp.windows.autocomplete.open_with_items(context, filtered_items)
        print('cmp.windows.autocomplete.open_with_items duration: ' .. duration / 1000000 .. 'ms')
      else
        cmp.windows.autocomplete.close()
      end
    end)
  end)
end

-- todo: dont default to cmp, use new hl groups
cmp.add_default_highlights = function()
  --- @class Opts
  --- @field name string
  --- @field cmp_name string | nil
  --- @field default_name string

  --- @param opts Opts
  local function default_to_cmp(opts)
    local cmp_hl_name = 'CmpItem' .. (opts.cmp_name or opts.name)
    local blink_hl_name = 'BlinkCmp' .. opts.name
    if vim.api.nvim_get_hl(0, { name = cmp_hl_name, create = false }) ~= nil then
      vim.api.nvim_set_hl(0, blink_hl_name, { link = cmp_hl_name, default = true })
    else
      vim.api.nvim_set_hl(0, blink_hl_name, { link = opts.default_name, default = true })
    end
  end

  default_to_cmp({ name = 'Label', cmp_name = 'Abbr', default_name = 'Pmenu' })
  default_to_cmp({ name = 'LabelDeprecated', cmp_name = 'AbbrDeprecated', default_name = 'Comment' })
  default_to_cmp({ name = 'LabelMatch', cmp_name = 'AbbrMatch', default_name = 'Pmenu' })
  default_to_cmp({ name = 'Kind', default_name = 'Special' })
  for _, kind in pairs(vim.lsp.protocol.CompletionItemKind) do
    default_to_cmp({ name = 'Kind' .. kind, default_name = 'BlinkCmpItemKind' })
  end
end

cmp.show = function()
  vim.schedule(function() cmp.trigger.show() end)
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
