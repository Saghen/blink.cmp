local utils = {}
local constants = require('blink.cmp.sources.cmdline.constants')

--- @param item blink.cmp.CompletionItem
--- @return lsp.CompletionItem
function utils.blink_item_to_lsp_item(item)
  local lsp_item = vim.deepcopy(item)
  lsp_item.score_offset = nil
  lsp_item.source_id = nil
  lsp_item.source_name = nil
  lsp_item.cursor_column = nil
  lsp_item.client_id = nil
  lsp_item.client_name = nil
  lsp_item.exact = nil
  lsp_item.score = nil
  return lsp_item
end

--- Check if we are in cmdline or cmdwin, optionally for specific types.
--- @param types? string[] Optional list of command types to check. If nil or empty, only checks for context.
--- @return boolean
function utils.is_command_line(types)
  local mode = vim.api.nvim_get_mode().mode

  -- If types is nil or empty, just check context
  if not types or #types == 0 then return mode == 'c' or vim.fn.win_gettype() == 'command' end

  -- If in cmdline mode, check type
  if mode == 'c' then
    local cmdtype = vim.fn.getcmdtype()
    return vim.tbl_contains(types, cmdtype)
  end

  -- If in command-line window, check type
  if vim.fn.win_gettype() == 'command' then
    local cmdtype = vim.fn.getcmdwintype()
    return vim.tbl_contains(types, cmdtype)
  end

  return false
end

--- Checks if the current command is one of the given Ex commands.
--- @param commands table List of command names to check against.
--- @return boolean
function utils.is_ex_command(commands)
  if not utils.is_command_line({ ':' }) then return false end

  local line = nil
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'c' then
    line = vim.fn.getcmdline()
  elseif vim.fn.win_gettype() == 'command' then
    line = vim.api.nvim_get_current_line()
  end

  if not line then return false end

  local ok, parsed = pcall(vim.api.nvim_parse_cmd, line, {})
  local cmd = (ok and parsed.cmd) or ''
  return vim.tbl_contains(commands, cmd)
end

---Get the current command-line completion type.
---@return string completion_type The detected completion type, or an empty string if unknown.
function utils.getcmdcompltype()
  if vim.fn.win_gettype() == 'command' then
    -- FIXME: AFAIK Neovim does not provide an API to determine the completion type in command-line window.
    -- Therefore, we attempt to parse the command-line and map it to a known completion type,
    -- either by guessing from the last argument or from the command name. This roughly mimics vim.fn.getcmdcompltype()
    local line = vim.api.nvim_get_current_line()
    local ok, parse_cmd = pcall(vim.api.nvim_parse_cmd, line, {})
    if ok then
      local function guess_type_by_prefix(arg)
        for prefix, completion_type in pairs(constants.arg_prefix_type) do
          if vim.startswith(arg, prefix) then return completion_type end
        end
        return nil
      end

      -- Guess by last argument
      local args = parse_cmd.args
      if #args > 0 then
        local last_arg = args[#args]
        local completion_type = guess_type_by_prefix(last_arg)
        if completion_type then return completion_type end
      end

      -- Guess by command name
      local completion_type = constants.commands_type[parse_cmd.cmd] or ''
      if #args > 0 then
        -- Adjust some completion type when args exists (to match cmdline)
        if completion_type == 'shellcmd' then completion_type = 'file' end
        if completion_type == 'command' then completion_type = '' end
      end

      return completion_type
    end

    return ''
  end

  return vim.fn.getcmdcompltype()
end

return utils
