local utils = {}

--- Shallow copy table
--- @generic T
--- @param t T
--- @return T
function utils.shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--- Returns the union of the keys of two tables
--- @generic T
--- @param t1 T[]
--- @param t2 T[]
--- @return T[]
function utils.union_keys(t1, t2)
  local t3 = {}
  for k, _ in pairs(t1) do
    t3[k] = true
  end
  for k, _ in pairs(t2) do
    t3[k] = true
  end
  return vim.tbl_keys(t3)
end

--- Returns a list of unique values from the input array
--- @generic T
--- @param arr T[]
--- @return T[]
function utils.deduplicate(arr)
  local hash = {}
  for _, v in ipairs(arr) do
    hash[v] = true
  end
  return vim.tbl_keys(hash)
end

function utils.schedule_if_needed(fn)
  if vim.in_fast_event() then
    vim.schedule(fn)
  else
    fn()
  end
end

--- Flattens an arbitrarily deep table into a  single level table
--- @param t table
--- @return table
function utils.flatten(t)
  if t[1] == nil then return t end

  local flattened = {}
  for _, v in ipairs(t) do
    if v[1] == nil then
      table.insert(flattened, v)
    else
      vim.list_extend(flattened, utils.flatten(v))
    end
  end
  return flattened
end

--- Returns the index of the first occurrence of the value in the array
--- @generic T
--- @param arr T[]
--- @param val T
--- @return number | nil
function utils.index_of(arr, val)
  for idx, v in ipairs(arr) do
    if v == val then return idx end
  end
  return nil
end

--- Finds an item in an array using a predicate function
--- @generic T
--- @param arr T[]
--- @param predicate fun(item: T): boolean
--- @return T | nil
function utils.find_idx(arr, predicate)
  for idx, v in ipairs(arr) do
    if predicate(v) then return idx end
  end
  return nil
end

--- Slices an array
--- @generic T
--- @param arr T[]
--- @param start number
--- @param finish number
--- @return T[]
function utils.slice(arr, start, finish)
  start = start or 1
  finish = finish or #arr
  local sliced = {}
  for i = start, finish do
    sliced[#sliced + 1] = arr[i]
  end
  return sliced
end

--- Generates a random string of length n
--- @param n number
--- @return string
function utils.random_string(n)
  n = n or 10
  local str = ''
  for _ = 1, n do
    str = str .. string.char(math.random(97, 122))
  end
  return str
end

--- Runs a function on an interval until it returns false or the timeout is reached
--- @param fn fun(): false?
--- @param opts { interval_ms: number, timeout_ms: number }
--- @return fun() Cancels the timer
function utils.run_on_interval(fn, opts)
  local start_time = vim.uv.now()
  local timer = vim.uv.new_timer()

  local function check()
    -- Check if we've exceeded the timeout
    if (vim.uv.now() - start_time) >= opts.timeout_ms then
      timer:stop()
      timer:close()
      return
    end

    -- Run the function and check its result
    local result = fn()
    if result == false then
      timer:stop()
      timer:close()
      return
    end
  end

  -- Run immediately first
  check()

  -- Then set up the interval
  timer:start(0, opts.interval_ms, vim.schedule_wrap(check))

  return function()
    timer:stop()
    timer:close()
  end
end

return utils
