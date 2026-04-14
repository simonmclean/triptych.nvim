--- Minimal luassert shim used by the test specs.
--- Only implements the subset of the luassert API that is actually used.

local M = {}

---Deep-equality check that mirrors luassert's assert.same behaviour.
---Raises an error (via Lua's built-in assert) when the values differ.
---@param expected any
---@param actual any
---@param msg? string
function M.same(expected, actual, msg)
  local function deep_eq(a, b)
    if type(a) ~= type(b) then
      return false
    end
    if type(a) ~= 'table' then
      return a == b
    end
    -- Check all keys in a exist and match in b
    for k, v in pairs(a) do
      if not deep_eq(v, b[k]) then
        return false
      end
    end
    -- Check b has no extra keys
    for k in pairs(b) do
      if a[k] == nil then
        return false
      end
    end
    return true
  end

  if not deep_eq(expected, actual) then
    local lines = {}
    if msg then
      table.insert(lines, msg)
    end
    table.insert(lines, 'Expected:')
    table.insert(lines, vim.inspect(expected))
    table.insert(lines, 'Got:')
    table.insert(lines, vim.inspect(actual))
    error(table.concat(lines, '\n'), 2)
  end
end

-- Make the module itself callable so that bare assert(cond, msg) calls work
-- even after `local assert = require 'luassert'` shadows the built-in.
setmetatable(M, {
  __call = function(_, cond, msg)
    if not cond then
      error(msg or 'assertion failed', 2)
    end
  end,
})

return M
