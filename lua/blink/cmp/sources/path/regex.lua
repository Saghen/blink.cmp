-- somehow less readable than normal regexes

-- we allow spaces in previous path segments, but not in the current one
-- Allowed: ~/example foo/
-- Not allowed: ~/example foo
local NAME_WITH_SPACE_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\|]\\)'
local NAME_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\| ]\\)'
local PATH_REGEX = assert(
  vim.regex(
    ([[\%(\%(/PAT1*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*/\zePAT2*$]])
      :gsub('PAT1', NAME_WITH_SPACE_REGEX)
      :gsub('PAT2', NAME_REGEX)
  )
)

return {
  --- Lua pattern for matching file names
  NAME = '[^/\\:*?<>\'"`|]',
  --- Vim regex for matching file paths
  PATH = PATH_REGEX,
}
