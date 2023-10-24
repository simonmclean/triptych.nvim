local M = {}

--- Create an iterator
---@param return_values any[]
---@param spy? table
function M.iterator(return_values, spy)
  return function(input_value)
    local i = 0
    if spy then
      table.insert(spy, input_value)
    end
    return function()
      i = i + 1
      local result = return_values[i]
      if (type(result) == 'table') then
        -- This assumes that a table in this case should translate to 2 return values
        -- This being a common iteration pattern, like with vim.fs.dir
        return result[1], result[2]
      end
      return result
    end
  end
end

return M
