local tailwind = {}

local kinds = require('blink.cmp.types').CompletionItemKind

--- @param item blink.cmp.CompletionItem
--- @return string|nil
function tailwind.get_hex_color(item)
  local doc = item.documentation
  if item.kind ~= kinds.Color or not doc then return end
  local content = type(doc) == 'string' and doc or doc.value
  if content and content:match('^#%x%x%x%x%x%x$') then return content end
end

--- @param item blink.cmp.CompletionItem
--- @return string?
function tailwind.get_kind_icon(item)
  if tailwind.get_hex_color(item) then return '██' end
end

--- @param ctx blink.cmp.DrawItemContext
--- @return string|nil
function tailwind.get_hl(ctx)
  local hex_color = tailwind.get_hex_color(ctx.item)
  if not hex_color then return end

  local hl_name = 'HexColor' .. hex_color:sub(2)
  if #vim.api.nvim_get_hl(0, { name = hl_name }) == 0 then vim.api.nvim_set_hl(0, hl_name, { fg = hex_color }) end
  return hl_name
end

return tailwind
