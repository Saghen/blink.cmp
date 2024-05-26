local win = {}

win.new = function(config)
  local self = setmetatable({}, { __index = win })

  self.id = nil
  self.config = {
    width = config.width or 40,
    max_height = config.max_height or 10,
    relative = config.relative or 'cursor',
    cursorline = config.cursorline or false,
    wrap = config.wrap or false,
    filetype = config.filetype or 'cmp_menu',
    winhighlight = config.winhighlight or 'Normal:NormalFloat,FloatBorder:NormalFloat',
    padding = config.padding,
  }

  win.temp_buf_hack(self)

  return self
end

win.temp_buf_hack = function(self)
  -- create buffer if it doesn't exist
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then
    self.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(self.buf, 'tabstop', 1) -- prevents tab widths from being unpredictable
    vim.api.nvim_buf_set_option(self.buf, 'filetype', self.config.filetype)
  end
end

win.open = function(self)
  -- window already exists
  if self.id ~= nil then return end

  win.temp_buf_hack(self)

  -- create window
  self.id = vim.api.nvim_open_win(self.buf, false, {
    relative = 'cursor',
    style = 'minimal',
    width = self.config.width,
    height = self.config.max_height,
    row = 1,
    col = 1,
    focusable = false,
    zindex = 1001,
    border = self.config.padding and { ' ', '', '', '', '', '', ' ', ' ' } or { '', '', '', '', '', '', '', '' },
  })
  vim.api.nvim_win_set_option(self.id, 'winhighlight', self.config.winhighlight)
  vim.api.nvim_win_set_option(self.id, 'wrap', self.config.wrap)
  vim.api.nvim_win_set_option(self.id, 'foldenable', false)
  vim.api.nvim_win_set_option(self.id, 'conceallevel', 2)
  vim.api.nvim_win_set_option(self.id, 'concealcursor', 'n')
  vim.api.nvim_win_set_option(self.id, 'cursorlineopt', 'line')
  vim.api.nvim_win_set_option(self.id, 'cursorline', self.config.cursorline)

  self:update()
end

win.close = function(self)
  if self.id ~= nil then
    vim.api.nvim_win_close(self.id, true)
    self.id = nil
  end
end

win.update = function(self)
  if self.id ~= nil then
    -- todo: should be global cursor position and screen size
    local screen_height = vim.api.nvim_win_get_height(0)
    local screen_width = vim.api.nvim_win_get_width(0)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_row = cursor[1]
    local cursor_col = cursor[2]

    -- set height to current line count
    local height = math.min(self:get_content_height(), self.config.max_height)
    vim.api.nvim_win_set_height(self.id, height)

    -- relative to cursor
    if self.config.relative == 'cursor' then
      local is_space_below = screen_height - cursor_row > height

      if is_space_below then
        vim.api.nvim_win_set_config(self.id, { relative = 'cursor', row = 1, col = 0 })
      else
        vim.api.nvim_win_set_config(self.id, { relative = 'cursor', row = -height, col = 0 })
      end
    -- relative to window
    elseif self.config.relative.id ~= nil then
      local relative_win_config = vim.api.nvim_win_get_config(self.config.relative.id)

      -- todo: why is there a -5 here?
      local max_width_right = screen_width - cursor_col - relative_win_config.width - 5
      local max_width_left = cursor_col

      local width = math.min(math.max(max_width_left, max_width_right), self.config.width)

      if max_width_right >= self.config.width or max_width_right >= max_width_left then
        vim.api.nvim_win_set_config(self.id, {
          relative = 'win',
          win = self.config.relative.id,
          row = 0,
          col = relative_win_config.width,
          width = width,
        })
      else
        vim.api.nvim_win_set_config(self.id, {
          relative = 'win',
          win = self.config.relative.id,
          row = 0,
          col = -width,
          width = width,
        })
      end
    -- No idea what it's supposed to be relative to
    else
      self:close()
    end
  end
end

-- todo: fix nvim_win_text_height
win.get_content_height = function(self)
  return vim.api.nvim_win_text_height(self.id, {}).all
  --
  -- if not self.config.wrap then return vim.api.nvim_buf_line_count(self.buf) end
  -- local height = 0
  -- vim.api.nvim_buf_call(self.buf, function()
  --   for _, text in ipairs(vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)) do
  --     height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(text) / self.config.width))
  --   end
  -- end)
  -- return height
end

return win
