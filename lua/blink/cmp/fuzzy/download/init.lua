local download_config = require('blink.cmp.config').fuzzy.prebuilt_binaries
local async = require('blink.cmp.lib.async')
local files = require('blink.cmp.fuzzy.download.files')
local system = require('blink.cmp.fuzzy.download.system')

local download = {}

--- @param callback fun(err: string | nil)
function download.ensure_downloaded(callback)
  callback = vim.schedule_wrap(callback)

  if not download_config.download then return callback() end

  async.task
    .await_all({ download.get_git_tag(), files.get_downloaded_version(), files.is_downloaded() })
    :map(
      function(results)
        return {
          git_version = results[1],
          version = results[2],
          is_downloaded = results[3],
        }
      end
    )
    :map(function(state)
      local target_version = download_config.force_version or state.git_version

      -- not built locally, not a git tag, error
      if not state.is_downloaded and not target_version then
        return callback(
          "Can't download from github due to not being on a git tag and no fuzzy.prebuilt_binaries.force_version set, but found no built version of the library. "
            .. 'Either run `cargo build --release` via your package manager, switch to a git tag, or set `fuzzy.prebuilt_binaries.force_version` in config. '
            .. 'See the README for more info.'
        )
      end

      -- built locally, ignore
      if state.is_downloaded and (state.version == nil) then return end

      -- already downloaded and the correct version, just verify the checksum, and re-download if checksum fails
      if state.version == target_version and state.is_downloaded then
        return files.verify_checksum():catch(function(err)
          vim.schedule(function()
            vim.notify(err, vim.log.levels.WARN)
            vim.notify('Pre-built binary failed checksum verification, re-downloading', vim.log.levels.WARN)
          end)
          return download.download(target_version)
        end)
      end

      -- unknown state
      if not target_version then error('Unknown error while getting pre-built binary. Consider re-installing') end

      -- download as per usual
      vim.schedule(function() vim.notify('Downloading pre-built binary', vim.log.levels.INFO) end)
      return download.download(target_version)
    end)
    :map(function() callback() end)
    :catch(function(err) callback(err) end)
end

function download.download(version)
  -- NOTE: we set the version to 'v0.0.0' to avoid a failure causing the pre-built binary being marked as locally built
  return files
    .set_downloaded_version('v0.0.0')
    :map(function() return download.from_github(version) end)
    :map(function() return files.verify_checksum() end)
    :map(function() return files.set_downloaded_version(version) end)
end

function download.get_git_tag()
  return async.task.new(function(resolve, reject)
    -- If repo_dir is nil, no git reposiory is found, similar to `out.code == 128`
    local repo_dir = vim.fs.root(files.root_dir, '.git')
    if not repo_dir then resolve() end

    vim.system({
      'git',
      '--git-dir',
      vim.fs.joinpath(repo_dir, '.git'),
      '--work-tree',
      repo_dir,
      'describe',
      '--tags',
      '--exact-match',
    }, { cwd = files.root_dir }, function(out)
      if out.code == 128 then return resolve() end
      if out.code ~= 0 then
        return reject('While getting git tag, git exited with code ' .. out.code .. ': ' .. out.stderr)
      end

      local lines = vim.split(out.stdout, '\n')
      if not lines[1] then return reject('Expected atleast 1 line of output from git describe') end
      return resolve(lines[1])
    end)
  end)
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

    return async.task.await_all({
      download.download_file(library_url, files.lib_filename),
      download.download_file(checksum_url, files.checksum_filename),
    })
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
