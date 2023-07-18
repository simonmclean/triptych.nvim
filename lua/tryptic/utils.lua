local function cond(value, handlers)
  if type(value) ~= "boolean" then
    error("cond expects value to be a boolean")
  end

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

local function with_highlight_group(group_name, str)
  return '%#' .. group_name .. '#' .. str
end

return {
  cond = cond,
  with_highlight_group = with_highlight_group
}
