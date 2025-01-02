--- @class blink.cmp.DictionarySource : blink.cmp.Source
--- Table containing the dictionary name label as key and and array of completion items for each dictionary
--- @field dictionaries table<string, blink.cmp.CompletionItem[]>

--- @type blink.cmp.DictionarySource
--- @diagnostic disable-next-line: missing-fields
local source = {}
source.dictionaries = {}

---Function to concatenate two CompletionItem lists
---@param items1 blink.cmp.CompletionItem[]
---@param items2 blink.cmp.CompletionItem[]
---@return blink.cmp.CompletionItem[]
local function items_add(items1, items2)
	---@type blink.cmp.CompletionItem[]
	local items = items1
	for _, item in ipairs(items2) do
		table.insert(items, item)
	end
	return items
end

---@return blink.cmp.CompletionItem[]
local function get_all_items()
	---@type blink.cmp.CompletionItem[]
	local all_items = setmetatable({}, { __add = items_add })
	for _, items in pairs(source.dictionaries) do
		all_items = all_items + items
	end
	return all_items
end

---@param dictionary_path string
---@return string[]
local function get_dictionary_words(dictionary_path)
	---@type string[]
	local words = {}
	local dictionary_file = io.open(dictionary_path, "r")
	if dictionary_file then
		for line in dictionary_file:lines() do
			for word in string.gmatch(line, "%S+") do
				table.insert(words, word)
			end
		end
	end
	return words
end

---@param words string[]
---@param dictionary_name string
---@return blink.cmp.CompletionItem[]
local function words_to_items(words, dictionary_name)
	---@type blink.cmp.CompletionItem[]
	local items = {}
	for _, word in ipairs(words) do
		---@type lsp.CompletionItemLabelDetails
		local label_details = {}
		label_details.description = dictionary_name
		table.insert(items, {
			label = word,
			labelDetails = label_details,
			kind = require('blink.cmp.types').CompletionItemKind.Text,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			insertText = word,
		})
	end
	return items
end

---Load all the dictionaries words and create the completion items
local function load_dictionaries()
	-- Create new dictionaries table
	---@type table<string, blink.cmp.CompletionItem[]>
	local dictionaries = {}

	-- First get the global options dictionary
	local dictionaries_paths = vim.opt_global.dictionary:get()
	-- Then add the local opts dictionaries to the table
	for _, local_dictionary in ipairs(vim.opt_local.dictionary:get()) do
		table.insert(dictionaries_paths, local_dictionary)
	end

	-- Deduplicate dictionary paths because local and global may be equivalent
	dictionaries_paths = require('blink.cmp.lib.utils').deduplicate(dictionaries_paths)

	-- Check if a dictionary already exists in the source
	-- If it exists, just take the items from the existing source dictionary
	-- If not, get all words from the dictionary
	-- Create all the completion items from each dictionary word
	---@type string
	local dictionary_name = ""
	for _, dictionary_path in ipairs(dictionaries_paths) do
		dictionary_name = string.match(dictionary_path, "([^/\\]+)$")
		-- Add table with key = dictoinary_name and empty items list to new dictionaries
		dictionaries[dictionary_name] = {}
		-- If the dictionary exists in the source dictionaries table, get the items from there
		if (source.dictionaries[dictionary_name]) then
			dictionaries[dictionary_name] = source.dictionaries[dictionary_name]
		else
			local dictionary_words = get_dictionary_words(dictionary_path)
			dictionaries[dictionary_name] = words_to_items(dictionary_words, dictionary_name)
		end
	end

	source.dictionaries = dictionaries
end

--- @param callback fun(items: blink.cmp.CompletionItem[])
local function run_sync(callback) callback(get_all_items()) end

--- Public API

function source.new()
	local self = setmetatable({}, { __index = source })
	return self
end

function source:get_completions(_, callback)
	---@param items blink.cmp.CompletionItem[]
	local transformed_callback = function(items)
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
	end

	vim.schedule(function ()
		load_dictionaries()
		run_sync(transformed_callback)
	end)

	-- TODO: cancel run_async
	return function() end
end

return source
