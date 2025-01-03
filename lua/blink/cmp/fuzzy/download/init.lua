local download_config = require('blink.cmp.config').fuzzy.prebuilt_binaries
local async = require('blink.cmp.lib.async')
local git = require('blink.cmp.fuzzy.download.git')
local files = require('blink.cmp.fuzzy.download.files')
local system = require('blink.cmp.fuzzy.download.system')

local download = {}

--- @param callback fun(err: string | nil)
function download.ensure_downloaded(callback)
  callback = vim.schedule_wrap(callback)

  if not download_config.download then return callback() end

  async.task
    .await_all({ git.get_version(), files.get_version() })
    :map(function(results)
      return {
        git = results[1],
        current = results[2],
      }
    end)
    :map(function(version)
      local target_git_tag = download_config.force_version or version.git.tag

      -- not built locally, not on a git tag, error
      assert(
        version.current.sha ~= nil or target_git_tag ~= nil,
        "\nDetected an out of date or missing fuzzy matching library. Can't download from github due to not being on a git tag and no `fuzzy.prebuilt_binaries.force_version` is set."
          .. '\nEither run `cargo build --release` via your package manager, switch to a git tag, or set `fuzzy.prebuilt_binaries.force_version` in config. '
          .. 'See the docs for more info.'
      )

      -- built locally, ignore
      if
        not download_config.force_version
        and (
          version.current.sha == version.git.sha
          or version.current.sha ~= nil and download_config.ignore_version_mismatch
        )
      then
        return
      end

      -- built locally but outdated and not on a git tag, error
      if
        not download_config.force_version
        and version.current.sha ~= nil
        and version.current.sha ~= version.git.sha
      then
        assert(
          target_git_tag or download_config.ignore_version_mismatch,
          "\nFound an outdated version of the fuzzy matching library, but can't download from github due to not being on a git tag. "
            .. '\n!! FOR DEVELOPERS !!, set `fuzzy.prebuilt_binaries.ignore_version_mismatch = true` in config. '
            .. '\n!! FOR USERS !!, either run `cargo build --release` via your package manager, switch to a git tag, or set `fuzzy.prebuilt_binaries.force_version` in config. '
            .. 'See the docs for more info.'
        )
        if not download_config.ignore_version_mismatch then
          vim.schedule(
            function()
              vim.notify(
                '[blink.cmp]: Found an outdated version of the fuzzy matching library built locally',
                vim.log.levels.INFO,
                { title = 'blink.cmp' }
              )
            end
          )
        end
      end

      -- already downloaded and the correct version, just verify the checksum, and re-download if checksum fails
      if version.current.tag ~= nil and version.current.tag == target_git_tag then
        return files.verify_checksum():catch(function(err)
          vim.schedule(function()
            vim.notify(err, vim.log.levels.WARN, { title = 'blink.cmp' })
            vim.notify(
              '[blink.cmp]: Pre-built binary failed checksum verification, re-downloading',
              vim.log.levels.WARN,
              { title = 'blink.cmp' }
            )
          end)
          return download.download(target_git_tag)
        end)
      end

      -- unknown state
      if not target_git_tag then error('Unknown error while getting pre-built binary. Consider re-installing') end

      -- download as per usual
      vim.schedule(
        function() vim.notify('[blink.cmp]: Downloading pre-built binary', vim.log.levels.INFO, { title = 'blink.cmp' }) end
      )
      return download.download(target_git_tag)
    end)
    :map(function() callback() end)
    :catch(function(err) callback(err) end)
end

function download.download(version)
  -- NOTE: we set the version to 'v0.0.0' to avoid a failure causing the pre-built binary being marked as locally built
  return files
    .set_version('v0.0.0')
    :map(function() return download.from_github(version) end)
    :map(function() return files.verify_checksum() end)
    :map(function() return files.set_version(version) end)
end

--- @param tag string
--- @return blink.cmp.Task
function download.from_github(tag)
  return system.get_triple():map(function(system_triple)
    if not system_triple then
      return error(
        'Your system is not supported by pre-built binaries. You must run cargo build --release via your package manager with rust nightly. See the README for more info.'
      )
    end

    local base_url = 'https://github.com/saghen/blink.cmp/releases/download/' .. tag .. '/'
    local library_url = base_url .. system_triple .. files.get_lib_extension()
    local checksum_url = base_url .. system_triple .. files.get_lib_extension() .. '.sha256'

    return async
      .task
      .await_all({
        download.download_file(library_url, files.lib_filename .. '.tmp'),
        download.download_file(checksum_url, files.checksum_filename),
      })
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
--- @return blink.cmp.Task
function download.download_file(url, filename)
  return async.task.new(function(resolve, reject)
    local args = { 'curl' }
    vim.list_extend(args, download_config.extra_curl_args)
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
