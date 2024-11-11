--- Helper for calculating placement of the scrollbar thumb and gutter

--- @class blink.cmp.ScrollbarGeometry
--- @field width number
--- @field height number
--- @field row number
--- @field col number
--- @field zindex number
--- @field relative string
--- @field win number

local M = {}

--- @param target_win number
--- @return number
local function get_win_buf_height(target_win)
  local buf = vim.api.nvim_win_get_buf(target_win)

  -- not wrapping, so just get the line count
  if not vim.wo[target_win].wrap then return vim.api.nvim_buf_line_count(buf) end

  local width = vim.api.nvim_win_get_width(target_win)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, (math.ceil(vim.fn.strwidth(l) / width)))
  end
  return height
end

--- @param border string|string[]
--- @return number
local function get_col_offset(border)
  -- we only need an extra offset when working with a padded window
  if type(border) == 'table' and border[1] == ' ' and border[4] == ' ' and border[7] == ' ' and border[8] == ' ' then
    return 1
  end
  return 0
end

--- @param target_win number
--- @return { should_hide: boolean, thumb: blink.cmp.ScrollbarGeometry, gutter: blink.cmp.ScrollbarGeometry }
function M.get_geometry(target_win)
  local config = vim.api.nvim_win_get_config(target_win)
  local width = config.width
  local height = config.height
  local zindex = config.zindex

  local buf_height = get_win_buf_height(target_win)
  local start_line = math.max(1, vim.fn.line('w0', target_win))
  local pct = (start_line - 1) / (buf_height - height)
  local thumb_height = math.max(1, math.floor(height * height / buf_height + 0.5) - 1)
  local thumb_offset = math.floor((pct * (height - thumb_height)) + 0.5)

  local common_geometry = {
    width = 1,
    row = thumb_offset,
    col = width + get_col_offset(config.border),
    relative = 'win',
    win = target_win,
  }

  return {
    should_hide = height >= buf_height,
    thumb = vim.tbl_deep_extend('force', common_geometry, { height = thumb_height, zindex = zindex + 2 }),
    gutter = vim.tbl_deep_extend('force', common_geometry, { row = 0, height = height, zindex = zindex + 1 }),
  }
end

return M
