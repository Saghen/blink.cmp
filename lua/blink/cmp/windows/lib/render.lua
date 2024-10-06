--- @class blink.cmp.Component
--- @field [number] blink.cmp.Component | string
--- @field fill boolean | nil
--- @field hl_group string | nil
--- @field hl_params table | nil

--- @class blink.cmp.RenderedComponentTree
--- @field text string
--- @field highlights { start: number, stop: number, group: string | nil, params: table | nil }[]

local renderer = {}

--- Draws the highlights for the rendered component tree
--- as ephemeral extmarks
--- @param rendered blink.cmp.RenderedComponentTree
function renderer.draw_highlights(rendered, bufnr, ns, line_number)
  for _, highlight in ipairs(rendered.highlights) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, line_number, highlight.start - 1, {
      end_col = highlight.stop - 1,
      hl_group = highlight.group,
      hl_mode = 'combine',
      hl_eol = true,
      ephemeral = true,
    })
  end
end

--- @param components blink.cmp.Component[]
--- @param length number
--- @return blink.cmp.RenderedComponentTree
function renderer.render(components, length)
  local left_of_fill = {}
  local right_of_fill = {}
  local fill = nil
  for _, component in ipairs(components) do
    if component.fill then
      fill = component
    else
      table.insert(fill and right_of_fill or left_of_fill, component)
    end
  end

  local left_rendered = renderer.render_components(left_of_fill)
  local fill_rendered = renderer.render_components({ fill })
  local right_rendered = renderer.render_components(right_of_fill)

  -- expanad/truncate the fill component to the width
  fill_rendered.text = fill_rendered.text
    .. string.rep(' ', length - vim.api.nvim_strwidth(left_rendered.text .. fill_rendered.text .. right_rendered.text))
  fill_rendered.text = fill_rendered.text:sub(
    1,
    length - vim.api.nvim_strwidth(left_rendered.text) - vim.api.nvim_strwidth(right_rendered.text)
  )

  renderer.add_offset_to_rendered_component(fill_rendered, left_rendered.text:len())
  renderer.add_offset_to_rendered_component(right_rendered, left_rendered.text:len() + fill_rendered.text:len())

  local highlights = {}
  vim.list_extend(highlights, left_rendered.highlights)
  vim.list_extend(highlights, fill_rendered.highlights)
  vim.list_extend(highlights, right_rendered.highlights)

  return {
    text = left_rendered.text .. fill_rendered.text .. right_rendered.text,
    highlights = highlights,
  }
end

--- @param components (blink.cmp.Component | string)[]
--- @return blink.cmp.RenderedComponentTree
function renderer.render_components(components)
  local text = ''
  local offset = 0
  local highlights = {}

  for _, component in ipairs(components) do
    if type(component) == 'string' then
      text = text .. component
      offset = offset + #component
    else
      local rendered = renderer.render_components(component)

      renderer.add_offset_to_rendered_component(rendered, offset)
      table.insert(highlights, {
        start = offset + 1,
        stop = offset + #rendered.text + 1,
        group = component.hl_group,
        params = component.hl_params,
      })
      vim.list_extend(highlights, rendered.highlights)

      text = text .. rendered.text
      offset = offset + #rendered.text
    end
  end

  return { text = text, highlights = highlights }
end

--- @param components blink.cmp.Component[]
--- @return number
function renderer.get_length(components)
  local length = 0
  for _, component in ipairs(components) do
    if type(component) == 'string' then
      length = length + #component
    else
      length = length + renderer.get_length(component)
    end
  end
  return length
end

--- @param arr_of_components blink.cmp.Component[][]
--- @return number
function renderer.get_max_length(arr_of_components)
  local max_length = 0
  for _, components in ipairs(arr_of_components) do
    local length = renderer.get_length(components)
    if length > max_length then max_length = length end
  end
  return max_length
end

--- @param component blink.cmp.RenderedComponentTree
--- @param offset number
--- @return blink.cmp.RenderedComponentTree
function renderer.add_offset_to_rendered_component(component, offset)
  for _, highlight in ipairs(component.highlights) do
    highlight.start = highlight.start + offset
    highlight.stop = highlight.stop + offset
  end
  return component
end

return renderer
