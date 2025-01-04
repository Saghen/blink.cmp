--- @class blink.cmp.MiniSnippetsSourceOptions

--- @class blink.cmp.MiniSnippetsSource : blink.cmp.Source
--- @field config blink.cmp.MiniSnippetsSourceOptions
--- @field items_cache table<string, blink.cmp.CompletionItem[]>

--- @class blink.cmp.MiniSnippetsSnippet
--- @field prefix string string snippet identifier.
--- @field body string string snippet content with appropriate syntax.
--- @field desc string string snippet description in human readable form.

--- @type blink.cmp.MiniSnippetsSource
--- @diagnostic disable-next-line: missing-fields
local source = {}

local defaults_config = {} -- currently, no options needed

function source.new(opts)
  local config = vim.tbl_deep_extend('keep', opts or {}, defaults_config)
  local self = setmetatable({}, { __index = source })
  self.config = config
  self.items_cache = {}
  return self
end

-- Ensure that user has explicitly setup mini.snippets
function source:enabled()
  ---@diagnostic disable-next-line: undefined-field
  return _G.MiniSnippets ~= nil
end

local function to_completion_items(snippets)
  local result = {}

  for _, snip in ipairs(snippets) do
    --- @type lsp.CompletionItem
    local item = {
      kind = require('blink.cmp.types').CompletionItemKind.Snippet,
      label = snip.prefix,
      insertText = snip.prefix,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      data = { snip = snip },
    }
    table.insert(result, item)
  end
  return result
end

-- Cached by buf_id/ft combination:
-- vim.b.minisnippets_config can contain buffer-local snippets.
--
-- From the help, MiniSnippets.default_prepare:
-- Unlike |MiniSnippets.gen_loader| entries, there is no output caching. This
-- avoids duplicating data from `gen_loader` cache and reduces memory usage.
-- It also means that every |MiniSnippets.expand()| call prepares snippets, which
-- is usually fast enough. If not, consider manual caching:
local function get_completion_items(cache)
  local _, context = MiniSnippets.default_prepare({})
  local id = 'buf=' .. context.buf_id .. ',lang=' .. context.lang

  -- Return the completion items for this context from cache
  if cache[id] then return cache[id] end

  -- Retrieve all raw snippets in context and transform into completion items
  local snippets = MiniSnippets.expand({ match = false, insert = false }) or {}
  local items = to_completion_items(vim.deepcopy(snippets))
  cache[id] = items

  return items
end

function source:get_completions(ctx, callback)
  --- @type blink.cmp.CompletionItem[]
  local items = get_completion_items(self.items_cache)
  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
    context = ctx,
    ---@diagnostic disable-next-line: missing-return
  })
end

function source:resolve(item, callback)
  --- @type blink.cmp.MiniSnippetsSnippet
  local snip = item.data.snip

  local desc = snip.desc
  if desc and not item.documentation then
    item.documentation = {
      kind = 'markdown',
      value = table.concat(vim.lsp.util.convert_input_to_markdown_lines(desc), '\n'),
    }
  end

  local detail = snip.body
  if not item.detail then
    if type(detail) == 'table' then detail = table.concat(detail, '\n') end
    item.detail = detail
  end

  callback(item)
end

function source:execute(_, item)
  -- Remove the word inserted by blink and insert snippet
  -- It's safe to assume that mode is insert during completion

  --- @type blink.cmp.MiniSnippetsSnippet
  local snip = item.data.snip

  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor[1] = cursor[1] - 1 -- nvim_buf_set_text: line is zero based
  local start_col = cursor[2] - #item.insertText
  vim.api.nvim_buf_set_text(0, cursor[1], start_col, cursor[1], cursor[2], {})

  local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
  ---@diagnostic disable-next-line: missing-return
  insert({ body = snip.body }) -- insert at cursor
end

-- For external integrations to force reloading the snippets
function source:reload()
  MiniSnippets.setup(MiniSnippets.config)
  self.items_cache = {}
end

return source
