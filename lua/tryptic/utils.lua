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

local function eval(fn)
  return fn()
end

local function with_highlight_group(group_name, str)
  return '%#' .. group_name .. '#' .. str
end

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

local function list_includes(list, value)
  for _, list_item in ipairs(list) do
    if list_item == value then
      return true
    end
  end
  return false
end

local function is_empty(value)
  if value == nil or value == '' then
    return true
  end
  return false
end

local function is_defined(value)
  if value == nil or value == '' then
    return false
  end
  return true
end

local function trim_last_char(str)
  return string.sub(str, 1, string.len(str) - 1)
end

local function trim(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

local function split_string_at_index(str, index)
  local a = string.sub(str, 1, index)
  local b = string.sub(str, index + 1, string.len(str))
  return a, b
end

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
