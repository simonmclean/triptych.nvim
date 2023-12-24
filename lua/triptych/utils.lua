-- TODO: The cond function seems to require a more sophisticated type
-- system than LuaCATS allows

---@alias CondFuncHandler1 fun(): any
---@alias CondFuncHandler2 fun(): any, any
---@class CondFuncHandlers
---@field when_true any | CondFuncHandler1 | CondFuncHandler2
---@field when_false any | CondFuncHandler1 | CondFuncHandler2
---@class CondValueHandlers
---@field when_true any
---@field when_false any

---@param value any # will be checked for truthiness
---@param handlers CondFuncHandlers
---@return any
local function cond(value, handlers)
  if value then
    if type(handlers.when_true) == 'function' then
      return handlers.when_true()
    end
    return handlers.when_true
  end

  if type(handlers.when_false) == 'function' then
    return handlers.when_false()
  end
  return handlers.when_false
end

---@param fn function
local function eval(fn)
  return fn()
end

---@param ... string
---@return string
local function path_join(...)
  local args = { ... }
  local path = ''
  for i = 1, #args, 1 do
    local part = args[i]
    if i == 1 and string.sub(part, 1, 1) == '/' then
      path = path .. part
    else
      path = path .. '/' .. part
    end
  end
  return path
end

---@param path string
---@return string[]
local function path_split(path)
  local result = {}
  local first_char = string.sub(path, 1, 1)
  if first_char == '/' then
    table.insert(result, '/')
  end
  local parts = string.gmatch(path, '([^/]+)')
  for part in parts do
    table.insert(result, part)
  end
  return result
end

---@param sep string
---@param str_list string[]
---@return string
local function string_join(sep, str_list)
  local result = ''
  for index, str in ipairs(str_list) do
    result = result .. str
    if index < #str_list then
      result = result .. sep
    end
  end
  return result
end

---@param group_name string
---@param str string
---@return string
local function with_highlight_group(group_name, str)
  return '%#' .. group_name .. '#' .. str
end

---@param list any[]
---@param value_or_fn function | string | number | integer
---@return integer
local function list_index_of(list, value_or_fn)
  for index, value in pairs(list) do
    if type(value_or_fn) == 'function' then
      if value_or_fn(value) then
        return index
      end
    else
      if value == value_or_fn then
        return index
      end
    end
  end
  return -1
end

---@param list any[]
---@param value string | number | integer
---@return boolean
local function list_includes(list, value)
  for _, list_item in ipairs(list) do
    if list_item == value then
      return true
    end
  end
  return false
end

---@param value nil | string | table
---@return boolean
local function is_empty(value)
  if type(value) == 'table' then
    return next(value) == nil
  end
  if value == nil or value == '' then
    return true
  end
  return false
end

---@param value nil | string | table
---@return boolean
local function is_defined(value)
  if type(value) == 'table' then
    return next(value) ~= nil
  end
  if value == nil or value == '' then
    return false
  end
  return true
end

---@param str string
---@return string
local function trim_last_char(str)
  return string.sub(str, 1, string.len(str) - 1)
end

---@param str string
---@return string
local function trim(str)
  ---@diagnostic disable-next-line: redundant-return-value
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

---@param str string
---@param index integer
---@return string
---@return string
local function split_string_at_index(str, index)
  local a = string.sub(str, 1, index)
  local b = string.sub(str, index + 1, string.len(str))
  return a, b
end

---@param t1 table
---@param t2 table
---@return table
local function merge_tables(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == 'table' then
      if type(t1[k] or false) == 'table' then
        merge_tables(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

local function list_concat(a, b)
  local result = {}
  for _, value in ipairs(a) do
    table.insert(result, value)
  end
  for _, value in ipairs(b) do
    table.insert(result, value)
  end
  return result
end

---@generic K, A, B
---@param tbl table<K, A>
---@param fn fun(value: A): B
---@return table<K, B>
local function map(tbl, fn)
  local result = {}
  for _, value in ipairs(tbl) do
    table.insert(result, fn(value))
  end
  return result
end

---@generic K, A
---@param tbl table<K, A>
---@param fn fun(value: A): A
---@return table<K, A>
local function filter(tbl, fn)
  local result = {}
  for _, value in ipairs(tbl) do
    if fn(value) then
      table.insert(result, value)
    end
  end
  return result
end

---@param str? string
---@return string[]
local function multiline_str_to_table(str)
  if not str then
    return {}
  end
  local lines = {}
  for s in str:gmatch '[^\r\n]+' do
    table.insert(lines, s)
  end
  return lines
end

--- Functional setter. Creates new copy. Only works on shallow tables
---@param tbl table
---@param k any
---@param v any
---@return table
local function set(tbl, k, v)
  local result = {}
  for key, value in pairs(tbl) do
    if key == k then
      result[k] = v
    else
      result[key] = value
    end
  end
  return result
end

---Curried function for getting index from a table
---@param index any
---@return function
local function get(index)
  ---@param tbl table
  ---@return any
  return function(tbl)
    return tbl[index]
  end
end

---@param str string
---@param search string
---@return boolean
local function string_contains(str, search)
  return string.find(str, search, 1, true) ~= nil
end

---@param value number
---@param num_of_decimal_places number
---@return number
local function round(value, num_of_decimal_places)
  local mult = 10 ^ (num_of_decimal_places or 0)
  return math.floor(value * mult + 0.5) / mult
end

--- Returns the debounced function and an instance of vim.loop.new_timer
--- Must call timer:close() when no longer needed in order to avoid memory leaks
--- Based on https://gist.github.com/runiq/31aa5c4bf00f8e0843cd267880117201
---@param fn function Function to debounce
---@param ms number Timeout in ms
---@return function
---@return table
local function debounce_trailing(fn, ms)
  local timer = vim.loop.new_timer()
  local wrapped_fn
  local first_time = true

  wrapped_fn = function(...)
    local argv = { ... }
    local argc = select('#', ...)
    local wait_ms = cond(first_time, {
      when_true = 0,
      when_false = ms,
    })
    timer:start(wait_ms, 0, function()
      first_time = false
      ---@diagnostic disable-next-line: deprecated
      pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
    end)
  end

  return wrapped_fn, timer
end

return {
  cond = cond,
  eval = eval,
  list_includes = list_includes,
  list_index_of = list_index_of,
  list_concat = list_concat,
  with_highlight_group = with_highlight_group,
  is_empty = is_empty,
  is_defined = is_defined,
  trim_last_char = trim_last_char,
  trim = trim,
  merge_tables = merge_tables,
  map = map,
  filter = filter,
  multiline_str_to_table = multiline_str_to_table,
  split_string_at_index = split_string_at_index,
  string_join = string_join,
  string_contains = string_contains,
  path_join = path_join,
  path_split = path_split,
  set = set,
  get = get,
  round = round,
  debounce_trailing = debounce_trailing,
}
