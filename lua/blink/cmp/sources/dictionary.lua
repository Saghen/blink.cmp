local function get_dict_words(dict_path)
	local words = {}
	local dict = io.open(dict_path, "r")
	if dict then
		for line in dict:lines() do
			for word in string.gmatch(line, "%g+") do
				table.insert(words, word)
			end
		end
	end
	return words
end

local function words_to_items(words, dictionary_name)
	local items = {}
	for _, word in ipairs(words) do
		table.insert(items, {
			label = word,
			detail = dictionary_name,
			kind = require('blink.cmp.types').CompletionItemKind.Keyword,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			insertText = word,
		})
	end
	return items
end

local dictionary = {}
dictionary.items = {}
dictionary.dictionary_names = {}

--- @param callback fun(items: blink.cmp.CompletionItem[])
local function run_sync(callback) callback(dictionary.items) end

--- Public API

function dictionary.reset_items()
	-- First get the global options dictionary
	local dict_paths = vim.opt_global.dictionary:get()
	-- Then add the local opts dictionaries to the table
	for _, local_dict in ipairs(vim.opt_local.dictionary:get()) do
		table.insert(dict_paths, local_dict)
	end

	-- Deduplicate dictionary paths because local and global may be equivalent
	dict_paths = require('blink.cmp.lib.utils').deduplicate(dict_paths)

	-- Get all words from all dictionaries
	-- Create all the completion items from each dictionary word
	local all_items = {}
	local dictionary_name = ""
	for _, dict in ipairs(dict_paths) do
		dictionary_name = string.match(dict, "([^/\\]+)$")
		local dict_words = get_dict_words(dict)
		local dict_items = words_to_items(dict_words, dictionary_name)
		for _, item in ipairs(dict_items) do
			table.insert(all_items, item)
		end
	end

	dictionary.items = all_items
end

function dictionary.new()
	local self = setmetatable({}, { __index = dictionary })

	vim.api.nvim_create_autocmd("OptionSet", {
		desc = "Callback to update the dictionaries items when the global and local dictionary option is changed",
		pattern = { "dictionary" },
		callback = function()
			self.reset_items()
		end,
	})

	vim.api.nvim_create_autocmd("BufRead", {
		desc = "Callback to update the dictionaries items when reading a new buffer",
		callback = function()
			self.reset_items()
		end,
	})

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
