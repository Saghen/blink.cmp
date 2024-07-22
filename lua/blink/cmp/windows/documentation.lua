-- todo: track cmp_win position

local sources = require('blink.cmp.sources')
local cmp_win = require('blink.cmp.windows.autocomplete')
local docs = {}

function docs.setup()
  docs.win = require('blink.cmp.windows.lib').new({
    width = 60,
    max_height = 20,
    relative = cmp_win.win:get_win(),
    wrap = true,
    -- todo: should be able to use the markdown stuff now?
    -- filetype = 'typescript', -- todo: set dynamically
    padding = true,
  })

  cmp_win.on_select_callback = function(item) docs.set_item(item) end
  cmp_win.on_open_callback = function() docs.set_item(cmp_win.get_selected_item()) end
  cmp_win.on_close_callback = function() docs.win:close() end

  return docs
end

-- todo: debounce and only update if the item changed
function docs.set_item(item)
  if item == nil then
    docs.win:close()
    return
  end
  if not cmp_win.win:is_open() then return end

  sources.resolve(item, function(resolved_item)
    if resolved_item.detail == nil then
      docs.win:close()
      return
    end

    local doc_lines = {}
    for s in resolved_item.detail:gmatch('[^\r\n]+') do
      table.insert(doc_lines, s)
    end
    vim.api.nvim_buf_set_lines(docs.win:get_buf(), 0, -1, true, doc_lines)
    vim.api.nvim_set_option_value('modified', false, { buf = docs.win:get_buf() })

    docs.win:open()
  end)
end

return docs
