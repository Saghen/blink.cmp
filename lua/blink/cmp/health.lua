local health = {}
local download = require('blink.cmp.fuzzy.download')

health.check = function()
  vim.health.start('blink.cmp healthcheck')

  local required_executables = { 'curl', 'git' }
  for _, executable in ipairs(required_executables) do
    if vim.fn.executable(executable) == 0 then
      vim.health.error(executable .. ' is not installed')
    else
      vim.health.ok(executable .. ' is installed')
    end
  end

  -- check if os is supported
  local system_triple = download.get_system_triple_sync()
  if system_triple then
    vim.health.ok('Your system is supported by pre-built binaries (' .. system_triple .. ')')
  else
    vim.health.warn(
      'Your system is not supported by pre-built binaries. You must run cargo build --release via your package manager with rust nightly. See the README for more info.'
    )
  end

  if
    vim.uv.fs_stat(download.lib_path)
    or vim.uv.fs_stat(string.gsub(download.lib_path, 'libblink_cmp_fuzzy', 'blink_cmp_fuzzy'))
  then
    vim.health.ok('blink_cmp_fuzzy lib is downloaded/built')
  else
    vim.health.warn('blink_cmp_fuzzy lib is not downloaded/built')
  end
end
return health
