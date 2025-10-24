local M = {}

--- @class blink.cmp.config<T>: { [string]: T, [integer]: T }

--- @generic T
--- @param default T
--- @return blink.cmp.config<T>
function M.new_config(default)
  return setmetatable({
    _configs = { ['*'] = vim.deepcopy(default) },
  }, {
    --- @param mode_or_bufnr blink.cmp.Mode | integer
    __index = function(self, mode_or_bufnr)
      vim.validate('name', mode_or_bufnr, { 'string', 'number' })

      local mode = type(mode_or_bufnr) == 'string' and mode_or_bufnr or get_mode()
      local bufnr = type(mode_or_bufnr) == 'number' and mode_or_bufnr or vim.api.nvim_get_current_buf()
      local include_buffer_config = type(mode_or_bufnr) == 'number' or mode == 'default' or mode == 'term'

      -- TODO: use metatable instead of merging every time
      return vim.tbl_deep_extend(
        'force',
        self._configs['*'],
        self._configs[mode] or {},
        include_buffer_config and self._configs[bufnr] or {}
      )
    end,

    --- @param mode_or_bufnr string
    __newindex = function(self, mode_or_bufnr, cfg)
      vim.validate('name', mode_or_bufnr, { 'string', 'number' })
      vim.validate('cfg', cfg, 'table')
      self._configs[mode_or_bufnr] = cfg
    end,

    --- @param filter? blink.cmp.Filter
    __call = function(self, cfg, filter)
      vim.validate('cfg', cfg, 'table')
      vim.validate('filter', filter, 'table', true)
      local normalized_filter = M.normalize_filter(filter)

      if normalized_filter.bufnr ~= nil then
        self._configs[normalized_filter.bufnr] =
          vim.tbl_deep_extend('force', self._configs[normalized_filter.bufnr] or {}, cfg)
      else
        for _, mode in ipairs(normalized_filter.modes) do
          self._configs[mode] = vim.tbl_deep_extend('force', self._configs[mode] or {}, cfg)
        end
      end
    end,
  })
end

--- @param default boolean
function M.new_enable(default)
  local per_mode = vim.deepcopy({
    default = default,
    cmdline = default,
    term = default,
  })
  --- @type table<integer, boolean>
  local per_buffer = {}

  return {
    --- @param enable? boolean
    --- @param filter? blink.cmp.Filter
    enable = function(enable, filter)
      vim.validate('enable', enable, 'boolean', true)
      vim.validate('filter', filter, 'table', true)

      if enable == nil then enable = true end
      local normalized_filter = M.normalize_filter(filter)

      if normalized_filter.bufnr ~= nil then
        per_buffer[normalized_filter.bufnr] = enable
      else
        for _, mode in ipairs(normalized_filter.modes) do
          per_mode[mode] = enable
        end
      end
    end,

    --- @param filter? blink.cmp.Filter
    is_enabled = function(filter)
      vim.validate('filter', filter, 'table', true)
      local normalized_filter = M.normalize_filter(filter)

      assert(#normalized_filter.modes == 1, 'Cannot call cmp.is_enabled with multiple modes')
      local mode = normalized_filter.modes[1]

      if normalized_filter.bufnr ~= nil and per_buffer[normalized_filter.bufnr] ~= nil then
        return per_buffer[normalized_filter.bufnr]
      end
      return per_mode[mode]
    end,
  }
end

--- @class blink.cmp.Filter : blink.cmp.BufferFilter
--- @field bufnr? integer
--- @field mode? blink.cmp.Mode | blink.cmp.Mode[] | '*'

--- @class blink.cmp.NormalizedFilter
--- @field bufnr? integer
--- @field modes blink.cmp.Mode[]

--- @param filter? blink.cmp.Filter
--- @return blink.cmp.NormalizedFilter
function M.normalize_filter(filter)
  if filter == nil then return { modes = { 'default' } } end

  local modes = filter.mode == nil and { 'default' }
    or filter.mode == '*' and { 'default', 'cmdline', 'term' }
    or type(filter.mode) == 'table' and filter.mode
    or { filter.mode }

  if filter.bufnr ~= nil then
    local bufnr = filter.bufnr == 0 and vim.api.nvim_get_current_buf() or filter.bufnr
    return { bufnr = bufnr, modes = modes }
  end
  return { modes = modes }
end

return M
