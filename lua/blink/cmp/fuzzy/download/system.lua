local download_config = require('blink.cmp.config').fuzzy.prebuilt_binaries
local async = require('blink.cmp.lib.async')
local system = {}

system.triples = {
  mac = {
    arm = 'aarch64-apple-darwin',
    x64 = 'x86_64-apple-darwin',
  },
  windows = {
    x64 = 'x86_64-pc-windows-msvc',
  },
  linux = {
    android = 'aarch64-linux-android',
    arm = function(libc) return 'aarch64-unknown-linux-' .. libc end,
    x64 = function(libc) return 'x86_64-unknown-linux-' .. libc end,
  },
}

--- Gets the operating system and architecture of the current system
--- @return string, string
function system.get_info()
  local os = jit.os:lower()
  if os == 'osx' then os = 'mac' end
  local arch = jit.arch:lower():match('arm') and 'arm' or jit.arch:lower():match('x64') and 'x64' or nil
  return os, arch
end

--- Synchronously gets the system target triple from `cc -dumpmachine`
--- I.e. { 'x86_64', 'pc', 'linux', 'gnu' }
--- @return string[] | nil
function system.get_target_triple()
  local success, process = pcall(function()
    return vim.system({'cc', '-dumpmachine'}, { text = true }):wait()
  end)
  if not success or process.code ~= 0 then
    vim.notify(
      "Failed to determine system target triple using `cc -dumpmachine`. " ..
      "Try setting `fuzzy.prebuilt_binaries.force_system_triple`",
      vim.log.levels.ERROR,
      { title = 'blink.cmp' }
    )
    return nil
  end

  -- strip whitespace
  local stdout = process.stdout:gsub('%s+', '')
  return vim.fn.split(stdout, '-')
end

--- Gets the system triple for the current system
--- I.e. `x86_64-unknown-linux-gnu` or `aarch64-apple-darwin`
--- @return blink.cmp.Task
function system.get_triple()
  return async.task.new(function(resolve)
    if download_config.force_system_triple then return resolve(download_config.force_system_triple) end

    local os, arch = system.get_info()
    local triples = system.triples[os]

    if os == 'linux' then
      if vim.fn.has('android') == 1 then return resolve(triples.android) end

      local target_triple = system.get_target_triple()
      if target_triple then
        local libc = target_triple[3]
        local triple = triples[arch]
        return resolve(triple and type(triple) == 'function' and triple(libc) or triple)
      end

      vim.uv.fs_stat('/etc/alpine-release', function(err, is_alpine)
        local libc = (not err and is_alpine) and 'musl' or 'gnu'
        local triple = triples[arch]
        return resolve(triple and type(triple) == 'function' and triple(libc) or triple)
      end)
    else
      return resolve(triples[arch])
    end
  end)
end

--- Same as `system.get_triple` but synchronous
--- @see system.get_triple
--- @return string | nil
function system.get_triple_sync()
  if download_config.force_system_triple then return download_config.force_system_triple end

  local os, arch = system.get_info()
  local triples = system.triples[os]

  if os == 'linux' then
    if vim.fn.has('android') == 1 then return triples.android end

    local success, is_alpine = pcall(vim.uv.fs_stat, '/etc/alpine-release')
    local libc = (success and is_alpine) and 'musl' or 'gnu'
    local triple = triples[arch]
    return triple and type(triple) == 'function' and triple(libc) or triple
  else
    return triples[arch]
  end
end

return system
