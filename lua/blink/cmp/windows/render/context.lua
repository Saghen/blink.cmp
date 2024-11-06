--- @class blink.cmp.DrawItemContext
--- @field self blink.cmp.Draw
--- @field item blink.cmp.CompletionItem
--- @field label string
--- @field label_detail string
--- @field label_description string
--- @field label_matched_indices number[]
--- @field kind string
--- @field kind_icon string
--- @field icon_gap string
--- @field deprecated boolean

local context = {}

--- @param draw blink.cmp.Draw
--- @param items blink.cmp.CompletionItem[]
--- @return blink.cmp.DrawItemContext[]
function context.get_from_items(draw, items)
  local fuzzy = require('blink.cmp.fuzzy')
  local matched_indices =
    fuzzy.fuzzy_matched_indices(fuzzy.get_query(), vim.tbl_map(function(item) return item.label end, items))

  local ctxs = {}
  for idx, item in ipairs(items) do
    ctxs[idx] = context.new(draw, item, matched_indices[idx])
  end
  return ctxs
end

--- @param draw blink.cmp.Draw
--- @param item blink.cmp.CompletionItem
--- @param matched_indices number[]
--- @return blink.cmp.DrawItemContext
function context.new(draw, item, matched_indices)
  local config = require('blink.cmp.config')
  local kind = require('blink.cmp.types').CompletionItemKind[item.kind] or 'Unknown'
  local kind_icon = config.kind_icons[kind] or config.kind_icons.Field
  -- Some LSPs can return labels with newlines.
  -- Escape them to avoid errors in nvim_buf_set_lines when rendering the autocomplete menu.
  local label = item.label:gsub('\n', '\\n')
  if config.nerd_font_variant == 'normal' then label = label:gsub('…', '… ') end

  return {
    self = draw,
    item = item,
    label = label,
    label_detail = item.labelDetails and item.labelDetails.detail or '',
    label_description = item.labelDetails and item.labelDetails.description or '',
    label_matched_indices = matched_indices,
    kind = kind,
    kind_icon = kind_icon,
    icon_gap = config.nerd_font_variant == 'mono' and ' ' or '  ',
    deprecated = item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) or false,
  }
end

return context
