-- todo: track cursor position
local config = require('blink.cmp.config')
local autocomplete = {
  items = {},
  context = nil,
  event_targets = {
    on_position_update = function() end,
    on_select = function() end,
    on_close = function() end,
  },
}

function autocomplete.setup()
  autocomplete.win = require('blink.cmp.windows.lib').new({
    cursorline = true,
    winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
    scrolloff = 2,
  })

  -- Setting highlights is slow and we update on every keystroke so we instead use a decoration provider
  -- which will only render highlights of the visible lines. This also avoids having to do virtual scroll
  -- like nvim-cmp does, which breaks on UIs like neovide
  vim.api.nvim_set_decoration_provider(config.highlight.ns, {
    on_win = function(_, winnr, bufnr)
      return autocomplete.win:get_win() == winnr and bufnr == autocomplete.win:get_buf()
    end,
    on_line = function(_, _, bufnr, line_number)
      local item = autocomplete.items[line_number + 1]
      if item == nil then return end
      local line_text = vim.api.nvim_buf_get_lines(bufnr, line_number, line_number + 1, false)[1]

      local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown'
      local kind_hl = 'BlinkCmpKind' .. kind

      -- todo: handle .labelDetails and others
      vim.api.nvim_buf_set_extmark(bufnr, config.highlight.ns, line_number, 0, {
        end_col = 4,
        hl_group = kind_hl,
        hl_mode = 'combine',
        hl_eol = true,
        ephemeral = true,
      })

      -- todo: use vim.lsp.protocol.CompletionItemTag
      if item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) then
        -- todo: why 7?
        vim.api.nvim_buf_set_extmark(bufnr, config.highlight.ns, line_number, 7, {
          end_col = #line_text - 1,
          hl_group = 'BlinkCmpLabelDeprecated',
          hl_mode = 'combine',
          ephemeral = true,
        })
      end
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
  autocomplete.items = items
  autocomplete.draw()

  autocomplete.win:open()

  autocomplete.context = context
  autocomplete.update_position(context)

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item())
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

function autocomplete.update_position(context)
  local win = autocomplete.win
  if not win:is_open() then return end
  local winnr = win:get_win()

  win:update_size()

  local height = vim.api.nvim_win_get_height(winnr)
  local screen_height = vim.api.nvim_win_get_height(0)
  local screen_scroll_range = win.get_screen_scroll_range()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1]
  local cursor_col = cursor[2]

  -- place the window at the start col of the current text we're fuzzy matching against
  -- so the window doesnt move around as we type
  local col = context.bounds.start_col - cursor_col - 1

  -- detect if there's space above/below the cursor
  local is_space_below = screen_height - cursor_row - screen_scroll_range.start_line > height
  local is_space_above = cursor_row - screen_scroll_range.start_line > height

  -- default to the user's preference but attempt to use the other options
  local row = config.windows.autocomplete.direction_priority[1] == 'n' and 1 or -height
  for _, direction in ipairs(config.windows.autocomplete.direction_priority) do
    if direction == 'n' and is_space_below then
      row = 1
      break
    elseif direction == 's' and is_space_above then
      row = -height
      break
    end
  end

  vim.api.nvim_win_set_config(winnr, { relative = 'cursor', row = row, col = col })

  autocomplete.event_targets.on_position_update()
end

function autocomplete.listen_on_position_update(callback) autocomplete.event_targets.on_position_update = callback end

---------- Selection ----------

function autocomplete.select_next()
  if not autocomplete.win:is_open() then return end

  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  local line_count = vim.api.nvim_buf_line_count(autocomplete.win:get_buf())
  if current_line == line_count then return end

  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { current_line + 1, 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item())
end

function autocomplete.select_prev()
  if not autocomplete.win:is_open() then return end

  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  if current_line == 1 then return end

  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { math.max(current_line - 1, 1), 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item())
end

function autocomplete.listen_on_select(callback) autocomplete.event_targets.on_select = callback end

---------- Rendering ----------

function autocomplete.draw()
  local max_line_width = 0
  for _, item in ipairs(autocomplete.items) do
    max_line_width = math.max(max_line_width, autocomplete.get_item_max_length(item))
  end
  local target_width =
    math.max(math.min(max_line_width, autocomplete.win.config.max_width), autocomplete.win.config.min_width)

  local lines = {}
  for _, item in ipairs(autocomplete.items) do
    table.insert(lines, autocomplete.draw_item(item, target_width))
  end

  local bufnr = autocomplete.win:get_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
end

function autocomplete.get_item_max_length(item)
  local icon_width = 4
  local label_width = vim.api.nvim_strwidth(autocomplete.get_label(item))
  return icon_width + label_width
end

function autocomplete.draw_item(item, max_length)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown'
  local kind_icon = config.kind_icons[kind] or config.kind_icons.Field

  -- get line text
  local label = autocomplete.get_label(item)
  local other_content_length = 5
  local abbr = string.sub(label, 1, max_length - other_content_length)

  return string.format(' %s  %s ', kind_icon, abbr)
end

function autocomplete.get_label(item) return item.label end

function autocomplete.get_selected_item()
  if not autocomplete.win:is_open() then return end
  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  return autocomplete.items[current_line]
end

return autocomplete
