local u = require 'tests.utils'

local M = {}

local TIMEOUT_SECONDS = 7

---@class TestQueue
---@field queue Test[]
---@field completed Test[]
---@field is_running boolean
---@field add fun(self: TestQueue, test: Test)
---@field remove fun(self: TestQueue, id: string)
---@field run_next function
local TestQueue = {}

function TestQueue.new()
  local instance = {}
  setmetatable(instance, { __index = TestQueue })
  instance.queue = {}
  instance.completed = {}
  return instance
end

if not GlobalTestQueue then
  GlobalTestQueue = TestQueue.new()
end

function TestQueue:add(test)
  table.insert(self.queue, test)

  if not self.is_running then
    self.is_running = true
    vim.schedule(function()
      self:run_next()
    end)
  end
end

---Cleanup that needs doing, whether the tests passed or failed
function TestQueue:cleanup()
  self.is_running = false
  for _, test in ipairs(self.queue) do
    test:cleanup()
    test.result = nil
  end
  for _, test in ipairs(self.completed) do
    test:cleanup()
    test.result = nil
  end
  self.queue = {}
  self.completed = {}
end

---On success (pass or skip)
function TestQueue:handle_all_tests_succeeded()
  u.print '--- RESULTS ---'

  --Group tests by describe block
  ---@type table<string, { describe_title: string, tests: Test[] }>
  local grouped_tests = {}
  for _, test in ipairs(self.completed) do
    local descId = test.describe_id
    if not grouped_tests[descId] then
      grouped_tests[descId] = {
        describe_title = test.describe_title,
        tests = {},
      }
    end
    table.insert(grouped_tests[descId].tests, test)
  end

  local result_count = {
    passed = 0,
    skipped = 0,
    failed = 0,
  }

  -- Print each the result
  for _, describe_block in pairs(grouped_tests) do
    u.print('[DESCRIBE] ' .. describe_block.describe_title)
    for _, test in ipairs(describe_block.tests) do
      result_count[test.result] = result_count[test.result] + 1
      u.print(' - [' .. string.upper(test.result) .. '] ' .. test.name)
    end
  end

  -- Print the summary
  u.print(
    'Finished running '
      .. #self.completed
      .. ' tests. '
      .. result_count.skipped
      .. ' skipped, '
      .. result_count.passed
      .. ' passed, 0 failed'
  )

  self:cleanup()
  if u.is_headless() then
    u.exit_status_code 'success'
  end
end

---@param test Test
---@param fail_message? string
function TestQueue:handle_test_fail(test, fail_message)
  test.result = 'failed'
  u.print('[FAILED] ' .. test.name)
  error(fail_message)
  self:cleanup()
  if u.is_headless() then
    u.exit_status_code 'failed'
  else
  end
end

function TestQueue:run_next()
  local test = self.queue[1]

  local function next_or_finish()
    local completed_test = table.remove(self.queue, 1)
    table.insert(self.completed, completed_test)
    vim.schedule(function()
      if #self.queue > 0 then
        self:run_next()
      else
        self:handle_all_tests_succeeded()
      end
    end)
  end

  if test.is_skipped then
    u.print('[SKIPPING] ' .. test.describe_title .. ' - ' .. test.name)
    test.result = 'skipped'
    next_or_finish()
  else
    u.print('[RUNNING] ' .. test.describe_title .. ' - ' .. test.name)

    -- Timout timer
    local timer = vim.loop.new_timer()
    timer:start(1000 * TIMEOUT_SECONDS, 0, function()
      test.is_timed_out = true
      self:handle_test_fail(test, 'Timeout after ' .. TIMEOUT_SECONDS .. ' seconds')
    end)

    test:run(function(passed, fail_message)
      timer:stop()
      if not passed then
        self:handle_test_fail(test, fail_message)
      else
        test.result = 'passed'
        next_or_finish()
      end
    end)
  end
end

---@alias AsyncTestCallback fun(done: { assertions: function, cleanup?: function })

---@class Test
---@field name string
---@field id string
---@field describe_id string
---@field describe_title string
---@field is_skipped boolean
---@field is_onlyed boolean
---@field is_timed_out boolean
---@field has_run boolean
---@field result? ('passed' | 'failed' | 'skipped')
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

function Test:cleanup()
  self.has_run = false
  self.result = nil
end

---@param tests Test[]
M.describe = function(description, tests)
  local describe_id = u.UUID()

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

  for _, test in ipairs(tests) do
    test.describe_id = describe_id
    test.describe_title = description
    GlobalTestQueue:add(test)
  end
end

return M
