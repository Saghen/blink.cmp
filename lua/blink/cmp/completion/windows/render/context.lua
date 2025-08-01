--- @class blink.cmp.DrawItemContext
--- @field self blink.cmp.Draw
--- @field item blink.cmp.CompletionItem
--- @field idx number
--- @field label string
--- @field label_detail string
--- @field label_description string
--- @field label_matched_indices number[]
--- @field kind string
--- @field kind_icon string
--- @field kind_hl string
--- @field icon_gap string
--- @field deprecated boolean
--- @field source_id string
--- @field source_name string

local draw_context = {}

--- @param context blink.cmp.Context
--- @param draw blink.cmp.Draw
--- @param items blink.cmp.CompletionItem[]
--- @return blink.cmp.DrawItemContext[]
function draw_context.get_from_items(context, draw, items)
  local matched_indices = require('blink.cmp.fuzzy').fuzzy_matched_indices(
    context.get_line(),
    context.get_cursor()[2],
    vim.tbl_map(function(item) return item.label end, items),
    require('blink.cmp.config').completion.keyword.range
  )

  local ctxs = {}
  for idx, item in ipairs(items) do
    ctxs[idx] = draw_context.new(draw, idx, item, matched_indices[idx])
  end
  return ctxs
end

local config = require('blink.cmp.config').appearance
local kinds = require('blink.cmp.types').CompletionItemKind

--- @param draw blink.cmp.Draw
--- @param item_idx number
--- @param item blink.cmp.CompletionItem
--- @param matched_indices number[]
--- @return blink.cmp.DrawItemContext
function draw_context.new(draw, item_idx, item, matched_indices)
  local kind = item.kind_name or kinds[item.kind] or 'Unknown'
  local kind_icon = item.kind_icon or config.kind_icons[kind] or config.kind_icons.Field
  local kind_hl = item.kind_hl or ('BlinkCmpKind' .. (kinds[item.kind] or 'Unknown'))

  local icon_spacing = config.nerd_font_variant == 'mono' and '' or ' '

  -- Some LSPs can return labels with newlines
  -- Escape them to avoid errors in nvim_buf_set_lines when rendering the completion menu
  local newline_char = '↲' .. icon_spacing

  local label = item.label:gsub('\n', newline_char) .. (kind == 'Snippet' and draw.snippet_indicator or '')
  if config.nerd_font_variant == 'normal' then label = label:gsub('…', '… ') end

  local label_detail = (item.labelDetails and item.labelDetails.detail or ''):gsub('\n', newline_char)
  if config.nerd_font_variant == 'normal' then label_detail = label_detail:gsub('…', '… ') end

  local label_description = (item.labelDetails and item.labelDetails.description or ''):gsub('\n', newline_char)
  if config.nerd_font_variant == 'normal' then label_description = label_description:gsub('…', '… ') end

  local source_id = item.source_id
  local source_name = item.source_name

  return {
    self = draw,
    item = item,
    idx = item_idx,
    label = label,
    label_detail = label_detail,
    label_description = label_description,
    label_matched_indices = matched_indices,
    kind = kind,
    kind_icon = kind_icon,
    kind_hl = kind_hl,
    icon_gap = config.nerd_font_variant == 'mono' and '' or ' ',
    deprecated = item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) or false,
    source_id = source_id,
    source_name = source_name,
  }
end

return draw_context
