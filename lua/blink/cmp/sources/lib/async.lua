--- Allows chaining of async operations without callback hell
---
--- @class blink.cmp.Task
--- @field status 1 | 2 | 3 | 4
--- @field result any | nil
--- @field error any | nil
--- @field new fun(fn: fun(resolve: fun(result: any), reject: fun(err: any))): blink.cmp.Task
---
--- @field cancel fun(self: blink.cmp.Task)
--- @field map fun(self: blink.cmp.Task, fn: fun(result: any): blink.cmp.Task | any): blink.cmp.Task
--- @field catch fun(self: blink.cmp.Task, fn: fun(err: any): blink.cmp.Task | any): blink.cmp.Task
---
--- @field on_completion fun(self: blink.cmp.Task, cb: fun(result: any))
--- @field on_failure fun(self: blink.cmp.Task, cb: fun(err: any))
--- @field on_cancel fun(self: blink.cmp.Task, cb: fun())

local STATUS = {
  RUNNING = 1,
  COMPLETED = 2,
  FAILED = 3,
  CANCELLED = 4,
}

local task = {
  __task = true,
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
      local mapped_result = fn(result)
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
      local mapped_err = fn(err)
      if type(mapped_err) == 'table' and mapped_err.is_task then
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
  return task.new(function(resolve)
    local results = {}

    local function resolve_if_completed()
      -- we can't check #results directly because a table like
      -- { [2] = { ... } } has a length of 2
      for i = 1, #tasks do
        if results[i] == nil then return end
      end
      resolve(results)
    end

    for idx, task in ipairs(tasks) do
      task:on_completion(function(result)
        results[idx] = { status = STATUS.COMPLETED, result = result }
        resolve_if_completed()
      end)
      task:on_failure(function(err)
        results[idx] = { status = STATUS.FAILED, err = err }
        resolve_if_completed()
      end)
      task:on_cancel(function()
        results[idx] = { status = STATUS.CANCELLED }
        resolve_if_completed()
      end)
    end
  end)
end

return { task = task, STATUS = STATUS }
