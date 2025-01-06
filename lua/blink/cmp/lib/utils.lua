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
    if type(v) == 'table' and vim.tbl_isempty(v) then goto continue end

    if v[1] == nil then
      table.insert(flattened, v)
    else
      vim.list_extend(flattened, utils.flatten(v))
    end

    ::continue::
  end
  return flattened
end

--- Returns the index of the first occurrence of the value in the array
--- @generic T
--- @param arr T[]
--- @param val T
--- @return number?
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
--- @return number?
function utils.find_idx(arr, predicate)
  for idx, v in ipairs(arr) do
    if predicate(v) then return idx end
  end
  return nil
end

--- Slices an array
--- @generic T
--- @param arr T[]
--- @param start number?
--- @param finish number?
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

return utils
