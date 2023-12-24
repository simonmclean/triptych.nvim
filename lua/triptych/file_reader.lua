local u = require 'triptych.utils'
local float = require 'triptych.float'

--- Wraps float.buf_set_lines_from_path with a "smart" debounce.
--- Doesn't debounce on first call
--- Doesn't debounce if elapsed time since last call > debounce_ms
local FileReader = {}

---@param debounce_ms number
---@return table
function FileReader.new(debounce_ms)
  local instance = {}
  setmetatable(instance, { __index = FileReader })

  local read_lines_fn = float.buf_set_lines_from_path
  local debounced_fn, timer = u.debounce_trailing(read_lines_fn, debounce_ms)

  instance.debounce_ms = debounce_ms
  instance.last_called = nil
  instance.debounce_timer = timer
  instance.read_now = read_lines_fn
  instance.read_debounced = debounced_fn

  return instance
end

---@param buf number
---@param path string
---@param bypass_debounce boolean
---@return nil
function FileReader:read(buf, path, bypass_debounce)
  local vim = _G.triptych_mock_vim or vim
  local should_run_instantly = self.debounce_ms == 0
    or bypass_debounce
    or u.eval(function()
      if self.last_called == nil then
        return true
      end
      local millis_since_last_called = math.floor(vim.fn.reltimefloat(vim.fn.reltime(self.last_called)) * 1000)
      return millis_since_last_called > self.debounce_ms
    end)
  if should_run_instantly then
    self.read_now(buf, path)
  else
    self.read_debounced(buf, path)
  end
  self.last_called = vim.fn.reltime()
end

function FileReader:destroy()
  self.debounce_timer:close()
end

return {
  new = FileReader.new,
}
