--- @module 'mini.snippets'

--- @class blink.cmp.MiniSnippetsSourceOptions
--- @field use_items_cache? boolean completion items are cached using default mini.snippets context

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

local defaults_config = {
  --- Whether to use a cache for completion items
  use_items_cache = true,
}

function source.new(opts)
  local config = vim.tbl_deep_extend('keep', opts, defaults_config)
  vim.validate({
    use_items_cache = { config.use_items_cache, 'boolean' },
  })

  local self = setmetatable({}, { __index = source })
  self.config = config
  self.items_cache = {}
  return self
end

function source:enabled()
  ---@diagnostic disable-next-line: undefined-field
  return _G.MiniSnippets ~= nil -- ensure that user has explicitly setup mini.snippets
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

-- NOTE: Completion items are cached by default using the default 'mini.snippets' context
--
-- vim.b.minisnippets_config can contain buffer-local snippets.
-- a buffer can contain code in multiple languages
--
-- See :h MiniSnippets.default_prepare
--
-- Return completion items produced from snippets either directly or from cache
local function get_completion_items(cache)
  if not cache then return to_completion_items(MiniSnippets.expand({ match = false, insert = false })) end

  -- Compute cache id
  local _, context = MiniSnippets.default_prepare({})
  local id = 'buf=' .. context.buf_id .. ',lang=' .. context.lang

  -- Return the completion items for this context from cache
  if cache[id] then return cache[id] end

  -- Retrieve all raw snippets in context and transform into completion items
  local snippets = MiniSnippets.expand({ match = false, insert = false })
  --- @cast snippets table
  local items = to_completion_items(vim.deepcopy(snippets))
  cache[id] = items

  return items
end

function source:get_completions(ctx, callback)
  local cache = self.config.use_items_cache and self.items_cache or nil

  --- @type blink.cmp.CompletionItem[]
  local items = get_completion_items(cache)
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
