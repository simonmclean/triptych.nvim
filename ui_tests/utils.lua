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

---@return nil
function M.wait()
  local co = coroutine.running()
  vim.defer_fn(function()
    coroutine.resume(co)
  end, 50)
  coroutine.yield()
end

---@param inputs string|string[]
---@return nil
function M.user_input(inputs)
  local input_list = u.cond(type(inputs) == 'table', {
    when_true = inputs,
    when_false = { inputs },
  })
  for _, input in ipairs(input_list) do
    vim.api.nvim_input(input)
    M.wait()
  end
end

---@param direction 'left' | 'right' | 'up' | 'down'
---@return nil
function M.move(direction)
  if direction == 'left' then
    M.user_input 'h'
  elseif direction == 'right' then
    M.user_input 'l'
  elseif direction == 'down' then
    M.user_input 'j'
  elseif direction == 'up' then
    M.user_input 'k'
  end
end

return M
