---Allows chaining of async operations without callback hell
---
---```lua
---local async = require('blink.cmp.lib.async')
---
---local task = async.task.new(function(resolve, reject)
---  vim.uv.fs_readdir(vim.loop.cwd(), function(err, entries)
---    if err ~= nil then return reject(err) end
---    resolve(entries)
---  end)
---end)
---
---task
---  :map(function(entries)
---    return vim.tbl_map(function(entry) return entry.name end, entries)
---  end)
---  :catch(function(err) vim.print('failed to read directory: ' .. err) end)
---```
---
---Note that lua language server cannot infer the type of the task from the `resolve` call.
---
---You may need to add the type annotation explicitly via an `@return` annotation on a function returning the task, or via the `@cast/@type` annotations on the task variable.
--- @class blink.cmp.Task<T>: { status: blink.cmp.TaskStatus, result: T | nil, error: any | nil, _completion_cbs: fun(result: T)[], _failure_cbs: fun(err: any)[], _cancel_cbs: fun()[], _cancel: fun()?, __task: true }
local task = {
  __task = true,
}

---@enum blink.cmp.TaskStatus
local STATUS = {
  RUNNING = 1,
  COMPLETED = 2,
  FAILED = 3,
  CANCELLED = 4,
}

--- @generic T
--- @param fn fun(resolve: fun(result?: T), reject: fun(err: any)): fun()?
--- @return blink.cmp.Task<T>
function task.new(fn)
  local self = setmetatable({}, { __index = task })
  self.status = STATUS.RUNNING
  self._completion_cbs = {}
  self._failure_cbs = {}
  self._cancel_cbs = {}
  self.result = nil
  self.error = nil

  local resolve = function(result)
    if self.status ~= STATUS.RUNNING then return end

    self.status = STATUS.COMPLETED
    self.result = result

    for _, cb in ipairs(self._completion_cbs) do
      cb(result)
    end
  end

  local reject = function(err)
    if self.status ~= STATUS.RUNNING then return end

    self.status = STATUS.FAILED
    self.error = err

    for _, cb in ipairs(self._failure_cbs) do
      cb(err)
    end
  end

  -- run task callback, if it returns a function, use it for cancellation

  local success, cancel_fn_or_err = pcall(function() return fn(resolve, reject) end)

  if not success then
    reject(cancel_fn_or_err)
  elseif type(cancel_fn_or_err) == 'function' then
    self._cancel = cancel_fn_or_err
  end

  return self
end

--- @param self blink.cmp.Task<any>
function task:cancel()
  if self.status ~= STATUS.RUNNING then return end
  self.status = STATUS.CANCELLED

  if self._cancel ~= nil then self._cancel() end
  for _, cb in ipairs(self._cancel_cbs) do
    cb()
  end
end

--- mappings

--- Creates a new task by applying a function to the result of the current task
--- This only applies if the input task completed successfully.
--- @generic T
--- @generic U
--- @param self blink.cmp.Task<T>
--- @param fn fun(result: T): blink.cmp.Task<U> | U | nil
--- @return blink.cmp.Task<U>
function task:map(fn)
  local chained_task
  chained_task = task.new(function(resolve, reject)
    self:on_completion(function(result)
      local success, mapped_result = pcall(fn, result)
      if not success then
        reject(mapped_result)
        return
      end

      if type(mapped_result) == 'table' and mapped_result.__task then
        mapped_result:on_completion(resolve)
        mapped_result:on_failure(reject)
        mapped_result:on_cancel(function() chained_task:cancel() end)
        return
      end
      resolve(mapped_result)
    end)
    self:on_failure(reject)
    self:on_cancel(function() chained_task:cancel() end)
    return function() self:cancel() end
  end)
  return chained_task
end

--- Creates a new task by applying a function to the error of the current task.
--- This only applies if the input task errored.
--- @generic T
--- @generic U
--- @param fn fun(self: blink.cmp.Task<T>, err: any): blink.cmp.Task<U> | U | nil
--- @return blink.cmp.Task<T | U>
function task:catch(fn)
  local chained_task
  chained_task = task.new(function(resolve, reject)
    self:on_completion(resolve)
    self:on_failure(function(err)
      local success, mapped_err = pcall(fn, err)
      if not success then
        reject(mapped_err)
        return
      end

      if type(mapped_err) == 'table' and mapped_err.__task then
        mapped_err:on_completion(resolve)
        mapped_err:on_failure(reject)
        mapped_err:on_cancel(function() chained_task:cancel() end)
        return
      end
      resolve(mapped_err)
    end)
    self:on_cancel(function() chained_task:cancel() end)
    return function() chained_task:cancel() end
  end)
  return chained_task
end

--- @generic T
--- @param self blink.cmp.Task<T>
--- @return blink.cmp.Task<T>
function task:schedule()
  return self:map(function(value)
    return task.new(function(resolve)
      vim.schedule(function() resolve(value) end)
    end)
  end)
end

--- @generic T
--- @param self blink.cmp.Task<T>
--- @param ms number
--- @return blink.cmp.Task<T>
function task:timeout(ms)
  return task.new(function(resolve, reject)
    vim.defer_fn(function() reject() end, ms)
    self:map(resolve):catch(reject)
  end)
end

--- events

--- @generic T
--- @param self blink.cmp.Task<T>
--- @param cb fun(result: T)
--- @return blink.cmp.Task<T>
function task:on_completion(cb)
  if self.status == STATUS.COMPLETED then
    cb(self.result)
  elseif self.status == STATUS.RUNNING then
    table.insert(self._completion_cbs, cb)
  end
  return self
end

--- @generic T
--- @param self blink.cmp.Task<T>
--- @param cb fun(err: any)
--- @return blink.cmp.Task<T>
function task:on_failure(cb)
  if self.status == STATUS.FAILED then
    cb(self.error)
  elseif self.status == STATUS.RUNNING then
    table.insert(self._failure_cbs, cb)
  end
  return self
end

--- @generic T
--- @param self blink.cmp.Task<T>
--- @param cb fun()
--- @return blink.cmp.Task<T>
function task:on_cancel(cb)
  if self.status == STATUS.CANCELLED then
    cb()
  elseif self.status == STATUS.RUNNING then
    table.insert(self._cancel_cbs, cb)
  end
  return self
end

--- utils

--- Awaits all tasks in the given array of tasks.
--- If any of the tasks fail, the returned task will fail.
--- If any of the tasks are cancelled, the returned task will be cancelled.
--- If all tasks are completed, the returned task will resolve with an array of results.
--- @generic T
--- @param tasks blink.cmp.Task<T>[]
--- @return blink.cmp.Task<T[]>
function task.all(tasks)
  if #tasks == 0 then
    return task.new(function(resolve) resolve({}) end)
  end

  local all_task
  all_task = task.new(function(resolve, reject)
    local results = {}
    local has_resolved = {}

    local function resolve_if_completed()
      -- we can't check #results directly because a table like
      -- { [2] = { ... } } has a length of 2
      for i = 1, #tasks do
        if has_resolved[i] == nil then return end
      end
      resolve(results)
    end

    for idx, task in ipairs(tasks) do
      -- task completed, add result to results table, and resolve if all tasks are done
      task:on_completion(function(result)
        results[idx] = result
        has_resolved[idx] = true
        resolve_if_completed()
      end)

      -- one task failed, cancel all other tasks
      task:on_failure(function(err)
        reject(err)
        for _, other_task in ipairs(tasks) do
          other_task:cancel()
        end
      end)

      -- one task was cancelled, cancel all other tasks
      task:on_cancel(function()
        for _, sub_task in ipairs(tasks) do
          sub_task:cancel()
        end
        if all_task == nil then
          vim.schedule(function() all_task:cancel() end)
        else
          all_task:cancel()
        end
      end)
    end

    -- root task cancelled, cancel all inner tasks
    return function()
      for _, other_task in ipairs(tasks) do
        other_task:cancel()
      end
    end
  end)
  return all_task
end

--- Creates a task that resolves with `nil`.
--- @return blink.cmp.Task<nil>
function task.empty()
  return task.new(function(resolve) resolve(nil) end)
end

--- Creates a task that resolves with the given value.
--- @generic T
--- @param val T
--- @return blink.cmp.Task<T>
function task.identity(val)
  return task.new(function(resolve) resolve(val) end)
end

return { task = task, STATUS = STATUS }
