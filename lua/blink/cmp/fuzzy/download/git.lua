local async = require('blink.cmp.lib.async')
local files = require('blink.cmp.fuzzy.download.files')
local git = {}

function git.get_version()
  return async.task.all({ git.get_tag(), git.get_sha() }):map(
    function(results)
      return {
        tag = results[1],
        sha = results[2],
      }
    end
  )
end

function git.get_tag()
  return async.task.new(function(resolve, reject)
    -- If repo_dir is nil, no git repository is found, similar to `out.code == 128`
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

function git.get_sha()
  return async.task.new(function(resolve, reject)
    -- If repo_dir is nil, no git repository is found, similar to `out.code == 128`
    local repo_dir = vim.fs.root(files.root_dir, '.git')
    if not repo_dir then resolve() end

    vim.system({
      'git',
      '--git-dir',
      vim.fs.joinpath(repo_dir, '.git'),
      '--work-tree',
      repo_dir,
      'rev-parse',
      'HEAD',
    }, { cwd = files.root_dir }, function(out)
      if out.code == 128 then return resolve() end
      if out.code ~= 0 then
        return reject('While getting git sha, git exited with code ' .. out.code .. ': ' .. out.stderr)
      end

      local sha = vim.split(out.stdout, '\n')[1]
      return resolve(sha)
    end)
  end)
end

return git
