local config = require('blink.cmp.config').windows.documentation
local sources = require('blink.cmp.sources.lib')
local autocomplete = require('blink.cmp.windows.autocomplete')
local docs = {}

function docs.setup()
  docs.win = require('blink.cmp.windows.lib').new({
    min_width = config.min_width,
    max_width = config.max_width,
    max_height = config.max_height,
    border = config.border,
    winhighlight = config.winhighlight,
    wrap = true,
    filetype = 'markdown',
  })

  autocomplete.listen_on_position_update(function()
    if autocomplete.win:is_open() then docs.update_position() end
  end)

  local timer = vim.uv.new_timer()
  local last_context_id = nil
  autocomplete.listen_on_select(function(item, context)
    timer:stop()
    if docs.win:is_open() or context.id == last_context_id then
      last_context_id = context.id
      timer:start(config.update_delay_ms, 0, function()
        vim.schedule(function() docs.show_item(item) end)
      end)
    elseif config.auto_show then
      timer:start(config.auto_show_delay_ms, 0, function()
        last_context_id = context.id
        vim.schedule(function() docs.show_item(item) end)
      end)
    end
  end)
  autocomplete.listen_on_close(function() docs.win:close() end)

  return docs
end

function docs.show_item(item)
  if item == nil then
    docs.win:close()
    return
  end

  -- TODO: cancellation
  -- TODO: only resolve if documentation does not exist
  sources
    .resolve(item)
    :map(function(item)
      if item.documentation == nil and item.detail == nil then
        docs.win:close()
        return
      end

      if docs.shown_item ~= item then
        require('blink.cmp.windows.lib.docs').render_detail_and_documentation(
          docs.win:get_buf(),
          item.detail,
          item.documentation,
          docs.win.config.max_width
        )
      end
      docs.shown_item = item

      if autocomplete.win:get_win() then
        docs.win:open()
        docs.update_position()
      end
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR) end)
end

function docs.scroll_up(amount)
  local winnr = docs.win:get_win()
  local top_line = math.max(1, vim.fn.line('w0', winnr) - 1)
  local desired_line = math.max(1, top_line - amount)

  vim.api.nvim_win_set_cursor(docs.win:get_win(), { desired_line, 0 })
end

function docs.scroll_down(amount)
  local winnr = docs.win:get_win()
  local line_count = vim.api.nvim_buf_line_count(docs.win:get_buf())
  local bottom_line = math.max(1, vim.fn.line('w$', winnr) + 1)
  local desired_line = math.min(line_count, bottom_line + amount)

  vim.api.nvim_win_set_cursor(docs.win:get_win(), { desired_line, 0 })
end

function docs.update_position()
  if not docs.win:is_open() or not autocomplete.win:is_open() then return end
  local winnr = docs.win:get_win()

  docs.win:update_size()

  local autocomplete_winnr = autocomplete.win:get_win()
  if not autocomplete_winnr then return end
  local autocomplete_win_config = vim.api.nvim_win_get_config(autocomplete_winnr)
  local autocomplete_win_width = autocomplete.win:get_width()
  local autocomplete_win_height = autocomplete.win:get_height()
  local autocomplete_border_size = autocomplete.win:get_border_size()

  local screen_width = vim.api.nvim_win_get_width(0)
  local screen_height = vim.api.nvim_win_get_height(0)
  local cursor_screen_row = vim.fn.screenrow()

  local autocomplete_win_is_up = autocomplete_win_config.row - cursor_screen_row < 0
  local direction_priority = autocomplete_win_is_up and config.direction_priority.autocomplete_north
    or config.direction_priority.autocomplete_south

  local height = docs.win:get_height()
  local width = docs.win:get_width()

  local space_above = autocomplete_win_config.row - 1 > height
  local space_below = screen_height - autocomplete_win_height - autocomplete_win_config.row > height
  -- todo: check if there's vertical space available, need to check the direction of the autocomplete window
  local space_left = autocomplete_win_config.col > width
  local space_right = screen_width - autocomplete_win_width - autocomplete_win_config.col > width

  local function set_config(opts)
    vim.api.nvim_win_set_config(winnr, { relative = 'win', win = autocomplete_winnr, row = opts.row, col = opts.col })
  end
  for _, direction in ipairs(direction_priority) do
    if direction == 'n' and space_above then
      if autocomplete_win_is_up then
        set_config({ row = -height - autocomplete_border_size.top, col = -autocomplete_border_size.left })
      else
        set_config({ row = -1 - height - autocomplete_border_size.top, col = -autocomplete_border_size.left })
      end
      return
    elseif direction == 's' and space_below then
      if autocomplete_win_is_up then
        set_config({
          row = 1 + autocomplete_win_height - autocomplete_border_size.top,
          col = -autocomplete_border_size.left,
        })
      else
        set_config({
          row = autocomplete_win_height - autocomplete_border_size.top,
          col = -autocomplete_border_size.left,
        })
      end
      return
    elseif direction == 'e' and space_right then
      set_config({
        row = -autocomplete_border_size.top,
        col = autocomplete_win_config.width + autocomplete_border_size.left,
      })
      return
    elseif direction == 'w' and space_left then
      set_config({ row = -autocomplete_border_size.top, col = -width - autocomplete_border_size.left })
      return
    end
  end

  -- failed to find a direction to place the window so close it
  docs.win:close()
end

return docs
