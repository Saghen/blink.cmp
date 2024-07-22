-- todo: track cmp_win position

local sources = require('blink.cmp.sources')
local autocomplete = require('blink.cmp.windows.autocomplete')
local docs = {}

function docs.setup()
  docs.win = require('blink.cmp.windows.lib').new({
    width = 60,
    max_height = 20,
    wrap = true,
    -- todo: should be able to use the markdown stuff now?
    -- filetype = 'typescript', -- todo: set dynamically
    padding = true,
  })

  autocomplete.listen_on_position_update(function()
    if autocomplete.win:get_win() then docs.win:update_position(autocomplete.win:get_win()) end
  end)
  autocomplete.listen_on_select(function(item) docs.show_item(item) end)
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

    if autocomplete.win:get_win() then
      docs.win:open()
      docs.win:update_position(autocomplete.win:get_win())
    end
  end)
end

return docs
