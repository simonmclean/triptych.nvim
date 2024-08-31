local M = {}

---@param ... string
---@return string
function M.join_path(...)
    return table.concat({ ... }, "/")
end

---@param n integer
---@param callback function
function M.wait_ticks(n, callback)
  local function tick()
    if n == 0 then
      callback()
    else
      n = n - 1
      vim.schedule(tick)
    end
  end
  tick()
end

function M.get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

return M
