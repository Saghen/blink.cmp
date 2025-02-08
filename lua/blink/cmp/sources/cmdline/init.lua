-- Credit goes to @hrsh7th for the code that this was based on
-- https://github.com/hrsh7th/cmp-cmdline
-- License: MIT

local async = require('blink.cmp.lib.async')
local constants = require('blink.cmp.sources.cmdline.constants')

--- @class blink.cmp.Source
local cmdline = {}

function cmdline.new()
  local self = setmetatable({}, { __index = cmdline })
  self.before_line = ''
  self.offset = -1
  self.ctype = ''
  self.items = {}
  return self
end

function cmdline:get_trigger_characters() return { ' ', '.', '#', '-', '=', '/', ':' } end

function cmdline:get_completions(context, callback)
  local arguments = vim.split(context.line, ' ', { plain = true })
  local arg_number = #vim.split(context.line:sub(1, context.cursor[2] + 1), ' ', { plain = true })
  local text_before_argument = table.concat(require('blink.cmp.lib.utils').slice(arguments, 1, arg_number - 1), ' ')
    .. (arg_number > 1 and ' ' or '')

  local current_arg = arguments[arg_number]
  local keyword_config = require('blink.cmp.config').completion.keyword
  local keyword = context.get_bounds(keyword_config.range)
  local current_arg_prefix = current_arg:sub(1, keyword.start_col - #text_before_argument - 1)

  -- Parse the command to ignore modifiers like :vert help
  -- Fails in some cases, like context.line = ':vert' so we fallback to the first argument
  local valid_cmd, parsed = pcall(vim.api.nvim_parse_cmd, context.line, {})
  local cmd = (valid_cmd and parsed.cmd) or arguments[1] or ''

  local task = async.task
    .empty()
    :map(function()
      -- Special case for help where we read all the tags ourselves
      if vim.tbl_contains(constants.help_commands, cmd) and arg_number > 1 then
        return require('blink.cmp.sources.cmdline.help').get_completions(current_arg_prefix)
      end

      local completions = {}
      local completion_args = vim.split(vim.fn.getcmdcompltype(), ',', { plain = true })
      local completion_type = completion_args[1]
      local completion_func = completion_args[2]

      -- Handle custom completions explicitly, since otherwise they won't work in input() mode (getcmdtype() == '@')
      -- TODO: however, we cannot handle v:lua, s:, and <sid> completions. is there a better solution here where we can
      -- get completions in input() mode without calling ourselves?
      if
        vim.fn.getcmdtype() == '@'
        and vim.startswith(completion_type, 'custom')
        and not vim.startswith(completion_func:lower(), 's:')
        and not vim.startswith(completion_func:lower(), 'v:lua')
        and not vim.startswith(completion_func:lower(), '<sid>')
      then
        completions = vim.fn.call(completion_func, { current_arg_prefix, vim.fn.getcmdline(), vim.fn.getcmdpos() })
        -- `custom,` type returns a string, delimited by newlines
        if type(completions) == 'string' then completions = vim.split(completions, '\n') end
      else
        local query = (text_before_argument .. current_arg_prefix):gsub([[\\]], [[\\\\]])
        completions = vim.fn.getcompletion(query, 'cmdline')
      end

      -- Special case for files, escape special characters
      if vim.tbl_contains(constants.file_commands, cmd) then
        completions = vim.tbl_map(function(completion) return vim.fn.fnameescape(completion) end, completions)
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
      -- In the case of file/buffer completion, we can be sure that the prefix is included
      -- In all other cases, we want to check for the prefix and remove it from the filter text
      -- and add it to the newText

      -- Helper function: find the longest match for a given set of patterns
      local function longest_match(str, patterns)
        local best = ''
        for _, pat in ipairs(patterns) do
          local m = str:match(pat)
          if m and #m > #best then best = m end
        end
        return best
      end

      local completion_type = vim.fn.getcmdcompltype()
      local is_file_completion = completion_type == 'file' or completion_type == 'buffer'
      local is_first_arg = arg_number == 1

      local items = {}
      for _, completion in ipairs(completions) do
        local has_prefix = string.find(completion, current_arg_prefix, 1, true) == 1

        local filter_text = completion
        local new_text = completion
        if not is_first_arg and not is_file_completion then
          -- remove prefix from the filter text
          if has_prefix then filter_text = completion:sub(#current_arg_prefix + 1) end

          -- add prefix to the newText
          if not has_prefix then new_text = current_arg_prefix .. completion end
        end

        local start_pos = #text_before_argument

        -- exclude range on the first argument
        if is_first_arg then
          local prefix = longest_match(current_arg, {
            "^%s*'<%s*,%s*'>%s*", -- Visual range, e.g., '<,>'
            '^%s*%d+%s*,%s*%d+%s*', -- Numeric range, e.g., 3,5
            '^%s*[%p]+%s*', -- One or more punctuation characters
          })
          start_pos = start_pos + #prefix
        end

        table.insert(items, {
          label = filter_text,
          filterText = filter_text,
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
        })
      end

      callback({
        is_incomplete_backward = true,
        is_incomplete_forward = false,
        items = items,
      })
    end)
    :catch(function(err)
      vim.notify('Error while fetching completions: ' .. err, vim.log.levels.ERROR, { title = 'blink.cmp' })
      callback({ is_incomplete_backward = false, is_incomplete_forward = false, items = {} })
    end)

  return function() task:cancel() end
end

return cmdline
