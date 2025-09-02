--- @module 'vsnip'

---@class vsnip.CompleteItem
---@field abbr string
---@field dup 1|0
---@field kind string probably just "Snippet" ?
---@field menu string something like "[v] snip short info"
---@field user_data string json definition, coded in string
---@field word string

---@class blink.cmp.VSnipSourceOptions
--- Not many options since everything's set either at blink or vsnip plugins
--- cache is already done in vsnip so 🤷🏽‍♀️

---@class blink.cmp.VSnipSource : blink.cmp.Source
---@field cfg blink.cmp.VSnipSourceOptions
---@field vsnips_cache table<blink.cmp.Context, blink.cmp.CompletionItem[]>

---@type blink.cmp.VSnipSource
---@diagnostic disable-next-line: missing-fields
local source = {}
local defaults = {}
function source.new(opts)
  opts = vim.tbl_extend('keep', opts or {}, defaults)
  local cfg = vim.tbl_deep_extend('keep', opts, defaults)
  local self = setmetatable({}, { __index = source })
  self.cfg = cfg
  return self
end

function source:enabled() return vim.g.loaded_vsnip == 1 end

function source:get_completions(ctx, callback)
  local items = vim
    .iter(vim.fn['vsnip#get_complete_items'](ctx.bufnr))
    :map(
      ---@param vsnip vsnip.CompleteItem
      ---@return lsp.CompletionItem?
      function(vsnip)
        local user_data = vim.fn.json_decode(vsnip.user_data)
        return {
          kind = require('blink.cmp.types').CompletionItemKind.Snippet,
          label = vsnip.abbr,
          insertText = vsnip.word,
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
          data = {
            snippet = user_data.vsnip.snippet,
          },
        }
      end
    )
    :filter(function(item) return item ~= nil end)
    :totable()
  local cb = {
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  }

  callback(cb)
  return function()
    -- nothing to cancel
  end
end
function source:resolve(in_item, callback)
  local out_item = vim.deepcopy(in_item)
  ---@diagnostic disable-next-line: need-check-nil
  local snippet = out_item.data.snippet
  if vim.fn.empty(snippet.description) ~= 1 and not out_item.documentation then
    out_item.documentation = {
      kind = 'markdown',
      value = table.concat(vim.lsp.util.convert_input_to_markdown_lines(vim.fn['vsnip#to_string'](snippet)), '\n'),
    }
  end
  if not out_item.detail then
    assert(out_item.data)
    out_item.detail = vim.fn['vsnip#to_string'](snippet)
  end
  callback(out_item)
end

function source:execute(_, item)
  -- assert(item.textEdit)
  -- remove keyword / stuff before cursor
  require('blink.cmp.lib.text_edits').apply({
    newText = '',
    range = require('blink.cmp.lib.text_edits').get_from_item(item).range,
  })
  -- paste expanded snippet from item (not from text in buffer)
  ---@diagnostic disable-next-line: need-check-nil
  vim.fn['vsnip#anonymous'](vim.iter(item.data.snippet):join('\n'))
end
-- xref https://raw.githubusercontent.com/hrsh7th/cmp-vsnip/refs/heads/main/lua/cmp_vsnip/init.lua
return source
