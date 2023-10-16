local M = {}

--- Create an iterator
---@param values any[]
function M.iterator(values)
  return function()
    local i = 0
    return function()
      i = i + 1
      return values[i]
    end
  end
end

return M
