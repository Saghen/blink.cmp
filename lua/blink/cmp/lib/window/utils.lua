local utils = {}

--- @param border blink.cmp.WindowBorder
--- @param default blink.cmp.WindowBorder
--- @return 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow' | 'bold' | 'padded' | string[]
function utils.pick_border(border, default)
  if border ~= nil then return border end

  -- On neovim 0.11+, use the vim.o.winborder option by default
  local has_winborder, winborder = pcall(function() return vim.o.winborder end)
  if has_winborder and winborder ~= '' then return winborder end

  return default or 'none'
end

return utils
