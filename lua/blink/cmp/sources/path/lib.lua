local lib = {}

--- @param path_regex vim.regex
--- @param get_cwd fun(context: blink.cmp.CompletionContext): string
--- @param context blink.cmp.CompletionContext
function lib.dirname(path_regex, get_cwd, context)
  local line_before_cursor = context.line:sub(1, context.cursor[2])
  local s = path_regex:match_str(line_before_cursor)
  if not s then return nil end

  local dirname = string.gsub(string.sub(line_before_cursor, s + 2), '%a*$', '') -- exclude '/'
  local prefix = string.sub(line_before_cursor, 1, s + 1) -- include '/'

  local buf_dirname = get_cwd(context)
  if vim.api.nvim_get_mode().mode == 'c' then buf_dirname = vim.fn.getcwd() end
  if prefix:match('%.%./$') then return vim.fn.resolve(buf_dirname .. '/../' .. dirname) end
  if prefix:match('%./$') or prefix:match('"$') or prefix:match("'$") then
    return vim.fn.resolve(buf_dirname .. '/' .. dirname)
  end
  if prefix:match('~/$') then return vim.fn.resolve(vim.fn.expand('~') .. '/' .. dirname) end
  local env_var_name = prefix:match('%$([%a_]+)/$')
  if env_var_name then
    local env_var_value = vim.fn.getenv(env_var_name)
    if env_var_value ~= vim.NIL then return vim.fn.resolve(env_var_value .. '/' .. dirname) end
  end
  if prefix:match('/$') then
    local accept = true
    -- Ignore URL components
    accept = accept and not prefix:match('%a/$')
    -- Ignore URL scheme
    accept = accept and not prefix:match('%a+:/$') and not prefix:match('%a+://$')
    -- Ignore HTML closing tags
    accept = accept and not prefix:match('</$')
    -- Ignore math calculation
    accept = accept and not prefix:match('[%d%)]%s*/$')
    -- Ignore / comment
    accept = accept and (not prefix:match('^[%s/]*$') or not self:_is_slash_comment())
    if accept then return vim.fn.resolve('/' .. dirname) end
  end
  return nil
end

--- @param dirname string
--- @param include_hidden boolean
--- @param opts table
function lib.candidates(dirname, include_hidden, opts)
  local fs = require('blink.cmp.sources.path.fs')
  return fs.scan_dir_async(dirname)
    :map(function(entries) return fs.fs_stat_all(dirname, entries) end)
    :map(function(entries)
      return vim.tbl_filter(function(entry) return include_hidden or entry.name ~= '.' end, entries)
    end)
    :map(function(entries)
      return vim.tbl_map(function(entry) return lib.entry_to_completion_item(entry, opts) end, entries)
    end)
end

function lib.is_slash_comment(_)
  local commentstring = vim.bo.commentstring or ''
  local no_filetype = vim.bo.filetype == ''
  local is_slash_comment = false
  is_slash_comment = is_slash_comment or commentstring:match('/%*')
  is_slash_comment = is_slash_comment or commentstring:match('//')
  return is_slash_comment and not no_filetype
end

--- @param entry { name: string, type: string, stat: table }
--- @param opts table
--- @return blink.cmp.CompletionItem[]
function lib.entry_to_completion_item(entry, opts)
  local is_dir = entry.type == 'directory'
  return {
    label = (opts.label_trailing_slash and is_dir) and entry.name .. '/' or entry.name,
    kind = is_dir and vim.lsp.protocol.CompletionItemKind.Folder or vim.lsp.protocol.CompletionItemKind.File,
    insertText = is_dir and entry.name .. '/' or entry.name,
    word = opts.trailing_slash and entry.name or nil,
    data = { path = entry.name, type = entry.type, stat = entry.stat },
  }
end

return lib
