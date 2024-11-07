--- @class blink.cmp.Renderer
--- @field def blink.cmp.Draw
--- @field padding number[]
--- @field gap number
--- @field columns blink.cmp.DrawColumn[]
---
--- @field new fun(draw: blink.cmp.Draw): blink.cmp.Renderer
--- @field draw fun(self: blink.cmp.Renderer, bufnr: number, items: blink.cmp.CompletionItem[])
--- @field get_component_column_location fun(self: blink.cmp.Renderer, component_name: string): { column_idx: number, component_idx: number }
--- @field get_component_start_col fun(self: blink.cmp.Renderer, component_name: string): number
--- @field get_alignment_start_col fun(self: blink.cmp.Renderer): number

local ns = vim.api.nvim_create_namespace('blink_cmp_renderer')

--- @type blink.cmp.Renderer
--- @diagnostic disable-next-line: missing-fields
local renderer = {}

function renderer.new(draw)
  vim.print(draw)
  --- Convert the component names in the columns to the component definitions
  --- @type blink.cmp.DrawComponent[][]
  local columns_definitions = vim.tbl_map(function(column)
    local components = {}
    for _, component_name in ipairs(column) do
      local component = draw.components[component_name]
      assert(component ~= nil, 'No component definition found for component: "' .. component_name .. '"')
      table.insert(components, draw.components[component_name])
    end

    return {
      components = components,
      gap = column.gap or 0,
    }
  end, draw.columns)

  local padding = type(draw.padding) == 'number' and { draw.padding, draw.padding } or draw.padding
  --- @cast padding number[]

  local self = setmetatable({}, { __index = renderer })
  self.padding = padding
  self.gap = draw.gap
  self.def = draw
  self.columns = vim.tbl_map(
    function(column_definition)
      return require('blink.cmp.windows.render.column').new(column_definition.components, column_definition.gap)
    end,
    columns_definitions
  )
  return self
end

function renderer:draw(bufnr, items)
  -- gather contexts
  local ctxs = require('blink.cmp.windows.render.context').get_from_items(self.def, items)

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

function renderer:get_component_column_location(component_name)
  for column_idx, column in ipairs(self.def.columns) do
    for component_idx, other_component_name in ipairs(column) do
      if other_component_name == component_name then return { column_idx, component_idx } end
    end
  end
  error('No component found with name: ' .. component_name)
end

function renderer:get_component_start_col(component_name)
  local column_idx, component_idx = unpack(self:get_component_column_location(component_name))

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

function renderer:get_alignment_start_col()
  local component_name = self.def.align_to_component
  if component_name == nil or component_name == 'none' then return 0 end
  return self:get_component_start_col(component_name)
end

return renderer
