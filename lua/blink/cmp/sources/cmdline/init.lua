-- Credit goes to @hrsh7th for the code that this was based on
-- https://github.com/hrsh7th/cmp-cmdline
-- License: MIT

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

function cmdline:get_trigger_characters() return { ' ', '.', '#', '-', '=', '/' } end

function cmdline:get_completions(context, callback)
  local arguments = vim.split(context.line, ' ', { plain = true })
  local arg_number = #vim.split(context.line:sub(1, context.cursor[2] + 1), ' ', { plain = true })
  local text_before_cursor = table.concat(require('blink.cmp.lib.utils').slice(arguments, 1, arg_number - 1), ' ')
    .. (arg_number > 1 and ' ' or '')

  local current_arg = arguments[arg_number]
  local keyword_config = require('blink.cmp.config').completion.keyword
  local keyword = context.get_regex_around_cursor(
    keyword_config.range,
    keyword_config.regex,
    keyword_config.exclude_from_prefix_regex
  )
  local current_arg_prefix = current_arg:sub(1, keyword.start_col - 1)

  local query = (text_before_cursor .. current_arg_prefix):gsub([[\\]], [[\\\\]])
  local completions = vim.fn.getcompletion(query, 'cmdline')

  local items = {}
  for _, completion in ipairs(completions) do
    -- remove prefix from the label
    if string.find(completion, current_arg_prefix, 1, true) == 1 then
      completion = completion:sub(#current_arg_prefix + 1)
    end

    -- add prefix to the newText
    local new_text = completion
    if string.find(new_text, current_arg_prefix, 1, true) ~= 1 then new_text = current_arg_prefix .. completion end

    table.insert(items, {
      label = completion,
      insertText = completion,
      textEdit = {
        newText = new_text,
        range = {
          start = { line = 0, character = #text_before_cursor },
          ['end'] = { line = 0, character = #text_before_cursor + #current_arg },
        },
      },
      kind = require('blink.cmp.types').CompletionItemKind.Property,
    })
  end

  callback({
    is_incomplete_backward = false,
    is_incomplete_forward = false,
    items = items,
  })
end

return cmdline
