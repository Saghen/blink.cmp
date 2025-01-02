local NAME_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\|]\\)'
local PATH_REGEX =
  assert(vim.regex(([[\%(\%(/PAT*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*/\zePAT*$]]):gsub('PAT', NAME_REGEX)))

return {
  --- Lua pattern for matching file names
  NAME = '[^/\\:*?<>\'"`|]',
  --- Vim regex for matching file paths
  PATH = PATH_REGEX,
}
