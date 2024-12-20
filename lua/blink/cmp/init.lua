local has_setup = false
local cmp = {}

--- @param opts? blink.cmp.Config
function cmp.setup(opts)
  if has_setup then return end
  has_setup = true

  opts = opts or {}

  local version = vim.version()
  if version.major == 0 and version.minor < 10 then
    vim.notify('blink.cmp only supports nvim 0.10 and newer', vim.log.levels.ERROR)
    return
  end

  local config = require('blink.cmp.config')
  config.merge_with(opts)

  require('blink.cmp.fuzzy.download').ensure_downloaded(function(err)
    if err then error('Error while downloading blink.cmp pre-built binary: ' .. err) end

    -- setup highlights, keymap, completion and signature help
    require('blink.cmp.highlights').setup()
    require('blink.cmp.keymap').setup()
    require('blink.cmp.completion').setup()
    if config.signature.enabled then require('blink.cmp.signature').setup() end
  end)
end

------- Public API -------

--- Checks if the completion menu is currently visible
--- @return boolean
function cmp.is_visible()
  return require('blink.cmp.completion.windows.menu').win:is_open()
    or require('blink.cmp.completion.windows.ghost_text').is_open()
end

--- @params opts? { providers?: string[] }
function cmp.show(opts)
  if cmp.is_visible() and not (opts and opts.providers) then return end

  vim.schedule(function()
    require('blink.cmp.completion.windows.menu').auto_show = true
    require('blink.cmp.completion.trigger').show({ force = true, providers = opts and opts.providers })
  end)
  return true
end

function cmp.hide()
  if not cmp.is_visible() then return end

  vim.schedule(require('blink.cmp.completion.trigger').hide)
  return true
end

function cmp.cancel()
  if not cmp.is_visible() then return end
  vim.schedule(function()
    require('blink.cmp.completion.list').undo_preview()
    require('blink.cmp.completion.trigger').hide()
  end)
  return true
end

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

function cmp.select_prev()
  if not cmp.is_visible() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_prev() end)
  return true
end

function cmp.select_next()
  if not cmp.is_visible() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_next() end)
  return true
end

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

function cmp.hide_documentation()
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.win:close() end)
  return true
end

--- @param count? number
function cmp.scroll_documentation_up(count)
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.scroll_up(count or 4) end)
  return true
end

--- @param count? number
function cmp.scroll_documentation_down(count)
  local documentation = require('blink.cmp.completion.windows.documentation')
  if not documentation.win:is_open() then return end

  vim.schedule(function() documentation.scroll_down(count or 4) end)
  return true
end

--- @param filter? { direction?: number }
function cmp.snippet_active(filter) return require('blink.cmp.config').snippets.active(filter) end

function cmp.snippet_forward()
  local snippets = require('blink.cmp.config').snippets
  if not snippets.active({ direction = 1 }) then return end
  vim.schedule(function() snippets.jump(1) end)
  return true
end

function cmp.snippet_backward()
  local snippets = require('blink.cmp.config').snippets
  if not snippets.active({ direction = -1 }) then return end
  vim.schedule(function() snippets.jump(-1) end)
  return true
end

--- Tells the sources to reload a specific provider or all providers (when nil)
--- @param provider? string
function cmp.reload(provider) require('blink.cmp.sources.lib').reload(provider) end

--- @param override? lsp.ClientCapabilities
--- @param include_nvim_defaults? boolean
function cmp.get_lsp_capabilities(override, include_nvim_defaults)
  return require('blink.cmp.sources.lib').get_lsp_capabilities(override, include_nvim_defaults)
end

--- @param id string
--- @param provider_config blink.cmp.SourceProviderConfig
function cmp.add_provider(id, provider_config)
  local config = require('blink.cmp.config')
  assert(config.sources.providers[id] == nil, 'Provider with id ' .. id .. ' already exists')
  require('blink.cmp.config.sources').validate_provider(id, provider_config)
  config.sources.providers[id] = provider_config
end

return cmp
