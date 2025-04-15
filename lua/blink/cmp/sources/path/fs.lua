local async = require('blink.cmp.lib.async')
local uv = vim.uv
local fs = {}

--- Scans a directory asynchronously in a loop until
--- it finds all entries
--- @param path string
--- @return blink.cmp.Task
function fs.scan_dir_async(path)
  local max_entries = 200
  return async.task.new(function(resolve, reject)
    uv.fs_opendir(path, function(err, handle)
      if err ~= nil or handle == nil then return reject(err) end

      local all_entries = {}

      local function read_dir()
        uv.fs_readdir(handle, function(err, entries)
          if err ~= nil or entries == nil then
            uv.fs_closedir(handle, function() end)
            return reject(err)
          end

          vim.list_extend(all_entries, entries)
          if #entries == max_entries then
            read_dir()
          else
            uv.fs_closedir(handle, function() end)
            resolve(all_entries)
          end
        end)
      end
      read_dir()
    end, max_entries)
  end)
end

--- @param entries { name: string, type: string }[]
--- @return blink.cmp.Task
function fs.fs_stat_all(cwd, entries)
  local tasks = {}
  for _, entry in ipairs(entries) do
    table.insert(
      tasks,
      async.task.new(function(resolve)
        uv.fs_stat(cwd .. '/' .. entry.name, function(err, stat)
          if err then return resolve(nil) end
          resolve({ name = entry.name, type = entry.type, stat = stat })
        end)
      end)
    )
  end
  return async.task.all(tasks):map(function(entries)
    return vim.tbl_filter(function(entry) return entry ~= nil end, entries)
  end)
end

--- @param path string
--- @param byte_limit number
--- @return blink.cmp.Task
function fs.read_file(path, byte_limit)
  return async.task.new(function(resolve, reject)
    uv.fs_open(path, 'r', 438, function(open_err, fd)
      if open_err or fd == nil then return reject(open_err) end
      uv.fs_read(fd, byte_limit, 0, function(read_err, data)
        uv.fs_close(fd, function() end)
        if read_err or data == nil then return reject(read_err) end
        resolve(data)
      end)
    end)
  end)
end

return fs
