--- @class blink.cmp.SnippetsOpts
--- @param friendly_snippets boolean
--- @param search_paths string[]
--- @param global_snippets string[]
--- @param extended_filetypes table<string, string[]>
--- @param ignored_filetypes string[]

--- @class blink.cmp.SnippetsSource : blink.cmp.Source
--- @field cache table<string, blink.cmp.CompletionItem[]>
local snippets = {}

--- @param opts blink.cmp.SnippetsOpts
function snippets.new(opts)
  local self = setmetatable({}, { __index = snippets })
  self.cache = {}
  self.registry = require('blink.cmp.sources.snippets.registry').new(opts)
  return self
end

function snippets:get_completions(context, callback)
  local filetype = vim.bo.filetype
  if vim.tbl_contains(self.registry.config.ignored_filetypes, filetype) then
    return callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  if not self.cache[filetype] then
    local global_snippets = self.registry:get_global_snippets()
    local extended_snippets = self.registry:get_extended_snippets(filetype)
    local ft_snippets = self.registry:get_snippets_for_ft(filetype)
    local snips = vim.tbl_deep_extend('force', {}, global_snippets, extended_snippets, ft_snippets)

    self.cache[filetype] = {}
    for _, snippet in pairs(snips) do
      table.insert(self.cache[filetype], self.registry:snippet_to_completion_item(snippet))
    end
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = self.cache[filetype],
  })
end

function snippets:resolve(item, callback)
  -- TODO: ideally context is passed with the filetype
  local documentation = '```'
    .. vim.bo.filetype
    .. '\n'
    .. self.registry:preview(item.insertText)
    .. '```'
    .. '\n---\n'
    .. item.description

  local resolved_item = vim.deepcopy(item)
  resolved_item.documentation = {
    kind = 'markdown',
    value = documentation,
  }
  callback(resolved_item)
end

return snippets
