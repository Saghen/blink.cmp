--- @class blink.cmp.API
local cmp = {}

local has_setup = false
--- Initializes blink.cmp with the given configuration and initiates the download
--- for the fuzzy matcher's prebuilt binaries, if necessary
--- @param opts? blink.cmp.Config
function cmp.setup(opts)
  if has_setup then return end
  has_setup = true

  opts = opts or {}

  if vim.fn.has('nvim-0.10') == 0 then
    vim.notify('blink.cmp requires nvim 0.10 and newer', vim.log.levels.ERROR, { title = 'blink.cmp' })
    return
  end

  local config = require('blink.cmp.config')
  config.merge_with(opts)

  require('blink.cmp.fuzzy.download').ensure_downloaded(function(err)
    if err then vim.notify(err, vim.log.levels.ERROR) end

    -- setup highlights, keymap, completion, commands and signature help
    require('blink.cmp.highlights').setup()
    require('blink.cmp.keymap').setup()
    require('blink.cmp.completion').setup()
    require('blink.cmp.commands').setup()
    if config.signature.enabled then require('blink.cmp.signature').setup() end
  end)
end

------- Public API -------

--- Checks if the completion menu or ghost text is visible
--- @return boolean
function cmp.is_visible() return cmp.is_menu_visible() or cmp.is_ghost_text_visible() end

--- Checks if the completion menu is visible
--- @return boolean
function cmp.is_menu_visible() return require('blink.cmp.completion.windows.menu').win:is_open() end

--- Checks if the ghost text is visible
--- @return boolean
function cmp.is_ghost_text_visible() return require('blink.cmp.completion.windows.ghost_text').is_open() end

--- Checks if the documentation window is visible
--- @return boolean
function cmp.is_documentation_visible() return require('blink.cmp.completion.windows.documentation').win:is_open() end

--- Show the completion window
--- @param opts? { providers?: string[], initial_selected_item_idx?: number, callback?: fun() }
function cmp.show(opts)
  opts = opts or {}

  -- TODO: when passed a list of providers, we should check if we're already showing the menu
  -- with that list of providers
  if require('blink.cmp.completion.windows.menu').win:is_open() and not (opts and opts.providers) then return end

  vim.schedule(function()
    require('blink.cmp.completion.windows.menu').auto_show = true

    -- HACK: because blink is event based, we don't have an easy way to know when the "show"
    -- event completes. So we wait for the list to trigger the show event and check if we're
    -- still in the same context
    local context
    if opts.callback then
      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpShow',
        callback = function(event)
          if context ~= nil and event.data.context.id == context.id then opts.callback() end
        end,
        once = true,
      })
    end

    context = require('blink.cmp.completion.trigger').show({
      force = true,
      providers = opts and opts.providers,
      trigger_kind = 'manual',
      initial_selected_item_idx = opts.initial_selected_item_idx,
    })
  end)
  return true
end

-- Show the completion window and select the first item
--- @params opts? { providers?: string[], callback?: fun() }
function cmp.show_and_insert(opts)
  opts = opts or {}
  opts.initial_selected_item_idx = 1
  return cmp.show(opts)
end

--- Hide the completion window
--- @param opts? { callback?: fun() }
function cmp.hide(opts)
  if not cmp.is_visible() then return end

  vim.schedule(function()
    require('blink.cmp.completion.trigger').hide()
    if opts and opts.callback then opts.callback() end
  end)
  return true
end

--- Cancel the current completion, undoing the preview from auto_insert
--- @param opts? { callback?: fun() }
function cmp.cancel(opts)
  if not cmp.is_visible() then return end
  vim.schedule(function()
    require('blink.cmp.completion.list').undo_preview()
    require('blink.cmp.completion.trigger').hide()
    if opts and opts.callback then opts.callback() end
  end)
  return true
end

--- Accept the current completion item
--- @param opts? blink.cmp.CompletionListAcceptOpts
function cmp.accept(opts)
  opts = opts or {}
  if not cmp.is_visible() then return end

  local completion_list = require('blink.cmp.completion.list')
  local item = opts.index ~= nil and completion_list.items[opts.index] or completion_list.get_selected_item()
  if item == nil then return end

  vim.schedule(function() completion_list.accept(opts) end)
  return true
end

--- Select the first completion item, if there's no selection, and accept
--- @param opts? blink.cmp.CompletionListSelectAndAcceptOpts
function cmp.select_and_accept(opts)
  if not cmp.is_visible() then return end

  local completion_list = require('blink.cmp.completion.list')
  vim.schedule(
    function()
      completion_list.accept({
        index = completion_list.selected_item_idx or 1,
        callback = opts and opts.callback,
      })
    end
  )
  return true
end

--- Select the previous completion item
--- @param opts? blink.cmp.CompletionListSelectOpts
function cmp.select_prev(opts)
  if not cmp.is_visible() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_prev(opts) end)
  return true
end

--- Select the next completion item
--- @param opts? blink.cmp.CompletionListSelectOpts
function cmp.select_next(opts)
  if not cmp.is_visible() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_next(opts) end)
  return true
end

--- Gets the currently selected completion item
function cmp.get_selected_item() return require('blink.cmp.completion.list').get_selected_item() end

--- Show the documentation window
function cmp.show_documentation()
  local menu = require('blink.cmp.completion.windows.menu')
  local documentation = require('blink.cmp.completion.windows.documentation')
  if documentation.win:is_open() or not menu.win:is_open() then return end

  local context = require('blink.cmp.completion.list').context
  local item = require('blink.cmp.completion.list').get_selected_item()
  if not item or not context then return end

  vim.schedule(function() documentation.show_item(context, item) end)
  return true
end

--- Hide the documentation window
function cmp.hide_documentation()
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.close() end)
  return true
end

--- Scroll the documentation window up
--- @param count? number
function cmp.scroll_documentation_up(count)
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.scroll_up(count or 4) end)
  return true
end

--- Scroll the documentation window down
--- @param count? number
function cmp.scroll_documentation_down(count)
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.scroll_down(count or 4) end)
  return true
end

--- Check if a snippet is active, optionally filtering by direction
--- @param filter? { direction?: number }
function cmp.snippet_active(filter) return require('blink.cmp.config').snippets.active(filter) end

--- Move the cursor forward to the next snippet placeholder
function cmp.snippet_forward()
  local snippets = require('blink.cmp.config').snippets
  if not snippets.active({ direction = 1 }) then return end
  vim.schedule(function() snippets.jump(1) end)
  return true
end

--- Move the cursor backward to the previous snippet placeholder
function cmp.snippet_backward()
  local snippets = require('blink.cmp.config').snippets
  if not snippets.active({ direction = -1 }) then return end
  vim.schedule(function() snippets.jump(-1) end)
  return true
end

--- Tells the sources to reload a specific provider or all providers (when nil)
--- @param provider? string
function cmp.reload(provider) require('blink.cmp.sources.lib').reload(provider) end

--- Gets the capabilities to pass to the LSP client
--- @param override? lsp.ClientCapabilities Overrides blink.cmp's default capabilities
--- @param include_nvim_defaults? boolean Whether to include nvim's default capabilities
function cmp.get_lsp_capabilities(override, include_nvim_defaults)
  return require('blink.cmp.sources.lib').get_lsp_capabilities(override, include_nvim_defaults)
end

--- Add a new source provider at runtime
--- @param source_id string
--- @param source_config blink.cmp.SourceProviderConfig
function cmp.add_provider(source_id, source_config)
  local config = require('blink.cmp.config')
  assert(config.sources.providers[source_id] == nil, 'Provider with id ' .. source_id .. ' already exists')
  require('blink.cmp.config.sources').validate_provider(source_id, source_config)
  config.sources.providers[source_id] = source_config
end

--- Adds a source to the list of enable sources for a given filetype
--- @param filetype string
--- @param source string
function cmp.add_filetype_source(filetype, source)
  local config = require('blink.cmp.config')

  assert(
    type(config.sources.per_filetype[filetype]) ~= 'function',
    'Sources for filetype "' .. filetype .. '" has been set to a function, so we cannot add a source to it'
  )
  if config.sources.per_filetype[filetype] == nil then config.sources.per_filetype[filetype] = {} end

  local sources = config.sources.per_filetype[filetype]
  --- @cast sources string[]
  table.insert(sources, source)
end

return cmp
