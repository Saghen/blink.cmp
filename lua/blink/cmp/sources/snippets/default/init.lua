--- @class blink.cmp.SnippetsOpts
--- @field friendly_snippets? boolean
--- @field search_paths? string[]
--- @field global_snippets? string[]
--- @field extended_filetypes? table<string, string[]>
--- @field get_filetype? fun(context: blink.cmp.Context): string
--- @field filter_snippets? fun(filetype: string, file: string): boolean
--- @field clipboard_register? string
--- @field use_label_description? boolean Whether to put the snippet description in the label description

local snippets = {}

function snippets.new(opts)
  -- TODO: config validation
  --- @cast opts blink.cmp.SnippetsOpts

  local self = setmetatable({}, { __index = snippets })
  --- @type table<string, blink.cmp.CompletionItem[]>
  self.cache = {}
  self.registry = require('blink.cmp.sources.snippets.default.registry').new(opts)
  self.get_filetype = opts.get_filetype or function() return vim.bo.filetype end

  return self
end

function snippets:get_completions(context, callback)
  local filetype = self.get_filetype(context)

  if not self.cache[filetype] then
    local global_snippets = self.registry:get_global_snippets()
    local extended_snippets = self.registry:get_extended_snippets(filetype)
    local ft_snippets = self.registry:get_snippets_for_ft(filetype)
    local snips = vim.list_extend({}, global_snippets)
    vim.list_extend(snips, extended_snippets)
    vim.list_extend(snips, ft_snippets)

    self.cache[filetype] = snips
  end

  local items = vim.tbl_map(
    function(item) return self.registry:snippet_to_completion_item(item, context) end,
    self.cache[filetype]
  )
  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

function snippets:resolve(item, callback)
  local parsed_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(item.insertText)
  local snippet = parsed_snippet and tostring(parsed_snippet) or item.insertText

  local resolved_item = vim.deepcopy(item)
  resolved_item.detail = snippet
  resolved_item.documentation = {
    kind = 'markdown',
    value = item.description,
  }
  callback(resolved_item)
end

--- For external integrations to force reloading the snippets
function snippets:reload() self.cache = {} end

return snippets
