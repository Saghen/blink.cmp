local regex = require('blink.cmp.sources.cmdline.regex')

--- @class blink.cmp.Source
local cmdline = {}

---@param word string
---@return boolean?
local function is_boolean_option(word)
  local ok, opt = pcall(function() return vim.opt[word]:get() end)
  if ok then return type(opt) == 'boolean' end
end

---@class cmp.Cmdline.Definition
---@field ctype string
---@field regex string
---@field kind lsp.CompletionItemKind
---@field isIncomplete boolean
---@field exec fun(option: table, arglead: string, cmdline: string, force: boolean): lsp.CompletionItem[]
---@field fallback boolean?

---@type cmp.Cmdline.Definition[]
local definitions = {
  {
    ctype = 'cmdline',
    regex = [=[[^[:blank:]]*$]=],
    kind = require('blink.cmp.types').CompletionItemKind.Variable,
    isIncomplete = true,
    ---@param option cmp-cmdline.Option
    exec = function(option, arglead, target, force)
      -- Ignore range only cmdline. (e.g.: 4, '<,'>)
      if not force and regex.ONLY_RANGE_REGEX:match_str(target) then return {} end

      local _, parsed = pcall(function()
        local s, e = regex.COUNT_RANGE_REGEX:match_str(target)
        if s and e then target = target:sub(e + 1) end
        -- nvim_parse_cmd throw error when the cmdline contains range specifier.
        return vim.api.nvim_parse_cmd(target, {}) or {}
      end)
      parsed = parsed or {}

      -- Check ignore cmd.
      if vim.tbl_contains(option.ignore_cmds, parsed.cmd) then return {} end

      -- Cleanup modifiers.
      -- We can just remove modifiers because modifiers is always separated by space.
      if arglead ~= target then
        while true do
          local s, e = regex.MODIFIER_REGEX:match_str(target)
          if s == nil then break end
          target = string.sub(target, e + 1)
        end
      end

      -- Support `lua vim.treesitter._get|` or `'<,'>del|` completion.
      -- In this case, the `vim.fn.getcompletion` will return only `get_query` for `vim.treesitter.get_|`.
      -- We should detect `vim.treesitter.` and `get_query` separately.
      -- TODO: The `\h\w*` was choosed by huristic. We should consider more suitable detection.
      local fixed_input
      do
        local suffix_pos = vim.regex([[\h\w*$]]):match_str(arglead)
        fixed_input = string.sub(arglead, 1, suffix_pos or #arglead)
      end

      -- The `vim.fn.getcompletion` does not return `*no*cursorline` option.
      -- cmp-cmdline corrects `no` prefix for option name.
      local is_option_name_completion = regex.OPTION_NAME_COMPLETION_REGEX:match_str(target) ~= nil

      --- create items.
      local items = {}
      local escaped = target:gsub([[\\]], [[\\\\]])
      for _, word_or_item in ipairs(vim.fn.getcompletion(escaped, 'cmdline')) do
        local word = type(word_or_item) == 'string' and word_or_item or word_or_item.word
        local item = { label = word }
        table.insert(items, item)
        if is_option_name_completion and is_boolean_option(word) then
          table.insert(
            items,
            vim.tbl_deep_extend('force', {}, item, {
              label = 'no' .. word,
              filterText = word,
            })
          )
        end
      end

      -- fix label with `fixed_input`
      for _, item in ipairs(items) do
        if not string.find(item.label, fixed_input, 1, true) then item.label = fixed_input .. item.label end
      end

      -- fix trailing slash for path like item
      if option.treat_trailing_slash then
        for _, item in ipairs(items) do
          local is_target = string.match(item.label, [[/$]])
          is_target = is_target and not (string.match(item.label, [[~/$]]))
          is_target = is_target and not (string.match(item.label, [[%./$]]))
          is_target = is_target and not (string.match(item.label, [[%.%./$]]))
          if is_target then item.label = item.label:sub(1, -2) end
        end
      end
      return items
    end,
  },
}

function cmdline.new()
  local self = setmetatable({}, { __index = cmdline })
  self.before_line = ''
  self.offset = -1
  self.ctype = ''
  self.items = {}
  return self
end

function cmdline:get_trigger_characters() return { ' ', '.', '#', '-' } end

function cmdline:get_completions(context, callback)
  local cursor_before_line = context.line:sub(0, context.cursor[2])

  local offset = 0
  local ctype = ''
  local items = {}
  local kind
  local isIncomplete = false
  for _, def in ipairs(definitions) do
    local s, e = vim.regex(def.regex):match_str(cursor_before_line)
    if s and e then
      offset = s
      ctype = def.ctype
      items = def.exec(
        vim.tbl_deep_extend('keep', {}, regex.DEFAULT_OPTION),
        string.sub(cursor_before_line, s + 1),
        cursor_before_line,
        false -- TODO:
      )
      kind = def.kind
      isIncomplete = def.isIncomplete
      if not (#items == 0 and def.fallback) then break end
    end
  end

  local labels = {}
  for _, item in ipairs(items) do
    item.kind = kind
    labels[item.label] = true
  end

  -- `vim.fn.getcompletion` does not handle fuzzy matches. So, we must return all items, including items that were matched in the previous input.
  local should_merge_previous_items = false
  if #cursor_before_line > #self.before_line then
    should_merge_previous_items = string.find(cursor_before_line, self.before_line, 1, true) == 1
  elseif #cursor_before_line < #self.before_line then
    should_merge_previous_items = string.find(self.before_line, cursor_before_line, 1, true) == 1
  end

  if should_merge_previous_items and self.offset == offset and self.ctype == ctype then
    for _, item in ipairs(self.items) do
      if not labels[item.label] then table.insert(items, item) end
    end
  end
  self.before_line = cursor_before_line
  self.offset = offset
  self.ctype = ctype
  self.items = items

  callback({
    is_incomplete_backward = true,
    is_incomplete_forward = isIncomplete,
    items = items,
  })
end

return cmdline
