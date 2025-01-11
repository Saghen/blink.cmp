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

  local task = async.task
    .empty()
    :map(function()
      -- Special case for help where we read all the tags ourselves
      if vim.tbl_contains(constants.help_commands, arguments[1] or '') then
        return require('blink.cmp.sources.cmdline.help').get_completions(current_arg_prefix)
      end

      local completions = {}
      local completion_args = vim.split(vim.fn.getcmdcompltype(), ',', { plain = true })
      local completion_type = completion_args[1]
      local completion_func = completion_args[2]

      -- Handle custom completions explicitly, since otherwise they won't work in input() mode (getcmdtype() == '@')
      -- TODO: however, we cannot handle s: and <sid> completions. is there a better solution here where we can get
      -- completions in input() mode without calling ourselves?
      if
        vim.startswith(completion_type, 'custom')
        and not vim.startswith(completion_func, 's:')
        and not vim.startswith(completion_func, '<sid>')
      then
        completions = vim.fn.call(completion_func, { current_arg_prefix, vim.fn.getcmdline(), vim.fn.getcmdpos() })
        -- `custom,` type returns a string, delimited by newlines
        if type(completions) == 'string' then completions = vim.split(completions, '\n') end
      else
        local query = (text_before_argument .. current_arg_prefix):gsub([[\\]], [[\\\\]])
        completions = vim.fn.getcompletion(query, 'cmdline')
      end

      -- Special case for files, escape special characters
      if vim.tbl_contains(constants.file_commands, arguments[1] or '') then
        completions = vim.tbl_map(function(completion) return vim.fn.fnameescape(completion) end, completions)
      end

      return completions
    end)
    :map(function(completions)
      local items = {}
      for _, completion in ipairs(completions) do
        local has_prefix = string.find(completion, current_arg_prefix, 1, true) == 1

        -- remove prefix from the filter text
        local filter_text = completion
        if has_prefix then filter_text = completion:sub(#current_arg_prefix + 1) end

        -- for lua, use the filter text as the label since it doesn't include the prefix
        local label = arguments[1] == 'lua' and filter_text or completion

        -- add prefix to the newText
        local new_text = completion
        if not has_prefix then new_text = current_arg_prefix .. completion end

        table.insert(items, {
          label = label,
          filterText = filter_text,
          -- move items starting with special characters to the end of the list
          sortText = label:lower():gsub('^([!-@\\[-`])', '~%1'),
          textEdit = {
            newText = new_text,
            range = {
              start = { line = 0, character = #text_before_argument },
              ['end'] = { line = 0, character = #text_before_argument + #current_arg },
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
