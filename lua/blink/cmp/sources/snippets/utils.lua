local utils = {}

--- Parses the json file and notifies the user if there's an error
---@param path string
---@param json string
function utils.parse_json_with_error_msg(path, json)
  local ok, parsed = pcall(vim.json.decode, json)
  if not ok then
    vim.notify(
      'Failed to parse json file "' .. path .. '" for blink.cmp snippets. Error: ' .. parsed,
      vim.log.levels.ERROR
    )
    return {}
  end
  return parsed
end

---@type fun(path: string): string|nil
function utils.read_file(path)
  local file = io.open(path, 'r')
  if not file then return nil end
  local content = file:read('*a')
  file:close()
  return content
end

---@type fun(input: string): vim.snippet.Node<vim.snippet.SnippetData>|nil
function utils.safe_parse(input)
  local safe, parsed = pcall(vim.lsp._snippet_grammar.parse, input)
  if not safe then return nil end
  return parsed
end

---@type fun(snippet: blink.cmp.Snippet, fallback: string): table
function utils.read_snippet(snippet, fallback)
  local snippets = {}
  local prefix = snippet.prefix or fallback
  local description = snippet.description or fallback
  local body = snippet.body

  if type(description) == 'table' then description = vim.fn.join(description, '') end

  if type(prefix) == 'table' then
    for _, p in ipairs(prefix) do
      snippets[p] = {
        prefix = p,
        body = body,
        description = description,
      }
    end
  else
    snippets[prefix] = {
      prefix = prefix,
      body = body,
      description = description,
    }
  end
  return snippets
end

function utils.get_tab_stops(snippet)
  local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(snippet)
  if not expanded_snippet then return end

  local tabstops = {}
  local grammar = require('vim.lsp._snippet_grammar')
  local line = 1
  local character = 1
  for _, child in ipairs(expanded_snippet.data.children) do
    local lines = tostring(child) == '' and {} or vim.split(tostring(child), '\n')
    line = line + math.max(#lines - 1, 0)
    character = #lines == 0 and character or #lines > 1 and #lines[#lines] or (character + #lines[#lines])
    if child.type == grammar.NodeType.Placeholder or child.type == grammar.NodeType.Tabstop then
      table.insert(tabstops, { index = child.data.tabstop, line = line, character = character })
    end
  end

  table.sort(tabstops, function(a, b) return a.index < b.index end)
  return tabstops
end

return utils
