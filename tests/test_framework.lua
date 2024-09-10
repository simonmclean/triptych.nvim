local u = require 'tests.utils'

local M = {}

local TIMEOUT_SECONDS = 7

if not TestsRunning then
  ---@type table<string, Test>
  TestsRunning = {}
end

-- Sniff out whether we're running in headless mode
-- When true, the framework will close vim on error or when all tests finish
vim.g.is_headless = true
vim.schedule(function()
  vim.g.is_headless = #vim.api.nvim_list_uis() == 0
end)

---@alias AsyncTestCallback fun(done: { assertions: function, cleanup?: function })

---@class Test
---@field name string
---@field id boolean
---@field is_skipped boolean
---@field is_onlyed boolean
---@field is_timed_out boolean
---@field has_run boolean
---@field result? ('passed' | 'failed' | 'skipped')
---@field fail_message? string
---@field is_async boolean
---@field test_body? function
---@field test_body_async? AsyncTestCallback
local Test = {}

---@param name string
---@return Test
function Test.new(name)
  local instance = {}
  setmetatable(instance, { __index = Test })

  instance.name = name
  instance.id = u.UUID()
  instance.is_onlyed = false
  instance.is_timed_out = false
  instance.has_run = false

  return instance
end

---Define a synchronous test
---@param name string
---@param test_body function
---@return Test
M.test = function(name, test_body)
  local t = Test.new(name)
  t.test_body = test_body
  t.is_async = false
  return t
end

---Define an asyncronous test
---@param name string
---@param test_body AsyncTestCallback
---@return Test
M.test_async = function(name, test_body)
  local t = Test.new(name)
  t.test_body_async = test_body
  t.is_async = true
  return t
end

---Run a test, calling the relevant method depending on whether it's sync or async
---@param callback fun(passed: boolean, fail_message?: string)
function Test:run(callback)
  if self.is_async then
    self:run_async(callback)
  else
    self:run_sync(callback)
  end
end

---Run an asyncronous test
---@param callback fun(passed: boolean, fail_message?: string)
function Test:run_async(callback)
  local success, err = pcall(self.test_body_async, function(test_callback)
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

  -- This catches errors thrown before we reach cleanup or assertions
  if not success then
    callback(false, err)
  end
end

---Run a synchronous test
---@param callback fun(passed: boolean, fail_message?: string)
function Test:run_sync(callback)
  local success, err = pcall(self.test_body)
  if success then
    callback(true, nil)
  else
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
  local print_level
  if test.result == 'passed' then
    print_level = 'success'
  elseif test.result == 'skipped' then
    print_level = 'warn'
  elseif test.result == 'failed' then
    print_level = 'error'
  end
  local indent = ' - '
  u.print(indent .. '[' .. string.upper(test.result) .. '] ' .. test.name, print_level)
  if test.fail_message then
    u.print(test.fail_message)
  end
end

---@param test Test
local function handle_test_complete(test)
  output_result(test)
  if test.result == 'failed' and vim.g.is_headless then
    u.exit_status_code 'failed'
  end
end

---Print the final result summary
---@param passed integer
---@param skipped integer
local function output_final_results(passed, skipped)
  local total = passed + skipped
  u.print('Finished running ' .. total .. ' tests. ' .. skipped .. ' skipped, ' .. passed .. ' passed, 0 failed')
end

---Check in the global space if any tests are still running
local function are_tests_running()
  for _, test in pairs(TestsRunning) do
    if not test.result then
      return true
    end
  end
  return false
end

---Check if other tests are still running. If so, do nothing, otherwise do things
local function on_test_suite_finish()
  -- Check if there are other test suites running
  if not are_tests_running() then
    local passed_count = 0
    local skipped_count = 0
    for _, test in pairs(TestsRunning) do
      if test.result == 'passed' then
        passed_count = passed_count + 1
      elseif test.result == 'skipped' then
        skipped_count = skipped_count + 1
      end
    end
    output_final_results(passed_count, skipped_count)
    TestsRunning = {}
    if vim.g.is_headless then
      u.exit_status_code 'success'
    end
  end
end

---@param tests Test[]
M.describe = function(description, tests)
  u.print('[DESCRIBE] ' .. description)

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

  -- Register test as running in global space
  for _, test in ipairs(tests) do
    TestsRunning[tostring(test.id)] = test
  end

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
        handle_test_complete(current_test)
        next()
      else
        timer:start(1000 * TIMEOUT_SECONDS, 0, function()
          current_test.is_timed_out = true
          current_test.result = 'failed'
          current_test.fail_message = 'Timeout after ' .. TIMEOUT_SECONDS .. ' seconds'
          handle_test_complete(current_test)
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
            handle_test_complete(current_test)
            next()
          end
        end)
      end
    else
      on_test_suite_finish()
    end
  end

  run_tests(u.reverse_list(tests))
end

return M
