--- @class blink.cmp.MiniSnippetsSourceOptions -- for future options

--- @class blink.cmp.MiniSnippetsSource : blink.cmp.Source
--- @field config blink.cmp.MiniSnippetsSourceOptions
--- @field items_cache table<string, blink.cmp.CompletionItem[]>

--- @type blink.cmp.MiniSnippetsSource
--- @diagnostic disable-next-line: missing-fields
local source = {}

local defaults_config = {}

-- Copied from mini.snippets: H.get_default_context
-- In mini.snippets the  context function can be overridden in the config
-- For now, only return lang.
local get_cache_key = function()
  local buf_id = vim.api.nvim_get_current_buf()
  local lang = vim.bo[buf_id].filetype

  -- TODO: Remove `opts.error` after compatibility with Neovim=0.11 is dropped
  local has_parser, parser = pcall(vim.treesitter.get_parser, buf_id, nil, { error = false })
  if not has_parser or parser == nil then return lang end

  -- Compute local TS language from the deepest parser covering position
  local lnum, col = vim.fn.line('.'), vim.fn.col('.')
  local ref_range, res_level = { lnum - 1, col - 1, lnum - 1, col }, 0
  local traverse
  traverse = function(lang_tree, level)
    if lang_tree:contains(ref_range) and level > res_level then lang = lang_tree:lang() or lang end
    for _, child_lang_tree in pairs(lang_tree:children()) do
      traverse(child_lang_tree, level + 1)
    end
  end
  traverse(parser, 1)

  return lang
end

local function expand()
  local snippets = MiniSnippets.expand({ match = false, insert = false }) or {}
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

function source.new(opts)
  local config = vim.tbl_deep_extend('keep', opts or {}, defaults_config)
  -- vim.validate: no items in default_config for now

  local self = setmetatable({}, { __index = source })
  self.config = config
  self.items_cache = {}
  return self
end

-- Ensure that user has explicitly setup mini.snippets
function source:enabled() return _G.MiniSnippets ~= nil end

function source:get_completions(ctx, callback)
  local cache_key = get_cache_key()
  --- @type blink.cmp.CompletionItem[] | nil
  local items = self.items_cache[cache_key]

  if not items then -- initialize cache for this context
    local new_items = expand()
    self.items_cache[cache_key] = new_items
    items = new_items
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
    context = ctx,
    ---@diagnostic disable-next-line: missing-return
  })
end

function source:resolve(item, callback)
  local snip = item.data.snip
  local resolved_item = vim.deepcopy(item)

  ---@diagnostic disable-next-line: undefined-field
  local detail = snip.body
  if type(detail) == 'table' then detail = table.concat(detail, '\n') end
  resolved_item.detail = detail

  ---@diagnostic disable-next-line: undefined-field
  local desc = snip.desc
  if desc then
    resolved_item.documentation = {
      kind = 'markdown',
      value = table.concat(vim.lsp.util.convert_input_to_markdown_lines(desc), '\n'),
    }
  end

  callback(resolved_item)
end

function source:execute(_, item)
  -- Remove the word inserted by blink and insert snippet
  -- It's safe to assume that mode is insert during completion
  local snip = item.data.snip

  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor[1] = cursor[1] - 1 -- nvim_buf_set_text: line is zero based
  local start_col = cursor[2] - #item.insertText
  vim.api.nvim_buf_set_text(0, cursor[1], start_col, cursor[1], cursor[2], {})

  local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
  ---@diagnostic disable-next-line: undefined-field, missing-return
  insert({ body = snip.body }) -- insert at cursor
end

-- For external integrations to force reloading the snippets
function source:reload()
  -- mini.snippets: snippets can not be added/deleted/changed dynamically
  -- self.items_cache = {}
end

return source
