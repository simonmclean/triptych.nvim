local function cond(value, handlers)
  if (value) then
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

local function list_index_of(list, fn)
  for index, value in ipairs(list) do
    if fn(value) then
      return index
    end
  end
  return -1
end

local function list_includes(list, value)
  for _, list_item in ipairs(list) do
    if list_item == value  then
      return true
    end
  end
  return false
end

return {
  cond = cond,
  eval = eval,
  list_includes = list_includes,
  list_index_of = list_index_of,
  with_highlight_group = with_highlight_group
}
