local u = require 'tests.utils'

local M = {}

local TIMEOUT_SECONDS = 3

---@class Test
---@field name string
---@field run fun(callback: fun(passed: boolean, fail_message?: string))

---@param description string
---@param test_body fun(done: function)
---@return Test
M.test = function(description, test_body)
  ---@type Test
  return {
    name = description,
    run = function(callback)
      local success, err = pcall(test_body, function(assertions)
        local passed, failed = pcall(assertions)
        if passed then
          callback(true, nil)
        else
          callback(false, failed)
        end
      end)

      -- This handles syncronous errors thrown
      if not success then
        callback(false, err)
      end
    end,
  }
end

---@param test_name string
---@param passed boolean
---@param fail_message? string
local function output_result(test_name, passed, fail_message)
  if passed then
    vim.print('[PASSED] ' .. test_name)
  else
    vim.print('[FAILED] ' .. test_name)
    vim.print(fail_message)
  end
end

---@param tests Test[]
M.run_tests = function(tests)
  local timer = vim.loop.new_timer()

  ---@param remaining_tests Test[]
  local function run_tests(remaining_tests)
    ---@type Test
    local current_test = table.remove(remaining_tests, #remaining_tests)

    if current_test then
      timer:start(1000 * TIMEOUT_SECONDS, 0, function ()
        output_result(current_test.name, false, 'Timeout after ' .. TIMEOUT_SECONDS .. ' seconds')
      end)
      current_test.run(function(passed, fail_message)
        timer:stop()
        output_result(current_test.name, passed, fail_message)
        if passed and #remaining_tests > 0 then
          run_tests(remaining_tests)
        end
      end)
    end
  end

  run_tests(u.reverse_list(tests))
end

return M
