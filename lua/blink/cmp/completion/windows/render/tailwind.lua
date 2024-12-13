local tailwind = {}

--- @param ctx blink.cmp.DrawItemContext
--- @return string|nil
function tailwind.get_hex_color(ctx)
  local doc = ctx.item.documentation
  if ctx.kind ~= 'Color' or not doc then return end
  local content = type(doc) == 'string' and doc or doc.value
  if content and content:match('^#%x%x%x%x%x%x$') then return content end
end

--- @param ctx blink.cmp.DrawItemContext
--- @return string|nil
function tailwind.get_hl(ctx)
  local hex_color = tailwind.get_hex_color(ctx)
  if hex_color then return require('blink.cmp.highlights').get_hex_color_highlight(hex_color) end
end

return tailwind
