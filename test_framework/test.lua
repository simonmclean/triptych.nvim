local u = require 'test_framework.utils'
local test_queue = require 'test_framework.queue'

local M = {}

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
  local success, err = pcall(self.test_body_async, function(test_finish)
    if self.has_run then
      u.raise_error 'Attempted to invoke test completion more than once. Check that any async callbacks in the test are not firing multiple times.'
    end

    -- Scheduling this allows cleanup to complete before running the next test
    local scheduled_callback = vim.schedule_wrap(callback)

    self.has_run = true

    if test_finish.cleanup then
      local cleanup_successful, cleanup_err = pcall(test_finish.cleanup)
      if not cleanup_successful then
        u.raise_error(cleanup_err)
      end
    end

    if self.is_timed_out then
      scheduled_callback(false, 'Timed out')
    else
      local passed, fail_message = pcall(test_finish.assertions)
      if passed then
        scheduled_callback(true, nil)
      else
        scheduled_callback(false, fail_message)
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

function Test:reset()
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
    test_queue.add(test)
  end
end

return M
