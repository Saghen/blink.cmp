-- Credit goes to @hrsh7th for the code that this was based on
-- https://github.com/hrsh7th/cmp-cmdline
-- License: MIT

local async = require('blink.cmp.lib.async')
local constants = require('blink.cmp.sources.cmdline.constants')
local path_lib = require('blink.cmp.sources.path.lib')

--- Split the command line into arguments, handling path escaping and trailing spaces.
--- For path completions, split by paths and normalize each one if needed.
--- For other completions, splits by spaces and preserves trailing empty arguments.
---@param context table
---@param is_path_completion boolean
---@return string, table
local function smart_split(context, is_path_completion)
  local line = context.line

  if is_path_completion then
    -- Split the line into tokens, respecting escaped spaces in paths
    local tokens = path_lib:split_unescaped(line:gsub('^%s+', ''))
    local cmd = tokens[1]
    local args = {}

    for i = 2, #tokens do
      local arg = tokens[i]
      -- Escape argument if it contains unescaped spaces
      -- Some commands may expect escaped paths (:edit), others may not (:view)
      if arg and arg ~= '' and not arg:find('\\ ') then arg = path_lib:fnameescape(arg) end
      table.insert(args, arg)
    end
    return line, { cmd, unpack(args) }
  end

  return line, vim.split(line:gsub('^%s+', ''), ' ', { plain = true })
end

-- Find the longest match for a given set of patterns
---@param str string
---@param patterns table
---@return string
local function longest_match(str, patterns)
  local best = ''
  for _, pat in ipairs(patterns) do
    local m = str:match(pat)
    if m and #m > #best then best = m end
  end
  return best
end

---@param name string
---@return boolean?
local function is_boolean_option(name)
  local ok, opt = pcall(function() return vim.opt[name]:get() end)
  if ok then return type(opt) == 'boolean' end
end

--- @class blink.cmp.Source
local cmdline = {}

function cmdline.new()
  local self = setmetatable({}, { __index = cmdline })
  self.before_line = ''
  self.offset = -1
  self.ctype = ''
  self.items = {}
  return self --[[@as blink.cmp.Source]]
end

---@return boolean
function cmdline:enabled()
  return vim.api.nvim_get_mode().mode == 'c' and vim.tbl_contains({ ':', '@' }, vim.fn.getcmdtype())
end

---@return table
function cmdline:get_trigger_characters() return { ' ', '.', '#', '-', '=', '/', ':', '!' } end

---@param context blink.cmp.Context
---@param callback fun(result?: blink.cmp.CompletionResponse)
---@return fun()
function cmdline:get_completions(context, callback)
  local completion_type = vim.fn.getcmdcompltype()

  local is_path_completion = vim.tbl_contains(constants.completion_types.path, completion_type)
  local is_buffer_completion = vim.tbl_contains(constants.completion_types.buffer, completion_type)

  local context_line, arguments = smart_split(context, is_path_completion or is_buffer_completion)
  local cmd = arguments[1]
  local before_cursor = context_line:sub(1, context.cursor[2])
  local _, args_before_cursor = smart_split({ line = before_cursor }, is_path_completion or is_buffer_completion)
  local arg_number = #args_before_cursor

  local leading_spaces = context.line:match('^(%s*)') -- leading spaces in the original query
  local text_before_argument = table.concat(require('blink.cmp.lib.utils').slice(arguments, 1, arg_number - 1), ' ')
    .. (arg_number > 1 and ' ' or '')

  local current_arg = arguments[arg_number]
  local keyword_config = require('blink.cmp.config').completion.keyword
  local keyword = context.get_bounds(keyword_config.range)
  local current_arg_prefix = current_arg:sub(1, keyword.start_col - #text_before_argument - 1)

  local task = async.task
    .empty()
    :map(function()
      -- Special case for help where we read all the tags ourselves
      if completion_type == 'help' then
        return require('blink.cmp.sources.cmdline.help').get_completions(current_arg_prefix)
      end

      local completions = {}

      -- Input mode (vim.fn.input())
      if vim.fn.getcmdtype() == '@' then
        local completion_args = vim.split(completion_type, ',', { plain = true })
        local completion_type = completion_args[1]
        local completion_func = completion_args[2]

        -- Handle custom completions explicitly, since `getcompletion()` will fail when using this type
        -- TODO: we cannot handle v:lua, s:, and <sid> completions. is there a better solution here where we can
        -- get completions in input() mode without calling ourselves?
        if
          vim.startswith(completion_type, 'custom')
          and not vim.startswith(completion_func:lower(), 's:')
          and not vim.startswith(completion_func:lower(), 'v:lua')
          and not vim.startswith(completion_func:lower(), '<sid>')
        then
          local success, fn_completions =
            pcall(vim.fn.call, completion_func, { current_arg_prefix, vim.fn.getcmdline(), vim.fn.getcmdpos() })

          if success then
            if type(fn_completions) == 'table' then
              completions = fn_completions
            -- `custom,` type returns a string, delimited by newlines
            elseif type(fn_completions) == 'string' then
              completions = vim.split(fn_completions, '\n')
            end
          end

        -- Regular input completions, use the type defined by the input
        else
          local query = (text_before_argument .. current_arg_prefix):gsub([[\\]], [[\\\\]])
          -- TODO: handle `custom` type
          local compl_type = not vim.startswith(completion_type, 'custom') and completion_type or 'cmdline'
          if compl_type ~= '' then
            -- path completions uniquely expect only the current path
            query = is_path_completion and current_arg_prefix or query

            completions = vim.fn.getcompletion(query, compl_type)
            if type(completions) ~= 'table' then completions = {} end
          end
        end

      -- Cmdline mode
      else
        local query = (text_before_argument .. current_arg_prefix):gsub([[\\]], [[\\\\]])
        completions = vim.fn.getcompletion(query, 'cmdline')
      end

      return completions
    end)
    :schedule()
    :map(function(completions)
      -- The getcompletion() api is inconsistent in whether it returns the prefix or not.
      --
      -- I.e. :set shiftwidth=| will return '2'
      -- I.e. :Neogit kind=| will return 'kind=commit'
      --
      -- For simplicity, excluding the first argument, we always replace the entire command argument,
      -- so we want to ensure the prefix is always in the new_text.
      --
      -- In the case of file/buffer completion, we use the basename for display
      -- but insert the full path for insertion.
      -- In all other cases, we want to check for the prefix and remove it from the filter text
      -- and add it to the newText

      ---@cast completions string[]
      local unique_prefixes = is_buffer_completion
          and #completions < 2000
          and path_lib:compute_unique_suffixes(completions)
        or {}

      ---@type blink.cmp.CompletionItem[]
      local items = {}
      for _, completion in ipairs(completions) do
        local filter_text, new_text = completion, completion
        local label, label_details

        -- path completion in commands, e.g. `chdir <path>` and options, e.g. `:set directory=<path>`
        if is_path_completion then
          filter_text = path_lib.basename_with_sep(completion)
          new_text = vim.fn.fnameescape(completion)
          if cmd == 'set' then
            new_text = current_arg_prefix:sub(1, current_arg_prefix:find('=') or #current_arg_prefix) .. new_text
          end

        -- buffer commands
        elseif is_buffer_completion then
          label = unique_prefixes[completion] or completion
          if #unique_prefixes[completion] then
            label_details = { description = completion:sub(1, -#unique_prefixes[completion] - 2) }
          end
          new_text = vim.fn.fnameescape(completion)

        -- env variables
        elseif completion_type == 'environment' then
          filter_text = '$' .. completion
          new_text = '$' .. completion

        -- for other completions, prepend the prefix
        elseif vim.tbl_contains({ 'lua', '' }, completion_type) then
          new_text = current_arg_prefix .. completion
        end

        local start_pos = #text_before_argument + #leading_spaces

        -- exclude range for commands on the first argument
        if arg_number == 1 and completion_type == 'command' then
          local prefix = longest_match(current_arg, {
            "^%s*'<%s*,%s*'>%s*", -- Visual range, e.g., '<,>'
            '^%s*%d+%s*,%s*%d+%s*', -- Numeric range, e.g., 3,5
            '^%s*[%p]+%s*', -- One or more punctuation characters
          })
          start_pos = start_pos + #prefix
        end

        ---@type blink.cmp.CompletionItem
        local item = {
          label = label or filter_text,
          filterText = filter_text,
          labelDetails = label_details,
          -- move items starting with special characters to the end of the list
          sortText = filter_text:lower():gsub('^([!-@\\[-`])', '~%1'),
          textEdit = {
            newText = new_text,
            insert = {
              start = { line = 0, character = start_pos },
              ['end'] = { line = 0, character = vim.fn.getcmdpos() - 1 },
            },
            replace = {
              start = { line = 0, character = start_pos },
              ['end'] = {
                line = 0,
                character = math.min(start_pos + #current_arg, context.bounds.start_col + context.bounds.length - 1),
              },
            },
          },
          kind = require('blink.cmp.types').CompletionItemKind.Property,
        }
        items[#items + 1] = item

        if completion_type == 'option' and is_boolean_option(filter_text) then
          filter_text = 'no' .. filter_text
          items[#items + 1] = vim.tbl_deep_extend('force', {}, item, {
            label = filter_text,
            filterText = filter_text,
            sortText = filter_text,
            textEdit = { newText = 'no' .. new_text },
          }) --[[@as blink.cmp.CompletionItem]]
        end
      end

      callback({
        is_incomplete_backward = completion_type ~= 'help',
        is_incomplete_forward = false,
        items = items,
        ---@diagnostic disable-next-line: missing-return
      })
    end)
    :catch(function(err)
      -- TODO: is there a way to avoid throwing this error?
      if type(err) ~= 'string' or not err:match('Vim:E433: No tags file') then
        vim.notify('Error while fetching completions: ' .. err, vim.log.levels.ERROR, { title = 'blink.cmp' })
      end
      ---@diagnostic disable-next-line: missing-return
      callback({ is_incomplete_backward = false, is_incomplete_forward = false, items = {} })
    end)

  return function() task:cancel() end
end

return cmdline
