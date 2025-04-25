local regex = require('blink.cmp.sources.path.regex')
local lib = {}

--- @param opts blink.cmp.PathOpts
--- @param context blink.cmp.Context
function lib.dirname(opts, context)
  -- HACK: move this :sub logic into the context?
  -- it's not obvious that you need to avoid going back a char if the start_col == end_col
  local line_before_cursor = context.line:sub(1, context.bounds.start_col - (context.bounds.length == 0 and 1 or 0))
  local s = regex.PATH:match_str(line_before_cursor)
  if not s then return nil end

  local dirname = string.gsub(string.sub(line_before_cursor, s + 2), regex.NAME .. '*$', '') -- exclude '/'
  local prefix = string.sub(line_before_cursor, 1, s + 1) -- include '/'

  local buf_dirname = opts.get_cwd(context)
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
    accept = accept and (not prefix:match('^[%s/]*$') or not lib.is_slash_comment())
    if accept then
      if opts.ignore_root_slash then
        return vim.fn.resolve(buf_dirname .. '/' .. dirname)
      else
        return vim.fn.resolve('/' .. dirname)
      end
    end
  end
  -- Windows drive letter (C:/)
  if prefix:match('(%a:)[/\\]$') then return vim.fn.resolve(prefix:match('(%a:)[/\\]$') .. '/' .. dirname) end
  return nil
end

--- @param context blink.cmp.Context
--- @param dirname string
--- @param include_hidden boolean
--- @param opts table
function lib.candidates(context, dirname, include_hidden, opts)
  local fs = require('blink.cmp.sources.path.fs')
  local ranges = lib.get_text_edit_ranges(context)
  return fs.scan_dir_async(dirname)
    :map(function(entries) return fs.fs_stat_all(dirname, entries) end)
    :map(function(entries)
      return vim.tbl_filter(function(entry) return include_hidden or entry.name:sub(1, 1) ~= '.' end, entries)
    end)
    :map(function(entries)
      return vim.tbl_map(
        function(entry)
          return lib.entry_to_completion_item(
            entry,
            dirname,
            entry.type == 'directory' and ranges.directory or ranges.file,
            opts
          )
        end,
        entries
      )
    end)
end

function lib.is_slash_comment()
  local commentstring = vim.bo.commentstring or ''
  local no_filetype = vim.bo.filetype == ''
  local is_slash_comment = false
  is_slash_comment = is_slash_comment or commentstring:match('/%*')
  is_slash_comment = is_slash_comment or commentstring:match('//')
  return is_slash_comment and not no_filetype
end

--- @param entry { name: string, type: string, stat: table }
--- @param dirname string
--- @param range lsp.Range
--- @param opts table
--- @return blink.cmp.CompletionItem[]
function lib.entry_to_completion_item(entry, dirname, range, opts)
  local is_dir = entry.type == 'directory'
  local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
  local insert_text = is_dir and opts.trailing_slash and entry.name .. '/' or entry.name
  return {
    label = (opts.label_trailing_slash and is_dir) and entry.name .. '/' or entry.name,
    kind = is_dir and CompletionItemKind.Folder or CompletionItemKind.File,
    insertText = insert_text,
    textEdit = { newText = insert_text, range = range },
    sortText = (is_dir and '1' or '2') .. entry.name:lower(), -- Sort directories before files
    data = { path = entry.name, full_path = dirname .. '/' .. entry.name, type = entry.type, stat = entry.stat },
  }
end

--- @param context blink.cmp.Context
--- @return { file: lsp.Range, directory: lsp.Range }
function lib.get_text_edit_ranges(context)
  local line_before_cursor = context.line:sub(1, context.cursor[2])
  local next_letter_is_slash = context.line:sub(context.cursor[2] + 1, context.cursor[2] + 1) == '/'

  local last_part_idx = lib.get_last_path_part(line_before_cursor)

  -- TODO: return the insert and replace ranges, instead of only the insert range
  return {
    file = {
      start = { line = context.cursor[1] - 1, character = last_part_idx - 1 },
      ['end'] = { line = context.cursor[1] - 1, character = context.cursor[2] },
    },
    directory = {
      start = { line = context.cursor[1] - 1, character = last_part_idx - 1 },
      -- replace the slash after the cursor, if it exists
      ['end'] = { line = context.cursor[1] - 1, character = context.cursor[2] + (next_letter_is_slash and 1 or 0) },
    },
  }
end

--- @param path string
--- @return number
function lib.get_last_path_part(path)
  local i = #path
  local start_pos = 1
  while i > 0 do
    local char = path:sub(i, i)

    -- Forward slash (linux/mac delimiter)
    if char == '/' then
      start_pos = i + 1
      break

    -- Backslash (windows delimiter or escape sequence)
    elseif char == '\\' then
      if i ~= #path then
        -- if the next character is a special character, it's likely
        -- an escape sequence
        local next_char = path:sub(i + 1, i + 1)
        if not next_char:match('[ "\'`$&*(){}[]|;:<>?]') then
          start_pos = i + 1
          break
        end
      else
        start_pos = i + 1
        break
      end
    end

    i = i - 1
  end

  return start_pos
end

return lib
