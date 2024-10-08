--- @class blink.cmp.CompletionRenderContext
--- @field item blink.cmp.CompletionItem
--- @field kind string
--- @field kind_icon string
--- @field icon_gap string
--- @field deprecated boolean

local config = require('blink.cmp.config')
local renderer = require('blink.cmp.windows.lib.render')
local autocmp_config = config.windows.autocomplete
local autocomplete = {
  items = {},
  context = nil,
  event_targets = {
    on_position_update = {},
    on_select = function() end,
    on_close = function() end,
  },
}

function autocomplete.setup()
  autocomplete.win = require('blink.cmp.windows.lib').new({
    min_width = autocmp_config.min_width,
    max_width = autocmp_config.max_width,
    max_height = autocmp_config.max_height,
    border = autocmp_config.border,
    winhighlight = autocmp_config.winhighlight,
    cursorline = true,
    scrolloff = autocmp_config.scrolloff,
  })

  -- Setting highlights is slow and we update on every keystroke so we instead use a decoration provider
  -- which will only render highlights of the visible lines. This also avoids having to do virtual scroll
  -- like nvim-cmp does, which breaks on UIs like neovide
  vim.api.nvim_set_decoration_provider(config.highlight.ns, {
    on_win = function(_, winnr, bufnr)
      return autocomplete.win:get_win() == winnr and bufnr == autocomplete.win:get_buf()
    end,
    on_line = function(_, _, bufnr, line_number)
      local rendered_item = autocomplete.rendered_items[line_number + 1]
      if rendered_item == nil then return end
      renderer.draw_highlights(rendered_item, bufnr, config.highlight.ns, line_number)
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'WinScrolled', 'WinResized' }, {
    callback = function()
      if autocomplete.context == nil then return end
      autocomplete.update_position(autocomplete.context)
    end,
  })

  return autocomplete
end

---------- Visibility ----------

function autocomplete.open_with_items(context, items)
  autocomplete.context = context
  autocomplete.items = items
  autocomplete.draw()

  autocomplete.win:open()

  autocomplete.context = context
  autocomplete.update_position(context)

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item(), context)
end

function autocomplete.open()
  if autocomplete.win:is_open() then return end
  autocomplete.win:open()
end

function autocomplete.close()
  if not autocomplete.win:is_open() then return end
  autocomplete.win:close()
  autocomplete.event_targets.on_close()
end
function autocomplete.listen_on_close(callback) autocomplete.event_targets.on_close = callback end

--- @param context blink.cmp.Context
--- TODO: Don't switch directions if the context is the same
function autocomplete.update_position(context)
  local win = autocomplete.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local height = win:get_height()
  local screen_height = vim.api.nvim_win_get_height(0)
  local screen_scroll_range = win.get_screen_scroll_range()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1]
  local cursor_col = cursor[2]

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local col = context.bounds.start_col - cursor_col - 1

  -- detect if there's space above/below the cursor
  -- todo: should pick the largest space if both are false and limit height of the window
  local is_space_below = screen_height - (cursor_row - screen_scroll_range.start_line) >= height
  local is_space_above = cursor_row - screen_scroll_range.start_line > height

  -- default to the user's preference but attempt to use the other options
  local row = autocmp_config.direction_priority[1] == 's' and 1 or -height
  for _, direction in ipairs(autocmp_config.direction_priority) do
    if direction == 's' and is_space_below then
      row = 1
      break
    elseif direction == 'n' and is_space_above then
      row = -height
      break
    end
  end

  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col })

  for _, callback in ipairs(autocomplete.event_targets.on_position_update) do
    callback()
  end
end

function autocomplete.listen_on_position_update(callback)
  table.insert(autocomplete.event_targets.on_position_update, callback)
end

---------- Selection ----------

function autocomplete.select_next()
  if not autocomplete.win:is_open() then return end

  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  local line_count = vim.api.nvim_buf_line_count(autocomplete.win:get_buf())
  local cycle_from_bottom = config.windows.autocomplete.cycle.from_bottom
  local is_last_completion = current_line == line_count

  -- at the end of completion list and the config is not enabled: do nothing
  if is_last_completion and not cycle_from_bottom then return end
  if is_last_completion then
    -- at the end of completion list and the config is enabled: cycle back to first completion
    vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
    autocomplete.event_targets.on_select(autocomplete.get_selected_item(), autocomplete.context)
  else
    -- select next completion
    vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { current_line + 1, 0 })
    autocomplete.event_targets.on_select(autocomplete.get_selected_item(), autocomplete.context)
  end
end

function autocomplete.select_prev()
  if not autocomplete.win:is_open() then return end

  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  local line_count = vim.api.nvim_buf_line_count(autocomplete.win:get_buf())
  local cycle_from_top = config.windows.autocomplete.cycle.from_top
  local is_first_completion = current_line == 1

  -- at the beginning of completion list and the config is not enabled: do nothing
  if is_first_completion and not cycle_from_top then return end
  if is_first_completion then
    -- at the beginning of completion list and the config is enabled: cycle back to last completion
    vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { line_count, 0 })
    autocomplete.event_targets.on_select(autocomplete.get_selected_item(), autocomplete.context)
  else
    -- select previous completion
    vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { math.max(current_line - 1, 1), 0 })
    autocomplete.event_targets.on_select(autocomplete.get_selected_item(), autocomplete.context)
  end
end

function autocomplete.listen_on_select(callback) autocomplete.event_targets.on_select = callback end

---------- Rendering ----------

function autocomplete.draw()
  local draw_fn = autocomplete.get_draw_fn()
  local icon_gap = config.nerd_font_variant == 'mono' and ' ' or '  '
  local arr_of_components = {}
  for _, item in ipairs(autocomplete.items) do
    local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown'
    local kind_icon = config.kind_icons[kind] or config.kind_icons.Field

    table.insert(
      arr_of_components,
      draw_fn({
        item = item,
        kind = kind,
        kind_icon = kind_icon,
        icon_gap = icon_gap,
        deprecated = item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)),
      })
    )
  end

  local max_line_length =
    math.min(autocmp_config.max_width, math.max(autocmp_config.min_width, renderer.get_max_length(arr_of_components)))
  autocomplete.rendered_items = vim.tbl_map(
    function(component) return renderer.render(component, max_line_length) end,
    arr_of_components
  )

  local lines = vim.tbl_map(function(rendered) return rendered.text end, autocomplete.rendered_items)
  local bufnr = autocomplete.win:get_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
end

function autocomplete.get_draw_fn()
  if type(autocmp_config.draw) == 'function' then
    return autocmp_config.draw
  elseif autocmp_config.draw == 'simple' then
    return autocomplete.render_item_simple
  elseif autocmp_config.draw == 'reversed' then
    return autocomplete.render_item_reversed
  end
  error('Invalid autocomplete window draw config')
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.render_item_simple(ctx)
  return {
    { ' ', ctx.kind_icon, ctx.icon_gap, hl_group = 'BlinkCmpKind' .. ctx.kind },
    { ctx.item.label, fill = true, hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
  }
end

--- @param ctx blink.cmp.CompletionRenderContext
--- @return blink.cmp.Component[]
function autocomplete.render_item_reversed(ctx)
  return {
    {
      ' ' .. ctx.item.label,
      fill = true,
      hl_group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
    },
    { ' ', ctx.kind_icon, ctx.icon_gap, ctx.kind .. ' ', hl_group = 'BlinkCmpKind' .. ctx.kind },
  }
end

function autocomplete.get_selected_item()
  if not autocomplete.win:is_open() then return end
  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  return autocomplete.items[current_line]
end

return autocomplete
