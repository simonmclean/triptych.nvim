local Diagnostics = {}

---@param severity 1 | 2 | 3 | 4
---@return string
Diagnostics.get_sign = function(severity)
  local map = {
    [1] = 'DiagnosticSignError',
    [2] = 'DiagnosticSignWarn',
    [3] = 'DiagnosticSignInfo',
    [4] = 'DiagnosticSignHint',
  }
  return map[severity]
end

Diagnostics.new = function()
  local vim = _G.triptych_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = Diagnostics })

  ---@type { [string]: integer }
  instance.diagnostics = {}

  ---@param entry { severity: integer }
  ---@param path string
  local function set_diagnostic(entry, path)
    if instance.diagnostics[path] then
      -- Highest severity is 1, which is why we're using the < operator
      if entry.severity < instance.diagnostics[path] then
        instance.diagnostics[path] = entry.severity
      end
    else
      instance.diagnostics[path] = entry.severity
    end
  end

  for _, entry in ipairs(vim.diagnostic.get()) do
    local path = vim.api.nvim_buf_get_name(entry.bufnr)
    set_diagnostic(entry, path)

    -- Propagate the status up through the parent directories
    for dir in vim.fs.parents(path) do
      if dir == vim.fn.getcwd() then
        break
      end
      set_diagnostic(entry, dir)
    end
  end

  return instance
end

---@param path string
---@return integer | nil
function Diagnostics:get(path)
  return self.diagnostics[path]
end

return {
  new = Diagnostics.new,
  get_sign = Diagnostics.get_sign,
}
