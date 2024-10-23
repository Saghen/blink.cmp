--- @class blink.cmp.SnippetsOpts
--- @field friendly_snippets boolean
--- @field search_paths string[]
--- @field global_snippets string[]
--- @field extended_filetypes table<string, string[]>
--- @field ignored_filetypes string[]

local snippets = {}

function snippets.new(opts)
  local self = setmetatable({}, { __index = snippets })
  --- @type table<string, blink.cmp.CompletionItem[]>
  self.cache = {}
  --- @type blink.cmp.SnippetsOpts
  self.registry = require('blink.cmp.sources.snippets.registry').new(opts or {})
  return self
end

function snippets:get_completions(_, callback)
  local filetype = vim.bo.filetype
  if vim.tbl_contains(self.registry.config.ignored_filetypes, filetype) then return callback() end

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
  local documentation = '```' .. vim.bo.filetype .. '\n' .. snippet .. '\n```' .. '\n---\n' .. item.description

  local resolved_item = vim.deepcopy(item)
  resolved_item.documentation = {
    kind = 'markdown',
    value = documentation,
  }
  callback(resolved_item)
end

--- For external integrations to force reloading the snippets
function snippets:reload() self.cache = {} end

return snippets
