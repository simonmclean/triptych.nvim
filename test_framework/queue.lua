local u = require 'test_framework.utils'

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
  ---@type TestQueue
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

return {
  ---@param test Test
  add = function(test)
    GlobalTestQueue:add(test)
  end,
}
