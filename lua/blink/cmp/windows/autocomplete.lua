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
  })

  -- Setting highlights is slow and we update on every keystroke so we instead use a decoration provider
  -- which will only render highlights of the visible lines. This also avoids having to do virtual scroll
  -- like nvim-cmp does, which breaks on UIs like neovide
  vim.api.nvim_set_decoration_provider(config.highlight_ns, {
    on_win = function(_, winnr, bufnr)
      return autocomplete.win:get_win() == winnr and bufnr == autocomplete.win:get_buf()
    end,
    on_line = function(_, _, bufnr, line_number)
      -- avoid drawing on the cursor because it interfers with the cursorline
      -- todo: some way to apply highlights with lower priority than cursorline?
      local cursor_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
      if cursor_line == line_number + 1 then return end

      local item = autocomplete.items[line_number + 1]
      if item == nil then return end

      local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown'
      local kind_hl = 'CmpItemKind' .. kind
      local kind_icon = config.kind_icons[kind] or config.kind_icons.Field

      -- todo: handle .deprecated, .flags, .labelDetails and others
      vim.api.nvim_buf_set_extmark(bufnr, config.highlight_ns, line_number, 0, {
        virt_text = { { ' ' .. kind_icon .. ' ', kind_hl } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
        priority = 0,
        ephemeral = true,
      })
    end,
  })

  vim.api.nvim_create_autocmd('CursorMovedI', {
    callback = function()
      if autocomplete.context == nil then return end

      local cursor_column = vim.api.nvim_win_get_cursor(0)[2]
      autocomplete.win:update_position('cursor', autocomplete.context.bounds.start_col - cursor_column - 1)
      autocomplete.event_targets.on_position_update()
    end,
  })

  return autocomplete
end

---------- Visibility ----------

function autocomplete.open_with_items(context, items)
  autocomplete.items = items
  autocomplete.context = context
  autocomplete.draw()

  autocomplete.win:open()
  local cursor_column = vim.api.nvim_win_get_cursor(0)[2]
  autocomplete.win:update_position('cursor', autocomplete.context.bounds.start_col - cursor_column - 1)
  autocomplete.event_targets.on_position_update()

  -- todo: some logic to maintain the selection if the user moved the cursor?
  vim.api.nvim_win_set_cursor(autocomplete.win:get_win(), { 1, 0 })
  autocomplete.event_targets.on_select(autocomplete.get_selected_item())
end

function autocomplete.listen_on_position_update(callback) autocomplete.event_targets.on_position_update = callback end

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
  local lines = {}
  for _, item in ipairs(autocomplete.items) do
    table.insert(lines, autocomplete.draw_item(item))
  end

  local bufnr = autocomplete.win:get_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
end

function autocomplete.draw_item(item)
  -- get icon
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or 'Unknown'
  local kind_icon = config.kind_icons[kind] or config.kind_icons.Field

  -- get line text
  local max_length = autocomplete.win.config.max_width
  local utf8len = vim.api.nvim_strwidth
  local other_content_length = utf8len(kind_icon) + utf8len(kind) + 5
  local remaining_length = math.max(0, max_length - other_content_length - utf8len(item.label))
  -- + 1 to include the final character, + 1 to account for lua being 1-indexed
  local abbr = string.sub(item.label, 1, max_length - other_content_length + 2) .. string.rep(' ', remaining_length)

  return string.format(' %s  %s %s ', kind_icon, abbr, kind)
end

function autocomplete.get_selected_item()
  local current_line = vim.api.nvim_win_get_cursor(autocomplete.win:get_win())[1]
  return autocomplete.items[current_line]
end

return autocomplete
