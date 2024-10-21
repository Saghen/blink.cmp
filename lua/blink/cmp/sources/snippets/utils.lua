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

return utils
