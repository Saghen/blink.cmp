--- @class blink.cmp.SnippetsOpts
--- @field friendly_snippets boolean
--- @field search_paths string[]
--- @field global_snippets string[]
--- @field extended_filetypes table<string, string[]>
--- @field ignored_filetypes string[]

local snippets = {}

--- @param opts blink.cmp.SnippetsOpts
function snippets.new(opts)
  local self = setmetatable({}, { __index = snippets })
  --- @type table<string, blink.cmp.CompletionItem[]>
  self.cache = {}
  self.registry = require('blink.cmp.sources.snippets.registry').new(opts)
  return self
end

function snippets:get_completions(_, callback)
  local filetype = vim.bo.filetype
  if vim.tbl_contains(self.registry.config.ignored_filetypes, filetype) then return callback() end

  if not self.cache[filetype] then
    local global_snippets = self.registry:get_global_snippets()
    local extended_snippets = self.registry:get_extended_snippets(filetype)
    local ft_snippets = self.registry:get_snippets_for_ft(filetype)
    local snips = vim.tbl_deep_extend('force', {}, global_snippets, extended_snippets, ft_snippets)

    self.cache[filetype] = {}
    for _, snippet in pairs(snips) do
      table.insert(self.cache[filetype], snippet)
    end
  end

  local items = vim.tbl_map(
    function(item) return self.registry:snippet_to_completion_item(item) end,
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

  -- TODO: ideally context is passed with the filetype
  local documentation = '```' .. vim.bo.filetype .. '\n' .. snippet .. '```' .. '\n---\n' .. item.description

  local resolved_item = vim.deepcopy(item)
  resolved_item.documentation = {
    kind = 'markdown',
    value = documentation,
  }
  callback(resolved_item)
end

return snippets
