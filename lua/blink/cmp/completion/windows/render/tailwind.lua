local tailwind = {}

--- @param ctx blink.cmp.DrawItemContext
--- @return string|nil
function tailwind.get_hl(ctx)
  local doc = ctx.item.documentation
  if ctx.kind == 'Color' and doc then
    local content = type(doc) == 'string' and doc or doc.value
    if content and content:match('^#%x%x%x%x%x%x$') then
      local hl_name = 'HexColor' .. content:sub(2)
      if #vim.api.nvim_get_hl(0, { name = hl_name }) == 0 then vim.api.nvim_set_hl(0, hl_name, { fg = content }) end
      return hl_name
    end
  end
end

return tailwind
