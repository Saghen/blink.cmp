---@param patterns string[]
---@param head boolean
---@return table #regex object
local function create_regex(patterns, head)
  local pattern = [[\%(]] .. table.concat(patterns, [[\|]]) .. [[\)]]
  if head then pattern = '^' .. pattern end
  return vim.regex(pattern)
end

---@class cmp-cmdline.Option
---@field treat_trailing_slash boolean
---@field ignore_cmds string[]
local DEFAULT_OPTION = {
  treat_trailing_slash = true,
  ignore_cmds = { 'Man', '!' },
}

local MODIFIER_REGEX = create_regex({
  [=[\s*abo\%[veleft]\s*]=],
  [=[\s*bel\%[owright]\s*]=],
  [=[\s*bo\%[tright]\s*]=],
  [=[\s*bro\%[wse]\s*]=],
  [=[\s*conf\%[irm]\s*]=],
  [=[\s*hid\%[e]\s*]=],
  [=[\s*keepal\s*t]=],
  [=[\s*keeppa\%[tterns]\s*]=],
  [=[\s*lefta\%[bove]\s*]=],
  [=[\s*loc\%[kmarks]\s*]=],
  [=[\s*nos\%[wapfile]\s*]=],
  [=[\s*rightb\%[elow]\s*]=],
  [=[\s*sil\%[ent]\s*]=],
  [=[\s*tab\s*]=],
  [=[\s*to\%[pleft]\s*]=],
  [=[\s*verb\%[ose]\s*]=],
  [=[\s*vert\%[ical]\s*]=],
}, true)

local COUNT_RANGE_REGEX = create_regex({
  [=[\s*\%(\d\+\|\$\)\%[,\%(\d\+\|\$\)]\s*]=],
  [=[\s*'\%[<,'>]\s*]=],
  [=[\s*\%(\d\+\|\$\)\s*]=],
}, true)

local ONLY_RANGE_REGEX = create_regex({
  [=[^\s*\%(\d\+\|\$\)\%[,\%(\d\+\|\$\)]\s*$]=],
  [=[^\s*'\%[<,'>]\s*$]=],
  [=[^\s*\%(\d\+\|\$\)\s*$]=],
}, true)

local OPTION_NAME_COMPLETION_REGEX = create_regex({
  [=[se\%[tlocal][^=]*$]=],
}, true)

return {
  DEFAULT_OPTION = DEFAULT_OPTION,
  MODIFIER_REGEX = MODIFIER_REGEX,
  COUNT_RANGE_REGEX = COUNT_RANGE_REGEX,
  ONLY_RANGE_REGEX = ONLY_RANGE_REGEX,
  OPTION_NAME_COMPLETION_REGEX = OPTION_NAME_COMPLETION_REGEX,
}
