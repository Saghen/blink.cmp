--- @class blink.cmp.Component
--- @field [number] blink.cmp.Component | string
--- @field fill? boolean
--- @field max_width? number
--- @field hl_group? string
--- @field hl_params? table

--- @class blink.cmp.RenderedComponentTree
--- @field text string
--- @field highlights { start: number, stop: number, group?: string, params?: table }[]

--- @class blink.cmp.StringsBuild
--- @field text string
--- @field length number

local renderer = {}

---@param text string
---@param max_width number
---@return string
function renderer.truncate_text(text, max_width)
  if vim.api.nvim_strwidth(text) > max_width then
    return vim.fn.strcharpart(text, 0, max_width) .. '…'
  else
    return text
  end
end

--- Draws the highlights for the rendered component tree
--- as ephemeral extmarks
--- @param rendered blink.cmp.RenderedComponentTree
function renderer.draw_highlights(rendered, bufnr, ns, line_number)
  for _, highlight in ipairs(rendered.highlights) do
    if highlight.group == "BlinkCmpLabel" then return end
    vim.api.nvim_buf_set_extmark(bufnr, ns, line_number, highlight.start - 1, {
      end_col = highlight.stop - 1,
      hl_group = highlight.group,
      hl_mode = 'combine',
      hl_eol = true,
      ephemeral = true,
    })
  end
end

--- Gets the concatenated text and length for a list of strings
--- and truncates if necessary when max_width is set
--- @param strings string[]
--- @param max_width? number
--- @return blink.cmp.StringsBuild
function renderer.concat_strings(strings, max_width)
  local text = ''
  for _, component in ipairs(strings) do
    text = text .. component
  end

  if max_width then text = renderer.truncate_text(text, max_width) end
  return { text = text, length = vim.api.nvim_strwidth(text) }
end

--- @param components (blink.cmp.Component | string)[]
--- @param lengths number[]
--- @return blink.cmp.RenderedComponentTree
function renderer.render(components, lengths)
  local text = ''
  local offset = 0
  local highlights = {}

  for i, component in ipairs(components) do
    if type(component) == 'string' then
      text = text .. component
      offset = offset + #component
    else
      local concatenated = renderer.concat_strings(component, component.max_width)

      table.insert(highlights, {
        start = offset + 1,
        stop = offset + #concatenated.text + 1,
        group = component.hl_group,
        params = component.hl_params,
      })

      text = text .. concatenated.text
      offset = offset + #concatenated.text

      if component.fill then
        local spaces = lengths[i] - concatenated.length
        text = text .. string.rep(' ', spaces)
        offset = offset + spaces
      end
    end
  end

  return { text = text, highlights = highlights }
end

--- @param component blink.cmp.Component | string
--- @return number
function renderer.get_length(component)
  if type(component) == 'string' then
    return vim.api.nvim_strwidth(component)
  else
    local build = renderer.concat_strings(component, component.max_width)
    return build.length
  end
end

--- @param components_list (blink.cmp.Component | string)[][]
--- @param min_width number
--- @return number[]
function renderer.get_max_lengths(components_list, min_width)
  local lengths = {}
  local first_fill

  for _, components in ipairs(components_list) do
    for i, component in ipairs(components) do
      local length = renderer.get_length(component)
      if not lengths[i] or lengths[i] < length then lengths[i] = length end
      if component.fill and not first_fill then first_fill = i end
    end
  end

  for _, length in ipairs(lengths) do
    min_width = min_width - length
  end

  first_fill = first_fill or 1
  if min_width > 0 then lengths[first_fill] = lengths[first_fill] + min_width end

  return lengths
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
