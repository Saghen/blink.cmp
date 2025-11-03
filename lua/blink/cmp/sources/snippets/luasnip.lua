---@type LuaSnip.API
local luasnip
local utils = require('blink.cmp.lib.utils')
local text_edits = require('blink.cmp.lib.text_edits')
local kind_snippet = require('blink.cmp.types').CompletionItemKind.Snippet

--- @class blink.cmp.LuasnipSourceOptions
--- @field use_show_condition? boolean Whether to use show_condition for filtering snippets
--- @field show_autosnippets? boolean Whether to show autosnippets in the completion list
--- @field prefer_doc_trig? boolean When expanding `regTrig` snippets, prefer `docTrig` over `trig` placeholder
--- @field use_label_description? boolean Whether to put the snippet description in the label description

--- @class blink.cmp.LuasnipSource : blink.cmp.Source
--- @field opts blink.cmp.LuasnipSourceOptions
--- @field items_cache table<string, blink.cmp.CompletionItem[]>
local source = {}

---@param snippet table
---@param event string
---@param callback fun(table, table)
local function add_luasnip_callback(snippet, event, callback)
  local events = require('luasnip.util.events')
  -- not defined for autosnippets
  if snippet.callbacks == nil then return end
  snippet.callbacks[-1] = snippet.callbacks[-1] or {}
  snippet.callbacks[-1][events[event]] = callback
end

---@param snippet LuaSnip.Snippet
---@return string?
local function get_insert_text(snippet)
  local res = {}
  for _, node in ipairs(snippet.nodes) do
    ---@cast node LuaSnip.Node
    -- TODO: How to know the node type? Would be nice to handle the others as well
    -- textNodes
    if type(node.static_text) == 'table' then res[#res + 1] = table.concat(node.static_text, '\n') end
  end

  -- Fallback
  if #res == 1 then
    -- Prefer docTrig over trigger
    ---@diagnostic disable-next-line: undefined-field
    if snippet.docTrig then return snippet.docTrig end
    return snippet.trigger
  end

  return table.concat(res, '')
end

---@param opts blink.cmp.LuasnipSourceOptions
function source.new(opts)
  local self = setmetatable({}, { __index = source })

  opts = vim.tbl_deep_extend('keep', opts or {}, {
    use_show_condition = true,
    show_autosnippets = true,
    prefer_doc_trig = false,
    use_label_description = false,
  })
  require('blink.cmp.config.utils').validate('sources.providers.snippets.opts', {
    use_show_condition = { opts.use_show_condition, 'boolean' },
    show_autosnippets = { opts.show_autosnippets, 'boolean' },
    prefer_doc_trig = { opts.prefer_doc_trig, 'boolean' },
    use_label_description = { opts.use_label_description, 'boolean' },
  }, opts)

  self.opts = opts
  self.items_cache = {}

  local luasnip_ag = vim.api.nvim_create_augroup('BlinkCmpLuaSnipReload', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'LuasnipSnippetsAdded',
    callback = function() self:reload() end,
    group = luasnip_ag,
    desc = 'Reset internal cache of luasnip source of blink.cmp when new snippets are added',
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'LuasnipCleanup',
    callback = function() self:reload() end,
    group = luasnip_ag,
    desc = 'Reload luasnip source of blink.cmp when snippets are cleared',
  })

  return self
end

function source:enabled()
  local ok, mod = pcall(require, 'luasnip')
  if ok then luasnip = mod end
  return ok
end

---@param ctx blink.cmp.Context
---@param callback fun(result?: blink.cmp.CompletionResponse)
function source:get_completions(ctx, callback)
  --- @type blink.cmp.CompletionItem[]
  local items = {}

  -- Gather snippets from relevant filetypes, including extensions
  for _, ft in ipairs(require('luasnip.util.util').get_snippet_filetypes()) do
    if self.items_cache[ft] and #self.items_cache[ft] > 0 then
      for _, item in ipairs(self.items_cache[ft]) do
        table.insert(items, utils.shallow_copy(item))
      end
      goto continue
    end

    -- Cache not yet available for this filetype
    self.items_cache[ft] = nil

    -- Gather filetype snippets and, optionally, autosnippets
    local snippets = luasnip.get_snippets(ft, { type = 'snippets' })
    if self.opts.show_autosnippets then
      local autosnippets = luasnip.get_snippets(ft, { type = 'autosnippets' })
      for _, s in ipairs(autosnippets) do
        add_luasnip_callback(s, 'enter', require('blink.cmp').hide)
      end
      snippets = utils.shallow_copy(snippets)
      vim.list_extend(snippets, autosnippets)
    end
    snippets = vim.tbl_filter(function(snip) return not snip.hidden end, snippets)

    -- Get the max priority for use with sortText
    local max_priority = 0
    for _, snip in ipairs(snippets) do
      max_priority = math.max(max_priority, snip.effective_priority or 0)
    end

    local ft_items = {}
    for _, snip in ipairs(snippets) do
      -- Convert priority of 1000 (with max of 8000) to string like "00007000|||asd" for sorting
      -- This will put high priority snippets at the top of the list, and break ties based on the trigger
      local inversed_priority = max_priority - (snip.effective_priority or 0)
      local sort_text = ('0'):rep(8 - #tostring(inversed_priority), '') .. inversed_priority .. '|||' .. snip.trigger

      --- @type lsp.CompletionItem
      local item = {
        kind = kind_snippet,
        label = snip.regTrig and snip.name or snip.trigger,
        insertText = get_insert_text(snip),
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        sortText = sort_text,
        data = { snip_id = snip.id, show_condition = snip.show_condition },
        labelDetails = snip.dscr and self.opts.use_label_description and {
          description = table.concat(snip.dscr, ' '),
        } or nil,
      }
      -- Populate snippet cache for this filetype
      table.insert(ft_items, item)
      -- While we're at it, also populate completion items for this request
      table.insert(items, utils.shallow_copy(item))
    end

    self.items_cache[ft] = ft_items

    ::continue::
  end

  -- Filter items based on show_condition, if configured
  if self.opts.use_show_condition then
    local line_to_cursor = ctx.line:sub(0, ctx.cursor[2] - 1)
    items = vim.tbl_filter(function(item) return item.data.show_condition(line_to_cursor) end, items)
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

function source:resolve(item, callback)
  local snip = luasnip.get_id_snippet(item.data.snip_id)

  local resolved_item = vim.deepcopy(item)

  ---@type string|string[]|nil
  local detail = snip:get_docstring()
  if type(detail) == 'table' then detail = table.concat(detail, '\n') end
  resolved_item.detail = detail

  ---@diagnostic disable-next-line: undefined-field
  if snip.dscr then
    resolved_item.documentation = {
      kind = 'markdown',
      ---@diagnostic disable-next-line: undefined-field
      value = table.concat(vim.lsp.util.convert_input_to_markdown_lines(snip.dscr), '\n'),
    }
  end

  callback(resolved_item)
end

---@param ctx blink.cmp.Context
---@param item blink.cmp.CompletionItem
function source:execute(ctx, item)
  local snip = luasnip.get_id_snippet(item.data.snip_id)

  -- if trigger is a pattern, expand "pattern" instead of actual snippet
  ---@diagnostic disable-next-line: undefined-field
  if snip.regTrig then
    ---@diagnostic disable-next-line: undefined-field
    local docTrig = self.opts.prefer_doc_trig and snip.docTrig
    snip = snip:get_pattern_expand_helper() --[[@as LuaSnip.Snippet]]

    if docTrig then
      add_luasnip_callback(snip, 'pre_expand', function(snip, _)
        if #snip.insert_nodes == 0 then
          snip.insert_nodes[0].static_text = { docTrig }
        else
          local matches = { string.match(docTrig, snip.trigger) }
          for i, match in ipairs(matches) do
            local idx = i ~= #matches and i or 0
            snip.insert_nodes[idx].static_text = { match }
          end
        end
      end)
    end
  end

  local cursor = ctx.get_cursor() --[[@as LuaSnip.BytecolBufferPosition]]
  cursor[1] = cursor[1] - 1

  local range = text_edits.get_from_item(item).range
  ---@type LuaSnip.BufferRegion
  local clear_region = {
    from = { range.start.line, range.start.character },
    to = cursor,
  }

  local line = ctx.get_line()
  local line_to_cursor = line:sub(1, cursor[2])
  local range_text = line:sub(range.start.character + 1, cursor[2])

  ---@type LuaSnip.Opts.SnipExpandExpandParams?
  local expand_params = snip:matches(line_to_cursor, {
    fallback_match = range_text ~= line_to_cursor and range_text,
  })

  if expand_params ~= nil then
    ---@diagnostic disable-next-line: undefined-field
    if expand_params.clear_region ~= nil then
      ---@diagnostic disable-next-line: undefined-field
      clear_region = expand_params.clear_region
    elseif expand_params.trigger ~= nil then
      clear_region.from = { cursor[1], cursor[2] - #expand_params.trigger }
      clear_region.to = cursor
    end
  end

  luasnip.snip_expand(snip, { expand_params = expand_params, clear_region = clear_region })
end

function source:reload() self.items_cache = {} end

return source
