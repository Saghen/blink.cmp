local async = require('blink.cmp.lib.async')
local files = require('blink.cmp.fuzzy.download.files')
local system = require('blink.cmp.fuzzy.download.system')
local utils = require('blink.cmp.lib.utils')

--- @class blink.cmp.Download
local download = {}

--- @class (exact) blink.cmp.DownloadProxy
--- @field from_env? boolean When downloading a prebuilt binary, use the HTTPS_PROXY environment variable. Defaults to true
--- @field url? string When downloading a prebuilt binary, use this proxy URL. This will ignore the HTTPS_PROXY environment variable

--- @param version string
--- @param system_triple string?
--- @param proxy blink.cmp.DownloadProxy?
--- @param extra_curl_args string[]?
--- @return blink.cmp.Task
function download.from_github(version, system_triple, proxy, extra_curl_args)
  local triple_task = system_triple and async.task.identity(system_triple) or system.get_triple()

  return triple_task:map(function(triple)
    if not triple then
      utils.notify({
        { 'Your system is not supported by ' },
        { ' pre-built binaries ', 'DiagnosticVirtualTextInfo' },
        { '. Try building from source via ' },
        { " build = 'cargo build --release' ", 'DiagnosticVirtualTextInfo' },
        { ' in your lazy.nvim spec and re-installing (requires Rust nightly)' },
      })
      return
    end

    local base_url = 'https://github.com/saghen/blink.cmp/releases/download/' .. version .. '/'
    local library_url = base_url .. triple .. files.get_lib_extension()

    return download
      .download_file(library_url, files.lib_filename .. '.tmp', proxy, extra_curl_args)
      -- Mac caches the library in the kernel, so updating in place causes a crash
      -- We instead write to a temporary file and rename it, as mentioned in:
      -- https://developer.apple.com/documentation/security/updating-mac-software
      :map(
        function()
          return files.rename(
            files.lib_folder .. '/' .. files.lib_filename .. '.tmp',
            files.lib_folder .. '/' .. files.lib_filename
          )
        end
      )
  end)
end

--- @param url string
--- @param filename string
--- @param proxy blink.cmp.DownloadProxy?
--- @param extra_curl_args string[]?
--- @return blink.cmp.Task<nil>
function download.download_file(url, filename, proxy, extra_curl_args)
  return async.task.new(function(resolve, reject)
    local args = { 'curl' }

    -- Use https proxy if available
    if proxy and proxy.url ~= nil then
      vim.list_extend(args, { '--proxy', proxy.url })
    elseif not proxy or proxy.from_env == nil or proxy.from_env then
      local proxy_url = os.getenv('HTTPS_PROXY')
      if proxy_url ~= nil then vim.list_extend(args, { '--proxy', proxy_url }) end
    end

    vim.list_extend(args, extra_curl_args or {})
    vim.list_extend(args, {
      '--fail', -- Fail on 4xx/5xx
      '--location', -- Follow redirects
      '--silent', -- Don't show progress
      '--show-error', -- Show errors, even though we're using --silent
      '--create-dirs',
      '--output',
      files.lib_folder .. '/' .. filename,
      url,
    })

    vim.system(args, {}, function(out)
      if out.code ~= 0 then
        reject('Failed to download ' .. filename .. 'for pre-built binaries: ' .. out.stderr)
      else
        resolve()
      end
    end)
  end)
end

return download
