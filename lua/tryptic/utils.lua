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
  for index, value in ipairs(list) do
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

---@param value string | nil
---@return boolean
local function is_empty(value)
  if value == nil or value == '' then
    return true
  end
  return false
end

---@param value string | nil
---@return boolean
local function is_defined(value)
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
  return string.gsub(str, '^%s*(.-)%s*$', '%1')[1]
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

---@param a table
---@param b table
---@return table
local function merge_tables(a, b)
  for key, value in pairs(b) do
    if type(value) == 'table' then
      merge_tables(a[key], b[key])
    elseif a and b[key] then
      a[key] = value
    end
  end
  return a
end

---@param str string
---@return string[]
local function multiline_str_to_table(str)
  local lines = {}
  for s in str:gmatch '[^\r\n]+' do
    table.insert(lines, s)
  end
  return lines
end

return {
  cond = cond,
  eval = eval,
  list_includes = list_includes,
  list_index_of = list_index_of,
  with_highlight_group = with_highlight_group,
  is_empty = is_empty,
  is_defined = is_defined,
  trim_last_char = trim_last_char,
  trim = trim,
  merge_tables = merge_tables,
  multiline_str_to_table = multiline_str_to_table,
  split_string_at_index = split_string_at_index,
}
