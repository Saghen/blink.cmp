---@class blink.cmp.OmniOpts
---@field disable_omnifuncs string[]

---@class blink.cmp.Source
---@field opts blink.cmp.OmniOpts
local omni = {}

---@class blink.cmp.OmniOpts

---@class blink.cmp.CompleteFuncItem
---@field word string
---@field abbr string?
---@field menu string?
---@field info string?
---@field kind string?
---@field icase integer?
---@field equal integer?
---@field dup integer?
---@field empty integer?
---@field user_data any?

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
---@param func string
---@param findstart integer
---@param base string
---@return integer|(string|blink.cmp.CompleteFuncItem)[]
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
  ---@cast cmp_results (string|blink.cmp.CompleteFuncItem)[]

  cmp_results = cmp_results['words'] or cmp_results

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
    -- TODO: does this need a blink specfic kind?
    if type(cmp) == 'string' then
      table.insert(items, {
        label = cmp,
        textEdit = {
          range = range,
          newText = cmp,
        },
      })
    else
      table.insert(items, {
        label = cmp.abbr or cmp.word,
        textEdit = {
          range = range,
          newText = cmp.word,
        },
        labelDetails = {
          detail = cmp.kind,
          description = cmp.menu,
        },
      })
    end
  end

  resolve({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })

  return nil
end

return omni
