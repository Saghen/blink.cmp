local utils = {}

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

--- Checks if the current command is an Ex substitute/global/vglobal command.
--- @return boolean
function utils.is_ex_substitute()
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
  return vim.tbl_contains({ 'substitute', 'global', 'vglobal' }, cmd)
end

---Get the current command-line completion type.
---@return string completion_type The detected completion type, or an empty string if unknown.
function utils.getcmdcompltype()
  -- FIXME: AFAIK Neovim does not provide an API to know which completion type we
  -- are in so we attempt to parse the command and map it to a known completion
  -- type using a constants mapping table.
  if vim.fn.win_gettype() == 'command' then
    local line = vim.api.nvim_get_current_line()
    local parse_cmd = vim.api.nvim_parse_cmd(line, {})
    if #parse_cmd.args > 0 then
      local constants = require('blink.cmp.sources.cmdline.constants')
      return constants.commands_type[parse_cmd.cmd] or ''
    end
  end

  return vim.fn.getcmdcompltype()
end

return utils
