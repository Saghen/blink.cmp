--- @class blink.cmp.Renderer
--- @field def blink.cmp.Draw
--- @field padding number[]
--- @field gap number
--- @field columns blink.cmp.DrawColumn[]
---
--- @field new fun(draw: blink.cmp.Draw): blink.cmp.Renderer
--- @field draw fun(self: blink.cmp.Renderer, context: blink.cmp.Context, bufnr: number, items: blink.cmp.CompletionItem[])
--- @field get_component_column_location fun(self: blink.cmp.Renderer, component_name: string): { column_idx: number, component_idx: number }
--- @field get_component_start_col fun(self: blink.cmp.Renderer, component_name: string): number
--- @field get_alignment_start_col fun(self: blink.cmp.Renderer): number

local ns = vim.api.nvim_create_namespace('blink_cmp_renderer')

--- @type blink.cmp.Renderer
--- @diagnostic disable-next-line: missing-fields
local renderer = {}

function renderer.new(draw)
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
      return require('blink.cmp.completion.windows.render.column').new(
        column_definition.components,
        column_definition.gap
      )
    end,
    columns_definitions
  )
  return self
end

function renderer:draw(context, bufnr, items)
  -- gather contexts
  local draw_contexts = require('blink.cmp.completion.windows.render.context').get_from_items(context, self.def, items)

  -- render the columns
  for _, column in ipairs(self.columns) do
    column:render(draw_contexts)
  end

  -- apply to the buffer
  local lines = {}
  for idx, _ in ipairs(draw_contexts) do
    local line = ''
    if self.padding[1] > 0 then line = string.rep(' ', self.padding[1]) end

    for _, column in ipairs(self.columns) do
      local text = column:get_line_text(idx)
      if #text > 0 then line = line .. text .. string.rep(' ', self.gap) end
    end
    line = line:sub(1, -self.gap - 1)

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
    on_line = function(_, _, _, line)
      local offset = self.padding[1]
      for _, column in ipairs(self.columns) do
        local text = column:get_line_text(line + 1)
        if #text > 0 then
          local highlights = column:get_line_highlights(line + 1)
          for _, highlight in ipairs(highlights) do
            local col = offset + highlight[1]
            local end_col = offset + highlight[2]
            vim.api.nvim_buf_set_extmark(bufnr, ns, line, col, {
              end_col = end_col,
              hl_group = highlight.group,
              hl_mode = 'combine',
              hl_eol = true,
              ephemeral = true,
            })
          end
          offset = offset + #text + self.gap
        end
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
