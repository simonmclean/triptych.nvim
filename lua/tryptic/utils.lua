local function cond(value, handlers)
  if (value) then
    if handlers == nil then
      return true
    end
    return handlers.when_true
  end
  if handlers == nil then
    return false
  end
  return handlers.when_false
end

return {
  cond = cond
}
