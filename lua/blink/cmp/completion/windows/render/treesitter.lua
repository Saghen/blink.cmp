local treesitter = {}

--- @param ctx blink.cmp.DrawItemContext
--- @param opts? {offset?: number}
function treesitter.highlight(ctx, opts)
  ---@type blink.cmp.DrawHighlight[]
  local ret = {}
  local source = ctx.label
  local offset = opts and opts.offset or 0

  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  if not lang then return ret end

  local ok, parser = pcall(vim.treesitter.get_string_parser, source, lang)
  if not ok then return ret end

  parser:parse(true)

  parser:for_each_tree(function(tstree, tree)
    if not tstree then return end
    local query = vim.treesitter.query.get(tree:lang(), 'highlights')
    -- Some injected languages may not have highlight queries.
    if not query then return end

    for capture, node in query:iter_captures(tstree:root(), source) do
      local _, start_col, _, end_col = node:range()

      ---@type string
      local name = query.captures[capture]
      if name ~= 'spell' then
        ret[#ret + 1] = {
          offset + start_col,
          offset + end_col,
          group = '@' .. name .. '.' .. lang,
        }
      end
    end
  end)
  return ret
end

return treesitter
