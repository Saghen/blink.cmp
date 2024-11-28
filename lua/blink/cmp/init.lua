local cmp = {}

--- @param opts blink.cmp.Config
function cmp.setup(opts)
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

function cmp.show()
  if require('blink.cmp.completion.windows.menu').win:is_open() then return end

  vim.schedule(function() require('blink.cmp.completion.trigger').show({ force = true }) end)
  return true
end

function cmp.hide()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end

  vim.schedule(require('blink.cmp.completion.trigger').hide)
  return true
end

function cmp.cancel()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end
  vim.schedule(function()
    require('blink.cmp.completion.list').undo_preview()
    require('blink.cmp.completion.trigger').hide()
  end)
  return true
end

function cmp.accept()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end

  local completion_list = require('blink.cmp.completion.list')
  local item = completion_list.get_selected_item()
  if item == nil then return end

  vim.schedule(function() completion_list.accept() end)
  return true
end

function cmp.select_and_accept()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end

  local completion_list = require('blink.cmp.completion.list')
  vim.schedule(function()
    -- select an item if none is selected
    if not completion_list.get_selected_item() then completion_list.select_next({ skip_auto_insert = true }) end
    completion_list.accept()
  end)
  return true
end

function cmp.select_prev()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_prev() end)
  return true
end

function cmp.select_next()
  if not require('blink.cmp.completion.windows.menu').win:is_open() then return end
  vim.schedule(function() require('blink.cmp.completion.list').select_next() end)
  return true
end

function cmp.show_documentation()
  local menu = require('blink.cmp.completion.windows.menu')
  local documentation = require('blink.cmp.completion.windows.documentation')
  if documentation.win:is_open() or not menu.win:is_open() then return end

  local item = require('blink.cmp.completion.list').get_selected_item()
  if not item then return end

  vim.schedule(function() documentation.show_item(item) end)
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

--- @param override? lsp.ClientCapabilities
--- @param include_nvim_defaults? boolean
function cmp.get_lsp_capabilities(override, include_nvim_defaults)
  return require('blink.cmp.sources.lib').get_lsp_capabilities(override, include_nvim_defaults)
end

return cmp
