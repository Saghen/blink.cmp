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
