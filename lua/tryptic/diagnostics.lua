local u = require 'tryptic.utils'

---@param severity 1 | 2 | 3 | 4
---@return string
local function get_sign(severity)
  local map = {
    [1] = 'DiagnosticSignError',
    [2] = 'DiagnosticSignWarn',
    [3] = 'DiagnosticSignInfo',
    [4] = 'DiagnosticSignHint',
  }
  return map[severity]
end

---Dictionary of path to severity
---@type Diagnostics
local __diagnostics = {}

local diagnostics = {
  ---@return Diagnostics
  get = function()
    if u.is_defined(__diagnostics) then
      return __diagnostics
    end

    local result = {}

    for _, entry in ipairs(vim.diagnostic.get()) do
      local path = vim.api.nvim_buf_get_name(entry.bufnr)
      -- TODO: De-dupe the code below
      if result[path] then
        -- Highest severity is 1, which is why we're using the < operator
        if entry.severity < result[path] then
          result[path] = entry.severity
        end
      else
        result[path] = entry.severity
      end

      -- Propagate the status up through the parent directories
      for dir in vim.fs.parents(path) do
        if dir == vim.fn.getcwd() then
          break
        end
        if result[dir] then
          -- Highest severity is 1, which is why we're using the < operator
          if entry.severity < result[dir] then
            result[dir] = entry.severity
          end
        else
          result[dir] = entry.severity
        end
      end
    end

    return result
  end,

  ---@return nil
  reset = function()
    __diagnostics = {}
  end,
}
return {
  diagnostics = diagnostics,
  get_sign = get_sign
}
