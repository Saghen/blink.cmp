--- Allows chaining of async operations without callback hell
---
--- @class blink.cmp.Task
--- @field status blink.cmp.TaskStatus
--- @field result any | nil
--- @field error any | nil
--- @field new fun(fn: fun(resolve: fun(result: any), reject: fun(err: any))): blink.cmp.Task
---
--- @field cancel fun(self: blink.cmp.Task)
--- @field map fun(self: blink.cmp.Task, fn: fun(result: any): blink.cmp.Task | any): blink.cmp.Task
--- @field catch fun(self: blink.cmp.Task, fn: fun(err: any): blink.cmp.Task | any): blink.cmp.Task
--- @field schedule fun(self: blink.cmp.Task): blink.cmp.Task
--- @field timeout fun(self: blink.cmp.Task, ms: number): blink.cmp.Task
---
--- @field on_completion fun(self: blink.cmp.Task, cb: fun(result: any))
--- @field on_failure fun(self: blink.cmp.Task, cb: fun(err: any))
--- @field on_cancel fun(self: blink.cmp.Task, cb: fun())
--- @field _completion_cbs function[]
--- @field _failure_cbs function[]
--- @field _cancel_cbs function[]
--- @field _cancel? fun()
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

  local success, cancel_fn_or_err = pcall(function() return fn(resolve, reject) end)

  if not success then
    reject(cancel_fn_or_err)
  elseif type(cancel_fn_or_err) == 'function' then
    self._cancel = cancel_fn_or_err
  end

  return self
end

function task:cancel()
  if self.status ~= STATUS.RUNNING then return end
  self.status = STATUS.CANCELLED

  if self._cancel ~= nil then self._cancel() end
  for _, cb in ipairs(self._cancel_cbs) do
    cb()
  end
end

--- mappings

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
    return function() chained_task:cancel() end
  end)
  return chained_task
end

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

function task:schedule()
  return self:map(function(value)
    return task.new(function(resolve)
      vim.schedule(function() resolve(value) end)
    end)
  end)
end

function task:timeout(ms)
  return task.new(function(resolve, reject)
    vim.defer_fn(function() reject() end, ms)
    self:map(resolve):catch(reject)
  end)
end

--- events

function task:on_completion(cb)
  if self.status == STATUS.COMPLETED then
    cb(self.result)
  elseif self.status == STATUS.RUNNING then
    table.insert(self._completion_cbs, cb)
  end
  return self
end

function task:on_failure(cb)
  if self.status == STATUS.FAILED then
    cb(self.error)
  elseif self.status == STATUS.RUNNING then
    table.insert(self._failure_cbs, cb)
  end
  return self
end

function task:on_cancel(cb)
  if self.status == STATUS.CANCELLED then
    cb()
  elseif self.status == STATUS.RUNNING then
    table.insert(self._cancel_cbs, cb)
  end
  return self
end

--- utils

function task.await_all(tasks)
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
      task:on_completion(function(result)
        results[idx] = result
        has_resolved[idx] = true
        resolve_if_completed()
      end)
      task:on_failure(function(err)
        reject(err)
        for _, task in ipairs(tasks) do
          task:cancel()
        end
      end)
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
  end)
  return all_task
end

function task.empty()
  return task.new(function(resolve) resolve() end)
end

return { task = task, STATUS = STATUS }
