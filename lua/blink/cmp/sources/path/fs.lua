local async = require('blink.cmp.lib.async')
local uv = vim.uv
local fs = {}

--- Scans a directory asynchronously in chunks, calling a provided callback for each directory entry.
--- The task resolves once all entries have been processed.
--- @param path string
--- @param callback fun(entries: table[]) Callback function called with an array (chunk) of directory entries
--- @param chunk_size? integer Optional number of entries to read per chunk (default 200)
--- @return blink.cmp.Task
function fs.scan_dir_async(path, callback, chunk_size)
  chunk_size = chunk_size or 200

  return async.task.new(function(resolve, reject)
    uv.fs_opendir(path, function(err, handle)
      if err or not handle then return reject(err) end

      local function read_dir()
        uv.fs_readdir(handle, function(err, entries)
          if err or not entries then
            uv.fs_closedir(handle, function() end)
            return reject(err)
          end

          callback(entries)

          if #entries == chunk_size then
            read_dir()
          else
            uv.fs_closedir(handle, function() end)
            resolve(true)
          end
        end)
      end
      read_dir()
    end, chunk_size)
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
