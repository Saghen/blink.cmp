local function get_dict_words()
	local words = require('blink.cmp.sources.dictionary.lily_db')
  return words
end

local function words_to_items(words)
  local items = {}
  for _, word in ipairs(words) do
    table.insert(items, {
      label = word,
      kind = require('blink.cmp.types').CompletionItemKind.Text,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      insertText = word,
    })
  end
  return items
end

--- @param callback fun(items: blink.cmp.CompletionItem[])
local function run_sync(callback) callback(words_to_items(get_dict_words())) end

--- Public API

local dictionary = {}

function dictionary.new()
  local self = setmetatable({}, { __index = dictionary })
  return self
end

function dictionary:get_completions(_, callback)
  local transformed_callback = function(items)
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  end

  vim.schedule(function()
		run_sync(transformed_callback)
  end)

  -- TODO: cancel run_async
  return function() end
end

return dictionary
