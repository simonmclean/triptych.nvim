local u = require 'triptych.utils'

local M = {}

---@param role 'parent' | 'primary' | 'child'
---@return table
function M.get_lines(role)
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local _, maybe_value = pcall(vim.api.nvim_win_get_var, win, 'triptych_role')
    if maybe_value == role then
      local buf = vim.api.nvim_win_get_buf(win)
      return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end
  end
  return {}
end

function M.wait()
  local co = coroutine.running()
  vim.defer_fn(function()
    coroutine.resume(co)
  end, 50)
  coroutine.yield()
end

---@param inputs string|string[]
function M.user_input(inputs)
  local input_list = u.cond(type(inputs) == 'table', {
    when_true = inputs,
    when_false = { inputs },
  })
  for _, input in ipairs(input_list) do
    vim.api.nvim_exec2('normal ' .. input, {})
    M.wait()
  end
end

return M
