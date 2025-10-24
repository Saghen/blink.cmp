local async = require('blink.cmp.lib.async')
local utils = require('blink.cmp.lib.utils')

local function get_lib_extension()
  if jit.os:lower() == 'mac' or jit.os:lower() == 'osx' then return '.dylib' end
  if jit.os:lower() == 'windows' then return '.dll' end
  return '.so'
end

local current_file_dir = debug.getinfo(1).source:match('@?(.*/)')
local current_file_dir_parts = vim.split(current_file_dir, '/')
local root_dir = table.concat(utils.slice(current_file_dir_parts, 1, #current_file_dir_parts - 6), '/')
local lib_folder = root_dir .. '/target/release'
local lib_filename = 'libblink_cmp_fuzzy' .. get_lib_extension()
local lib_path = lib_folder .. '/' .. lib_filename

local files = {
  get_lib_extension = get_lib_extension,
  root_dir = root_dir,
  lib_folder = lib_folder,
  lib_filename = lib_filename,
  lib_path = lib_path,
}

--- Filesystem helpers ---

--- @param path string
--- @return blink.cmp.Task
function files.read_file(path)
  return async.task.new(function(resolve, reject)
    vim.uv.fs_open(path, 'r', 438, function(open_err, fd)
      if open_err or fd == nil then return reject(open_err or 'Unknown error') end
      vim.uv.fs_read(fd, 1024, 0, function(read_err, data)
        vim.uv.fs_close(fd, function() end)
        if read_err or data == nil then return reject(read_err or 'Unknown error') end
        return resolve(data)
      end)
    end)
  end)
end

--- @param path string
--- @param data string
--- @return blink.cmp.Task
function files.write_file(path, data)
  return async.task.new(function(resolve, reject)
    vim.uv.fs_open(path, 'w', 438, function(open_err, fd)
      if open_err or fd == nil then return reject(open_err or 'Unknown error') end
      vim.uv.fs_write(fd, data, 0, function(write_err)
        vim.uv.fs_close(fd, function() end)
        if write_err then return reject(write_err) end
        return resolve()
      end)
    end)
  end)
end

--- @param path string
--- @return blink.cmp.Task
function files.exists(path)
  return async.task.new(function(resolve)
    vim.uv.fs_stat(path, function(err) resolve(not err) end)
  end)
end

--- @param path string
--- @return blink.cmp.Task
function files.stat(path)
  return async.task.new(function(resolve, reject)
    vim.uv.fs_stat(path, function(err, stat)
      if err then return reject(err) end
      resolve(stat)
    end)
  end)
end

--- @param path string
--- @return blink.cmp.Task
function files.create_dir(path)
  return files
    .stat(path)
    :map(function(stat) return stat.type == 'directory' end)
    :catch(function() return false end)
    :map(function(exists)
      if exists then return end

      return async.task.new(function(resolve, reject)
        vim.uv.fs_mkdir(path, 511, function(err)
          if err then return reject(err) end
          resolve()
        end)
      end)
    end)
end

--- Renames a file
--- @param old_path string
--- @param new_path string
function files.rename(old_path, new_path)
  return async.task.new(function(resolve, reject)
    vim.uv.fs_rename(old_path, new_path, function(err)
      if err then return reject(err) end
      resolve()
    end)
  end)
end

return files
