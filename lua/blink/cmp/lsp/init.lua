-- TODO: the `enable` concept is generic and should be moved to a separate module
-- TODO: all buffer-local configs should be cleared when the buffer is deleted
-- TODO: tests

--- @class blink.cmp.lsp
--- @field package _enabled_configs table<string, boolean>
local lsp = { _enabled_configs = {}, _per_buffer_enabled_configs = {} }

--- @class blink.cmp.lsp.Config
--- @field name? string
--- @field async? boolean Whether we should show the completions before this provider returns, without waiting for it
--- @field timeout_ms? number How long to wait for the provider to return before showing completions and treating it as asynchronous
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field should_show_items? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether or not to show the items
--- @field max_items? number | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): number Maximum number of items to display in the menu
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger the provider
--- @field score_offset? number | fun(): number Boost/penalize the score of the items

--- @param name string | string[]
--- @param enable boolean
--- @param filter? { bufnr: integer? }
function lsp.enable(name, enable, filter)
  vim.validate('name', name, { 'string', 'table' })

  local curr_buf = vim.api.nvim_get_current_buf()
  for _, nm in vim._ensure_list(name) do
    assert(nm ~= '*', 'Cannot call cmp.lsp.enable with name "*"')
    if filter ~= nil and filter.bufnr ~= nil then
      local bufnr = filter.bufnr == 0 and curr_buf or filter.bufnr
      lsp._per_buffer_enabled_configs[bufnr] = lsp._per_buffer_enabled_configs[bufnr] or {}
      lsp._per_buffer_enabled_configs[bufnr][nm] = enable
    else
      lsp._enabled_configs[nm] = enable
    end
  end
end

--- @param name string
--- @param filter? { bufnr: integer? }
function lsp.is_enabled(name, filter)
  if filter ~= nil and filter.bufnr ~= nil then
    local bufnr = filter.bufnr == 0 and vim.api.nvim_get_current_buf() or filter.bufnr
    if lsp._per_buffer_enabled_configs[bufnr][name] ~= nil then return lsp._per_buffer_enabled_configs[bufnr][name] end
  end

  if lsp._enabled_configs[name] ~= nil then return lsp._enabled_configs[name] end
  return true
end

--- @param filter? vim.lsp.get_clients.Filter
--- @return vim.lsp.Client[]
function lsp.get_clients(filter)
  return vim.tbl_filter(function(client) return lsp.is_enabled(client.name, filter) end, vim.lsp.get_clients(filter))
end

-- TODO: make private somehow?
--- @class blink.cmp.lsp.buffer_config
--- @field [string] blink.cmp.lsp.Config
--- @field package _per_buffer_configs table<integer, blink.cmp.lsp.Config>
local buffer_configs = setmetatable({
  _per_buffer_configs = {},
}, {
  __index = function(self, bufnr)
    return setmetatable({}, {
      __index = function(_, name)
        vim.validate('name', name, 'string')
        return vim.tbl_deep_extend(
          'force',
          (self._per_buffer_configs[bufnr] or {})['*'] or {},
          (self._per_buffer_configs[bufnr] or {})[name] or {}
        )
      end,

      __newindex = function(_, name, cfg)
        vim.validate('name', name, 'string')
        local hint = ('table (hint: to resolve a config, use cmp.lsp.config.b[bufnr]["%s"])'):format(name)
        vim.validate('cfg', cfg, 'table', hint)
        self._per_buffer_configs[bufnr] = self._per_buffer_configs[bufnr] or {}
        self._per_buffer_configs[bufnr][name] = cfg
      end,
    })
  end,
})

--- @class blink.cmp.lsp.config
--- @field [string] blink.cmp.lsp.Config
--- @field [integer] { [string]: blink.cmp.lsp.Config } Buffer-local configs
--- @field package _configs table<string, blink.cmp.lsp.Config>
lsp.config = setmetatable({
  _configs = {
    ['*'] = {
      async = false,
      timeout_ms = 2000,
      transform_items = function(_, items) return items end,
      should_show_items = function() return true end,
      max_items = function() end,
      min_keyword_length = 0,
      score_offset = 0,
    },
  },
}, {
  --- @param self blink.cmp.lsp.config
  --- @param name_or_bufnr string | integer
  --- @return vim.lsp.Config
  __index = function(self, name_or_bufnr)
    vim.validate('name', name_or_bufnr, { 'string', 'number' })

    if type(name_or_bufnr) == 'number' then return buffer_configs[name_or_bufnr] end

    -- TODO: use metatable instead of merging every time
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.tbl_deep_extend(
      'force',
      self._configs['*'],
      (vim.lsp.config[name_or_bufnr] or {}).blink_cmp or {},
      self._configs[name_or_bufnr] or {},
      buffer_configs[bufnr][name_or_bufnr]
    )
  end,

  --- @param name string
  --- @param cfg blink.cmp.lsp.Config
  __newindex = function(self, name, cfg)
    vim.validate('name', name, 'string')
    vim.validate('cfg', cfg, 'table', ('table (hint: to resolve a config, use cmp.lsp.config["%s"])'):format(name))
    self._configs[name] = cfg
  end,

  --- @param name string
  --- @param cfg blink.cmp.lsp.Config
  --- @param filter? { bufnr: integer? }
  __call = function(self, name, cfg, filter)
    vim.validate('name', name, 'string')
    vim.validate('cfg', cfg, 'table', ('table (hint: to resolve a config, use cmp.lsp.config["%s"])'):format(name))
    vim.validate('filter', filter, 'table', true)

    if filter ~= nil then
      vim.validate('filter.bufnr', filter.bufnr, 'number', true)
      local bufnr = filter.bufnr == 0 and vim.api.nvim_get_current_buf() or filter.bufnr
      buffer_configs[bufnr][name] = cfg
    else
      self[name] = vim.tbl_deep_extend('force', self._configs[name] or {}, cfg)
    end
  end,
})

return lsp
