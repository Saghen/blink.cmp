local utils = {}

--- @param border blink.cmp.WindowBorder
--- @param default blink.cmp.WindowBorder
--- @return 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow' | 'bold' | 'padded' | string[]
function utils.pick_border(border, default)
  if border ~= nil then return border end

  -- On neovim 0.11+, use the vim.o.winborder option by default
  -- Use `vim.opt.winborder:get()` to handle custom border characters
  if vim.fn.exists('&winborder') == 1 and vim.o.winborder ~= '' then
    local winborder = vim.opt.winborder:get()
    return #winborder == 1 and winborder[1] or winborder
  end

  return default or 'none'
end

return utils
