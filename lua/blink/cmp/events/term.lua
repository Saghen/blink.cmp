--- @class blink.cmp.TermEventsListener
--- @field on_char_added fun(char: string)
--- @field on_term_leave fun()

--- @class blink.cmp.TermEvents
local term_events = {}

local term_on_key_ns = vim.api.nvim_create_namespace('blink-term-keypress')
local term_command_start_ns = vim.api.nvim_create_namespace('blink-term-command-start')

--- @param opts blink.cmp.TermEventsListener
function term_events.listen(opts)
  local last_char = ''
  -- There's no terminal equivalent to 'InsertCharPre', so we need to simulate
  -- something similar to this by watching with `vim.on_key()`
  vim.api.nvim_create_autocmd('TermEnter', {
    callback = function()
      vim.on_key(function(k) last_char = k end, term_on_key_ns)
    end,
  })
  vim.api.nvim_create_autocmd('TermLeave', {
    callback = function()
      vim.on_key(nil, term_on_key_ns)
      last_char = ''
      opts.on_term_leave()
    end,
  })

  vim.api.nvim_create_autocmd('TextChangedT', {
    callback = function()
      -- no characters added so let cursormoved handle it
      if last_char == '' then return end

      opts.on_char_added(last_char)
      last_char = ''
    end,
  })

  --- To build proper shell completions we need to know where prompts end and typed commands start.
  --- The most reliable way to get this information is to listen for terminal escape sequences. This
  --- adds a listener for the terminal escape sequence \027]133;B (called FTCS_COMMAND_START) which
  --- marks the start of a command. To enable plugins to access this information later we put an extmark
  --- at the position in the buffer.
  --- For documentation on FTCS_COMMAND_START see https://iterm2.com/3.0/documentation-escape-codes.html
  ---
  --- Example:
  --- If you type "ls --he" into a terminal buffer in neovim the current line will look something like this:
  --- ~/Downloads > ls --he|
  --- "~/Downloads > " is your prompt <- an extmark is added after this
  --- "ls --he" is the command you typed <- this is what we need to provide proper shell completions
  --- "|" marks your cursor position
  vim.api.nvim_create_autocmd('TermRequest', {
    callback = function(args)
      if string.match(args.data.sequence, '^\027]133;B') then
        local row, col = table.unpack(args.data.cursor)
        vim.api.nvim_buf_set_extmark(args.buf, term_command_start_ns, row - 1, col, {})
      end
    end,
  })

  return setmetatable({}, { __index = term_events })
end

return term_events
