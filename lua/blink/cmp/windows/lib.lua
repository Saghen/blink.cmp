local win = {}

function win.new(config)
  local self = setmetatable({}, { __index = win })

  self.id = nil
  self.config = {
    min_width = config.min_width or 30,
    max_width = config.max_width or 60,
    max_height = config.max_height or 10,
    cursorline = config.cursorline or false,
    wrap = config.wrap or false,
    filetype = config.filetype or 'cmp_menu',
    winhighlight = config.winhighlight or 'Normal:NormalFloat,FloatBorder:NormalFloat',
    padding = config.padding,
  }

  return self
end

function win:get_buf()
  -- create buffer if it doesn't exist
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then
    self.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('tabstop', 1, { buf = self.buf }) -- prevents tab widths from being unpredictable
    vim.api.nvim_set_option_value('filetype', self.config.filetype, { buf = self.buf })
  end
  return self.buf
end

function win:get_win()
  -- re-open if the window is supposed to be open but isn't valid
  if self.id ~= nil and not vim.api.nvim_win_is_valid(self.id) then self:open() end
  return self.id
end

function win:is_open() return self.id ~= nil and vim.api.nvim_win_is_valid(self.id) end

function win:open()
  -- window already exists
  if self.id ~= nil and vim.api.nvim_win_is_valid(self.id) then return end

  -- create window
  self.id = vim.api.nvim_open_win(self:get_buf(), false, {
    relative = 'cursor',
    style = 'minimal',
    width = self.config.min_width,
    height = self.config.max_height,
    row = 1,
    col = 1,
    focusable = false,
    zindex = 1001,
    border = self.config.padding and { ' ', '', '', '', '', '', ' ', ' ' } or { '', '', '', '', '', '', '', '' },
  })
  vim.api.nvim_set_option_value('winhighlight', self.config.winhighlight, { win = self.id })
  vim.api.nvim_set_option_value('wrap', self.config.wrap, { win = self.id })
  vim.api.nvim_set_option_value('foldenable', false, { win = self.id })
  vim.api.nvim_set_option_value('conceallevel', 2, { win = self.id })
  vim.api.nvim_set_option_value('concealcursor', 'n', { win = self.id })
  vim.api.nvim_set_option_value('cursorlineopt', 'line', { win = self.id })
  vim.api.nvim_set_option_value('cursorline', self.config.cursorline, { win = self.id })
end

function win:close()
  if self.id ~= nil then
    vim.api.nvim_win_close(self.id, true)
    self.id = nil
  end
end

-- todo: move this code to the individual windows
function win:update_position(relative_to, offset)
  if not self:is_open() then return end
  local winnr = self:get_win()
  local config = self.config

  -- todo: should be global cursor position and screen size
  local screen_height = vim.api.nvim_win_get_height(0)
  local screen_width = vim.api.nvim_win_get_width(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1]
  local cursor_col = cursor[2]

  -- set width to current content width, bounded by min and max
  -- todo: should be determined based on the items since we format the items to the current width
  -- so the get_content_width() will always be the window width
  local width = math.max(math.min(self:get_content_width(), config.max_width), config.min_width)
  vim.api.nvim_win_set_width(winnr, width)

  -- set height to current line count, bounded by max
  local height = math.min(self:get_content_height(), config.max_height)
  vim.api.nvim_win_set_height(winnr, height)

  if relative_to == 'cursor' then
    local is_space_below = screen_height - cursor_row > height

    if is_space_below then
      vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = 1, col = offset })
    else
      vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = -height, col = offset })
    end

  -- relative to window
  elseif type(relative_to) == 'number' then
    local relative_win_config = vim.api.nvim_win_get_config(relative_to)

    -- todo: why is there a -7 here? probably the signcolumn stuff?
    local max_width_right = screen_width - cursor_col - relative_win_config.width - 7
    local max_width_left = cursor_col

    if max_width_right >= width or max_width_right >= max_width_left then
      vim.api.nvim_win_set_config(winnr, {
        relative = 'win',
        win = relative_to,
        row = 0,
        col = relative_win_config.width,
        width = width,
      })
    else
      vim.api.nvim_win_set_config(winnr, {
        relative = 'win',
        win = relative_to,
        row = 0,
        col = -width,
        width = width,
      })
    end
  else
    error('Invalid relative config')
  end
end

-- todo: fix nvim_win_text_height
function win:get_content_height()
  if not self:is_open() then return 0 end
  return vim.api.nvim_win_text_height(self:get_win(), {}).all
end

function win:get_content_width()
  if not self:is_open() then return 0 end
  local max_width = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)) do
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
  end
  return max_width
end

return win
