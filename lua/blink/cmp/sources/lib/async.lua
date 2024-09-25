--- @class blink.cmp.Task
--- @field status 1 | 2 | 3
--- @field result any
--- @field new fun(fn: fun(..., cb: fun(result: any, success: boolean | nil)), ...): blink.cmp.Task
--- @field await fun(self: blink.cmp.Task, cb: fun(success: boolean, result: any))
--- @field cancel fun(self: blink.cmp.Task)

local STATUS = {
  RUNNING = 1,
  COMPLETED = 2,
  FAILED = 3,
}

local task = {}

function task.new(fn, ...)
  local self = setmetatable({}, { __index = task })
  self.status = STATUS.RUNNING
  self._awaits = {}
  self.result = nil

  local arg = { ... }

  local success, cancel_or_err = pcall(function()
    local cb = function(result, success)
      if self.status ~= STATUS.RUNNING then return end
      if success == false then return self:cancel() end

      self.status = STATUS.COMPLETED
      self.result = result

      for _, await_cb in ipairs(self._awaits) do
        await_cb(true, result)
      end
    end

    -- todo: why doesnt unpack work?
    if #arg == 0 then
      return fn(cb)
    elseif #arg == 1 then
      return fn(arg[1], cb)
    elseif #arg == 2 then
      return fn(arg[1], arg[2], cb)
    end

    return fn(unpack(arg), cb)
  end)

  if not success then
    vim.print('Failed to create task :' .. cancel_or_err)
    self:cancel()
  elseif type(cancel_or_err) ~= 'function' then
    vim.print('Cancel is not a function')
    vim.print(cancel_or_err)
    self:cancel()
  else
    self._cancel = cancel_or_err
  end

  return self
end

function task:cancel()
  if self.status ~= STATUS.RUNNING then return end
  self.status = STATUS.FAILED
  if self._cancel ~= nil then self._cancel() end

  for _, await_cb in ipairs(self._awaits) do
    await_cb(false)
  end
end

function task:await(cb)
  if self.status == STATUS.FAILED then
    cb(false)
  elseif self.status == STATUS.COMPLETED then
    cb(true, self.result)
  else
    table.insert(self._awaits, cb)
  end
  return self
end

function task:map(f)
  return task.new(function(cb)
    self:await(function(success, result)
      if success then
        cb(f(result))
      else
        cb(nil, false)
      end
    end)
    return function() self:cancel() end
  end)
end

function task:map_error(f)
  return task.new(function(cb)
    self:await(function(success, result)
      if success then
        cb(result)
      else
        cb(f())
      end
    end)
    return function() self:cancel() end
  end)
end

return { task = task, STATUS = STATUS }
