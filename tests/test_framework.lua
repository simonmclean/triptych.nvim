local u = require 'tests.utils'

local M = {}

local TIMEOUT_SECONDS = 7

-- TODO: values (like has_run, result, is_timed_out) persist between test runs. Write a function to reset the tests
-- This should run on pcall error, and also on successful completion
-- Perhaps I can just call the constructor again?

---@alias TestBodyCallback fun(done: { assertions: function, cleanup?: function })

---@class Test
---@field name string
---@field is_skipped boolean
---@field is_onlyed boolean
---@field is_timed_out boolean
---@field has_run boolean
---@field result? ('passed' | 'failed' | 'skipped')
---@field fail_message? string
---@field test_body fun(done: TestBodyCallback)
local Test = {}

---@param name string
---@param test_body fun(done: TestBodyCallback)
---@return Test
function Test.new(name, test_body)
  local instance = {}
  setmetatable(instance, { __index = Test })

  instance.name = name
  instance.is_ignored = false
  instance.is_onlyed = false
  instance.is_timed_out = false
  instance.has_run = false
  instance.test_body = test_body

  return instance
end

M.test = Test.new

---@param callback fun(passed: boolean, fail_message?: string)
function Test:run(callback)
  local success, err = pcall(self.test_body, function(test_callback)
    if self.has_run then
      error 'Attempted to invoke test completion more than once. Check that any async callbacks in the test are not firing multiple times.'
    end

    self.has_run = true

    if test_callback.cleanup then
      local cleanup_successful, cleanup_err = pcall(test_callback.cleanup)
      if not cleanup_successful then
        error(cleanup_err)
      end
    end

    if self.is_timed_out then
      callback(false, 'Timed out')
    else
      local passed, fail_message = pcall(test_callback.assertions)
      if passed then
        callback(true, nil)
      else
        callback(false, fail_message)
      end
    end
  end)

  -- This handles syncronous errors thrown
  if not success then
    callback(false, err)
  end
end

function Test:skip()
  self.is_skipped = true
  return self
end

function Test:only()
  self.is_onlyed = true
  return self
end

---@param test Test
local function output_result(test)
  vim.print('[' .. string.upper(test.result) .. '] ' .. test.name)
  if test.fail_message then
    vim.print(test.fail_message)
  end
end

---@param passed integer
---@param skipped integer
local function output_final_results(passed, skipped)
  local total = passed + skipped
  vim.print('Finished running ' .. total .. ' tests. ' .. skipped .. ' skipped, ' .. passed .. ' passed')
end

---@param tests Test[]
M.run_tests = function(tests)
  local contains_onlyed = u.list_find(tests, function(test)
    return test.is_onlyed
  end)

  if contains_onlyed then
    for _, test in ipairs(tests) do
      if not test.is_onlyed then
        test:skip()
      end
    end
  end

  local timer = vim.loop.new_timer()

  -- Not counting failed, because we stop in that case
  local result_count = {
    passed = 0,
    skipped = 0,
  }

  ---@param remaining_tests Test[]
  local function run_tests(remaining_tests)
    ---@type Test
    local current_test = table.remove(remaining_tests, #remaining_tests)

    local function next()
      local result = current_test.result

      if not result then
        error 'Unexpected nil result'
      end

      if result == 'failed' then
        return
      end

      result_count[result] = result_count[result] + 1

      vim.schedule(function()
        run_tests(remaining_tests)
      end)
    end

    if current_test then
      if current_test.is_skipped then
        current_test.result = 'skipped'
        output_result(current_test)
        next()
      else
        timer:start(1000 * TIMEOUT_SECONDS, 0, function()
          current_test.is_timed_out = true
          current_test.result = 'failed'
          current_test.fail_message = 'Timeout after ' .. TIMEOUT_SECONDS .. ' seconds'
          output_result(current_test)
        end)

        current_test:run(function(passed, fail_message)
          timer:stop()
          if not current_test.is_timed_out then
            if passed then
              current_test.result = 'passed'
            else
              current_test.result = 'failed'
              current_test.fail_message = fail_message
            end
            output_result(current_test)
            next()
          end
        end)
      end
    else
      output_final_results(result_count.passed, result_count.skipped)
    end
  end

  run_tests(u.reverse_list(tests))
end

return M
