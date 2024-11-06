--- @class blink.cmp.DrawColumn
--- @field components blink.cmp.DrawComponent[]
--- @field lines string[][]
--- @field width number
--- @field ctxs blink.cmp.CompletionRenderContext[]
---
--- @field new fun(components: blink.cmp.DrawComponent[]): blink.cmp.DrawColumn
--- @field render fun(self: blink.cmp.DrawColumn, ctxs: blink.cmp.DrawItemContext[])
--- @field get_line_text fun(self: blink.cmp.DrawColumn, line_idx: number): string[]
--- @field get_line_highlights fun(self: blink.cmp.DrawColumn, line_idx: number): blink.cmp.DrawHighlight[]

local text_lib = require('blink.cmp.windows.render.text')

--- @type blink.cmp.DrawColumn
--- @diagnostic disable-next-line: missing-fields
local column = {}

function column.new(components)
  local self = setmetatable({}, { __index = column })
  self.components = components
  self.lines = {}
  self.width = 0
  self.ctxs = {}
  return self
end

function column:render(ctxs)
  --- render text and get the max widths of each component
  --- @type string[][]
  local lines = {}
  local max_component_widths = {}
  for _, ctx in ipairs(ctxs) do
    --- @type string[]
    local line = {}
    for component_idx, component in ipairs(self.components) do
      local text = text_lib.apply_component_width(component.text(ctx) or '', component)
      table.insert(line, text)
      max_component_widths[component_idx] =
        math.max(max_component_widths[component_idx] or 0, vim.api.nvim_strwidth(text))
    end
    table.insert(lines, line)
  end

  --- get the total width of the column
  local column_width = 0
  for _, max_component_width in ipairs(max_component_widths) do
    column_width = column_width + max_component_width
  end

  --- find the component that will fill the empty space
  local fill_idx = -1
  for component_idx, component in ipairs(self.components) do
    if component.width and component.width.fill then
      fill_idx = component_idx
      break
    end
  end
  if fill_idx == -1 then fill_idx = #self.components end

  --- and add extra spaces until we reach the column width
  for _, line in ipairs(lines) do
    local line_width = 0
    for _, component_text in ipairs(line) do
      line_width = line_width + vim.api.nvim_strwidth(component_text)
    end
    local remaining_width = column_width - line_width
    line[fill_idx] = text_lib.pad(line[fill_idx], vim.api.nvim_strwidth(line[fill_idx]) + remaining_width)
  end

  -- store results for later
  self.width = column_width
  self.lines = lines
  self.ctxs = ctxs
end

function column:get_line_text(line_idx)
  local line = self.lines[line_idx]
  local concatenated = ''
  for _, component in ipairs(line) do
    concatenated = concatenated .. component
  end
  return concatenated
end

function column:get_line_highlights(line_idx)
  local ctx = self.ctxs[line_idx]
  local offset = 0
  local highlights = {}

  for component_idx, component in ipairs(self.components) do
    local text = self.lines[line_idx][component_idx]

    local column_highlights = type(component.highlight) == 'function' and component.highlight(ctx, text)
      or component.highlight

    if type(column_highlights) == 'string' then
      table.insert(highlights, { offset, offset + #text, group = column_highlights })
    elseif type(column_highlights) == 'table' then
      for _, highlight in ipairs(column_highlights) do
        table.insert(highlights, {
          offset + highlight[1],
          offset + highlight[2],
          group = highlight.group,
          params = highlight.params,
        })
      end
    end

    offset = offset + #text
  end

  return highlights
end

return column
