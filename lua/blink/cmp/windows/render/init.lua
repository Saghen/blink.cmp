--- @class blink.cmp.Renderer
--- @field draw blink.cmp.Draw
--- @field padding number[]
--- @field gap number
--- @field columns blink.cmp.DrawColumn[]
---
--- @field new fun(draw: blink.cmp.Draw): blink.cmp.Renderer
--- @field render fun(self: blink.cmp.Renderer, bufnr: number, items: blink.cmp.CompletionItem[])

local ns = vim.api.nvim_create_namespace('blink_cmp_renderer')

--- @type blink.cmp.Draw
local draw = {
  padding = 1,
  gap = 1,
  columns = { { 'kind_icon' }, { 'label', 'detail' } },
  components = {
    kind_icon = {
      ellipsis = false,
      text = function(ctx) return ctx.kind_icon .. ' ' end,
      highlight = function(ctx) return 'BlinkCmpKind' .. ctx.kind end,
    },

    label = {
      width = { fill = true, min = 20, max = 60 },
      text = function(ctx) return ctx.label .. (ctx.label_details or '') end,
      highlight = function(ctx)
        -- label and label details
        local highlights = {
          { 0, #ctx.label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
        }
        if ctx.label_details then
          table.insert(highlights, { #ctx.label + 1, #ctx.label + #ctx.label_details, group = 'BlinkCmpLabelDetails' })
        end

        -- characters matched on the label by the fuzzy matcher
        if ctx.label_matched_indices ~= nil then
          for _, idx in ipairs(ctx.label_matched_indices) do
            table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
          end
        end

        -- TODO: treesitter highlighting

        return highlights
      end,
    },

    detail = {
      width = { max = 40 },
      text = function(ctx) return ctx.item.detail or '' end,
      highlight = 'BlinkCmpLabelDetail',
    },
  },
}

--- @type blink.cmp.Renderer
--- @diagnostic disable-next-line: missing-fields
local renderer = {}

function renderer.new(_)
  --- Convert the component names in the columns to the component definitions
  --- @type blink.cmp.DrawComponent[][]
  local columns_components = vim.tbl_map(function(column)
    return vim.tbl_map(function(component_name)
      local component = draw.components[component_name]
      assert(component ~= nil, 'No component definition found for component: "' .. component_name .. '"')
      return component
    end, column)
  end, draw.columns)

  local padding = type(draw.padding) == 'number' and { draw.padding, draw.padding } or draw.padding
  --- @cast padding number[]

  local self = setmetatable({}, { __index = renderer })
  self.padding = padding
  self.gap = draw.gap
  self.draw = draw
  self.columns = vim.tbl_map(
    function(components) return require('blink.cmp.windows.render.column').new(components) end,
    columns_components
  )
  return self
end

function renderer:render(bufnr, items)
  -- gather contexts
  local ctxs = require('blink.cmp.windows.render.context').get_from_items(items)

  -- render the columns
  for _, column in ipairs(self.columns) do
    column:render(ctxs)
  end

  -- apply to the buffer
  local lines = {}
  for idx, _ in ipairs(ctxs) do
    local line = ''
    if self.padding[1] > 0 then line = string.rep(' ', self.padding[1]) end

    for column_idx, column in ipairs(self.columns) do
      line = line .. column:get_line_text(idx)
      if column_idx ~= #self.columns then line = line .. string.rep(' ', self.gap) end
    end

    if self.padding[2] > 0 then line = line .. string.rep(' ', self.padding[2]) end

    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })

  -- Setting highlights is slow and we update on every keystroke so we instead use a decoration provider
  -- which will only render highlights of the visible lines. This also avoids having to do virtual scroll
  -- like nvim-cmp does, which breaks on UIs like neovide
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, win_bufnr) return bufnr == win_bufnr end,
    on_line = function(_, _, _, line_number)
      local offset = self.padding[1]
      local highlights = {}

      for _, column in ipairs(self.columns) do
        local highlights_for_column = column:get_line_highlights(line_number + 1)
        for _, highlight in ipairs(highlights_for_column) do
          table.insert(highlights, {
            offset + highlight[1],
            offset + highlight[2],
            group = highlight.group,
            params = highlight.params,
          })
        end
        offset = offset + #column:get_line_text(line_number + 1) + self.gap
      end

      for _, highlight in ipairs(highlights) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, line_number, highlight[1], {
          end_col = highlight[2],
          hl_group = highlight.group,
          hl_mode = 'combine',
          hl_eol = true,
          ephemeral = true,
        })
      end
    end,
  })
end

function renderer:get_component_location(component_name)
  for column_idx, column in ipairs(self.draw.columns) do
    for component_idx, other_component_name in ipairs(column) do
      if other_component_name == component_name then return { column_idx, component_idx } end
    end
  end
  error('No component found with name: ' .. component_name)
end

function renderer:get_component_start_col(component_name)
  local column_idx, component_idx = unpack(self:get_component_location(component_name))

  -- add previous columns
  local start_col = self.padding[1]
  for i = 1, column_idx - 1 do
    start_col = start_col + self.columns[i].width + self.gap
  end

  -- add previous components
  local line = self.columns[column_idx].lines[1]
  if not line then return start_col end
  for i = 1, component_idx - 1 do
    start_col = start_col + #line[i]
  end

  return start_col
end

return renderer
