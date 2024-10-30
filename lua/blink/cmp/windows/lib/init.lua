local win = {}

--- @class blink.cmp.WindowOptions
--- @field min_width? number
--- @field max_width? number
--- @field max_height number
--- @field cursorline boolean
--- @field border blink.cmp.WindowBorder
--- @field wrap boolean
--- @field filetype string
--- @field winhighlight string
--- @field scrolloff number

--- @class blink.cmp.Window
--- @field id? number
--- @field config blink.cmp.WindowOptions
---
--- @param config blink.cmp.WindowOptions
function win.new(config)
  local self = setmetatable({}, { __index = win })

  self.id = nil
  self.config = {
    min_width = config.min_width,
    max_width = config.max_width,
    max_height = config.max_height or 10,
    cursorline = config.cursorline or false,
    border = config.border or 'none',
    wrap = config.wrap or false,
    filetype = config.filetype or 'cmp_menu',
    winhighlight = config.winhighlight or 'Normal:NormalFloat,FloatBorder:NormalFloat',
    scrolloff = config.scrolloff or 0,
  }

  return self
end

--- @return number
function win:get_buf()
  -- create buffer if it doesn't exist
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then
    self.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('tabstop', 1, { buf = self.buf }) -- prevents tab widths from being unpredictable
    vim.api.nvim_set_option_value('filetype', self.config.filetype, { buf = self.buf })
    vim.treesitter.stop(self.buf)
  end
  return self.buf
end

--- @return number
function win:get_win()
  if self.id ~= nil and not vim.api.nvim_win_is_valid(self.id) then self.id = nil end
  return self.id
end

--- @return boolean
function win:is_open() return self.id ~= nil and vim.api.nvim_win_is_valid(self.id) end

function win:open()
  -- window already exists
  if self.id ~= nil and vim.api.nvim_win_is_valid(self.id) then return end

  -- create window
  self.id = vim.api.nvim_open_win(self:get_buf(), false, {
    relative = 'cursor',
    style = 'minimal',
    width = self.config.min_width or 1,
    height = self.config.max_height,
    row = 1,
    col = 1,
    focusable = false,
    zindex = 1001,
    border = self.config.border == 'padded' and { ' ', '', '', ' ', '', '', ' ', ' ' } or self.config.border,
  })
  vim.api.nvim_set_option_value('winhighlight', self.config.winhighlight, { win = self.id })
  vim.api.nvim_set_option_value('wrap', self.config.wrap, { win = self.id })
  vim.api.nvim_set_option_value('foldenable', false, { win = self.id })
  vim.api.nvim_set_option_value('conceallevel', 2, { win = self.id })
  vim.api.nvim_set_option_value('concealcursor', 'n', { win = self.id })
  vim.api.nvim_set_option_value('cursorlineopt', 'line', { win = self.id })
  vim.api.nvim_set_option_value('cursorline', self.config.cursorline, { win = self.id })
  vim.api.nvim_set_option_value('scrolloff', self.config.scrolloff, { win = self.id })
end

function win:set_option_values(option, value) vim.api.nvim_set_option_value(option, value, { win = self.id }) end

function win:close()
  if self.id ~= nil then
    vim.api.nvim_win_close(self.id, true)
    self.id = nil
  end
end

function win:update_size()
  if not self:is_open() then return end
  local winnr = self:get_win()
  local config = self.config

  -- todo: never go above the screen width and height

  -- set width to current content width, bounded by min and max
  local width = self:get_content_width()
  if config.max_width then width = math.min(width, config.max_width) end
  if config.min_width then width = math.max(width, config.min_width) end
  vim.api.nvim_win_set_width(winnr, width)

  -- set height to current line count, bounded by max
  local height = math.min(self:get_content_height(), config.max_height)
  vim.api.nvim_win_set_height(winnr, height)
end

-- todo: fix nvim_win_text_height
-- @return number
function win:get_content_height()
  if not self:is_open() then return 0 end
  return vim.api.nvim_win_text_height(self:get_win(), {}).all
end

--- @return { vertical: number, horizontal: number, left: number, right: number, top: number, bottom: number }
function win:get_border_size()
  if not self:is_open() then return { vertical = 0, horizontal = 0, left = 0, right = 0, top = 0, bottom = 0 } end

  local border = self.config.border
  if border == 'none' then
    return { vertical = 0, horizontal = 0, left = 0, right = 0, top = 0, bottom = 0 }
  elseif border == 'padded' then
    return { vertical = 0, horizontal = 1, left = 1, right = 0, top = 0, bottom = 0 }
  elseif border == 'shadow' then
    return { vertical = 1, horizontal = 1, left = 0, right = 1, top = 0, bottom = 1 }
  elseif type(border) == 'string' then
    return { vertical = 2, horizontal = 2, left = 1, right = 1, top = 1, bottom = 1 }
  elseif type(border) == 'table' and border ~= nil then
    -- borders can be a table of strings and act differently with different # of chars
    -- so we normalize it: https://neovim.io/doc/user/api.html#nvim_open_win()
    -- based on nvim-cmp
    local resolved_border = {}
    while #resolved_border <= 8 do
      for _, b in ipairs(border) do
        table.insert(resolved_border, type(b) == 'string' and b or b[1])
      end
    end

    local top = resolved_border[2] == '' and 0 or 1
    local bottom = resolved_border[6] == '' and 0 or 1
    local left = resolved_border[8] == '' and 0 or 1
    local right = resolved_border[4] == '' and 0 or 1
    return { vertical = top + bottom, horizontal = left + right, left = left, right = right, top = top, bottom = bottom }
  end

  return { vertical = 0, horizontal = 0, left = 0, right = 0, top = 0, bottom = 0 }
end

--- @return number
function win:get_height()
  if not self:is_open() then return 0 end
  return vim.api.nvim_win_get_height(self:get_win()) + self:get_border_size().vertical
end

--- @return number
function win:get_content_width()
  if not self:is_open() then return 0 end
  local max_width = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)) do
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
  end
  return max_width
end

--- @return number
function win:get_width()
  if not self:is_open() then return 0 end
  return vim.api.nvim_win_get_width(self:get_win()) + self:get_border_size().horizontal
end

--- Gets the cursor's distance from the top and bottom of the window
--- @return { distance_from_top: number, distance_from_bottom: number }
function win.get_cursor_screen_position()
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Calculate the visual distance from top of the window sinc the vim.fn.line()
  -- func gives the literal line number but there can be folds.
  -- HACK: ideally there's a more generic solution since vertical conceal
  -- will be added in the future
  local distance_from_top = 0
  local line = math.max(1, vim.fn.line('w0'))
  while line < cursor_line do
    distance_from_top = distance_from_top + 1
    if vim.fn.foldclosedend(line) ~= -1 then line = vim.fn.foldclosedend(line) end
    line = line + 1
  end

  local distance_from_bottom = win_height - distance_from_top - 1

  return {
    distance_from_bottom = distance_from_bottom,
    distance_from_top = distance_from_top,
  }
end

return win
