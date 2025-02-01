local Kind = require('blink.cmp.types').CompletionItemKind

---@class blink.cmp.OmniOpts
---@field disable_omnifuncs string[]

---@class blink.cmp.OmniSource : blink.cmp.Source
---@field opts blink.cmp.OmniOpts
local omni = {}

---@class blink.cmp.CompleteFuncItem
---@field word string
---@field abbr? string
---@field menu? string
---@field info? string
---@field kind? string
---@field icase? integer
---@field equal? integer
---@field dup? integer
---@field empty? integer
---@field user_data? any

---@alias blink.cmp.CompleteFuncWords (string | blink.cmp.CompleteFuncItem)[]

---@param _ string
---@param config blink.cmp.SourceProviderConfig
---@return blink.cmp.Source
function omni.new(_, config)
  local self = setmetatable({}, { __index = omni })

  local opts = vim.tbl_deep_extend('force', {
    disable_omnifuncs = { 'v:lua.vim.lsp.omnifunc' },
  }, config.opts or {})

  require('blink.cmp.config.utils').validate('sources.providers.omni', {
    disable_omnifuncs = { opts.disable_omnifuncs, 'table' },
  }, opts)

  self.opts = opts

  return self
end

function omni:enabled()
  return vim.bo.omnifunc ~= ''
    and vim.api.nvim_get_mode().mode == 'i'
    and not vim.tbl_contains(self.opts.disable_omnifuncs, vim.bo.omnifunc)
end

---Invoke an omnifunc handling `v:lua.*`
---@return (table<{ words: blink.cmp.CompleteFuncWords, refresh: string }> | blink.cmp.CompleteFuncWords) | integer
---@overload fun(func: string, findstart: 1, base: ''): integer
---@overload fun(func: string, findstart: 0, base: string): table<{ words: blink.cmp.CompleteFuncWords, refresh: string }> | blink.cmp.CompleteFuncWords
local function invoke_omnifunc(func, findstart, base)
  local prev_pos = vim.api.nvim_win_get_cursor(0)

  local _, result = pcall(function()
    local args = { findstart, base }
    local match = func:match('^v:lua%.(.+)')

    if match then
      return vim.fn.luaeval(string.format('%s(_A[1], _A[2], _A[3])', match), args)
    else
      return vim.api.nvim_call_function(func, args)
    end
  end)

  local next_pos = vim.api.nvim_win_get_cursor(0)
  if prev_pos[1] ~= next_pos[1] or prev_pos[2] ~= next_pos[2] then vim.api.nvim_win_set_cursor(0, prev_pos) end

  return result
end

-- Map the defined `complete-items` 'kind's to blink kinds
local OMNI_TO_BLINK_KIND = {
  v = Kind.Variable, -- variable
  f = Kind.Function, -- function/method
  m = Kind.Field, -- struct/class member
  t = Kind.TypeParameter, -- typedef
  d = Kind.Constant, -- #define/macro
}

---@param context blink.cmp.Context
---@param resolve fun(response?: blink.cmp.CompletionResponse)
---@return nil
function omni:get_completions(context, resolve)
  -- for info on omnifunc see `:h 'omnifunc'`, and `:h complete-functions`

  -- get the starting column from which completion will start
  local start_col = invoke_omnifunc(vim.bo.omnifunc, 1, '')

  if type(start_col) ~= 'number' then
    resolve()
    return nil
  end

  local cur_line, cur_col = unpack(context.cursor)

  -- TODO: differentiate between staying in (-2) vs leaving (-3) completion mode?
  if start_col == -2 or start_col == -3 then
    resolve()
    return nil
  elseif start_col < 0 or start_col > cur_col then
    start_col = cur_col
  end

  -- for info on omnifunc results see `:h complete-items`
  -- get the actual omnifunc completion results
  local cmp_results = invoke_omnifunc(vim.bo.omnifunc, 0, string.sub(context.line, start_col + 1, cur_col))
  cmp_results = cmp_results['words'] or cmp_results
  ---@cast cmp_results blink.cmp.CompleteFuncWords

  local range = {
    ['start'] = {
      line = cur_line - 1,
      character = start_col,
    },
    ['end'] = {
      line = cur_line - 1,
      character = cur_col,
    },
  }

  local items = {} ---@type blink.cmp.CompletionItem[]
  for _, cmp in ipairs(cmp_results) do
    local item ---@type blink.cmp.CompletionItem

    if type(cmp) == 'string' then
      item = {
        label = cmp,
        textEdit = {
          range = range,
          newText = cmp,
        },
      }
    else
      item = {
        label = cmp.abbr or cmp.word,
        textEdit = {
          range = range,
          newText = cmp.word,
        },
        labelDetails = {
          description = cmp.menu,
        },
      }

      -- if possible, prefer blink's 'kind' to remove redundancy
      local blink_kind = OMNI_TO_BLINK_KIND[cmp.kind]
      if blink_kind ~= nil then
        item.kind = blink_kind
      else
        item.labelDetails.detail = cmp.kind
      end

      if cmp.info ~= nil and #cmp.info > 0 then
        item.documentation = {
          value = cmp.info,
          kind = 'plaintext',
        }
      end
    end

    table.insert(items, item)
  end

  resolve({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })

  return nil
end

return omni
