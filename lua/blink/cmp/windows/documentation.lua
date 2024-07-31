-- todo: track cmp_win position
local config = require('blink.cmp.config')
local sources = require('blink.cmp.sources')
local autocomplete = require('blink.cmp.windows.autocomplete')
local docs = {}

function docs.setup()
  docs.win = require('blink.cmp.windows.lib').new({
    min_width = 10,
    max_height = 20,
    wrap = true,
    -- todo: is just using markdown enough?
    filetype = 'markdown',
    padding = true,
  })

  autocomplete.listen_on_position_update(function()
    if autocomplete.win:get_win() then docs.update_position() end
  end)
  if config.windows.documentation.auto_show then
    autocomplete.listen_on_select(function(item) docs.show_item(item) end)
  end
  autocomplete.listen_on_close(function() docs.win:close() end)

  return docs
end

-- todo: debounce and only update if the item changed
function docs.show_item(item)
  if item == nil then
    docs.win:close()
    return
  end

  sources.resolve(item, function(resolved_item)
    item = resolved_item or item
    if item.documentation == nil then
      docs.win:close()
      return
    end

    local doc = type(item.documentation) == 'string' and item.documentation or item.documentation.value
    local doc_lines = {}
    for s in doc:gmatch('[^\r\n]+') do
      table.insert(doc_lines, s)
    end
    vim.api.nvim_buf_set_lines(docs.win:get_buf(), 0, -1, true, doc_lines)
    vim.api.nvim_set_option_value('modified', false, { buf = docs.win:get_buf() })

    local filetype = item.documentation.kind == 'markdown' and 'markdown' or 'plaintext'
    if filetype ~= vim.api.nvim_get_option_value('filetype', { buf = docs.win:get_buf() }) then
      vim.api.nvim_set_option_value('filetype', filetype, { buf = docs.win:get_buf() })
    end

    if autocomplete.win:get_win() then
      docs.win:open()
      docs.update_position()
    end
  end)
end

function docs.update_position()
  if not docs.win:is_open() or not autocomplete.win:is_open() then return end
  local winnr = docs.win:get_win()

  docs.win:update_size()

  local autocomplete_winnr = autocomplete.win:get_win()
  if not autocomplete_winnr then return end
  local autocomplete_win_config = vim.api.nvim_win_get_config(autocomplete_winnr)

  local screen_width = vim.api.nvim_win_get_width(0)
  local screen_height = vim.api.nvim_win_get_height(0)
  local cursor_screen_row = vim.fn.screenrow()

  local autocomplete_win_is_up = autocomplete_win_config.row - cursor_screen_row < 0
  local direction_priority = autocomplete_win_is_up
      and config.windows.documentation.direction_priority.autocomplete_north
    or config.windows.documentation.direction_priority.autocomplete_south

  local height = vim.api.nvim_win_get_height(winnr)
  local width = vim.api.nvim_win_get_width(winnr)

  local space_above = autocomplete_win_config.row - 1 > height
  local space_below = screen_height - autocomplete_win_config.height - autocomplete_win_config.row > height
  local space_left = autocomplete_win_config.col > width
  local space_right = screen_width - autocomplete_win_config.width - autocomplete_win_config.col > width

  local function set_config(opts)
    vim.api.nvim_win_set_config(winnr, { relative = 'win', win = autocomplete_winnr, row = opts.row, col = opts.col })
  end
  for _, direction in ipairs(direction_priority) do
    if direction == 'n' and space_above then
      if autocomplete_win_is_up then
        set_config({ row = -height, col = 0 })
      else
        set_config({ row = -1 - height, col = 0 })
      end
      return
    elseif direction == 's' and space_below then
      if autocomplete_win_is_up then
        set_config({ row = 1 + autocomplete_win_config.height, col = 0 })
      else
        set_config({ row = autocomplete_win_config.height, col = 0 })
      end
      return
    elseif direction == 'e' and space_right then
      set_config({ row = 0, col = autocomplete_win_config.width })
      return
    elseif direction == 'w' and space_left then
      set_config({ row = 0, col = -1 - width })
      return
    end
  end

  -- failed to find a direction to place the window so close it
  docs.win:close()
end

return docs
