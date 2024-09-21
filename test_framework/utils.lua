local M = {}

function M.UUID()
  local handle = io.popen 'uuidgen'
  if handle then
    local uuid = handle:read '*a'
    handle:close()
    return uuid
  end
  error 'uuidgen failed'
end

---@param list table
---@param fn fun(element: any): boolean
---@return boolean
function M.list_find(list, fn)
  for _, value in ipairs(list) do
    if fn(value) then
      return value
    end
  end
  return false
end

---Used when running tests headlessly
---@param status ('success' | 'failed')
function M.exit_status_code(status)
  if status == 'success' then
    M.print 'Exiting with status code 0'
    vim.cmd '0cq'
  else
    M.print 'Exiting with status code 1'
    vim.cmd '1cq'
  end
end

---Decides how to output messages, based on whether we're running headlessly
---@param str string
---@param level? ('error' | 'warn' | 'info' | 'success')
function M.print(str, level)
  if M.is_headless() then
    io.stdout:write(str)
    io.stdout:write '\n'
  else
    local highlight = 'Normal'
    if level == 'error' then
      highlight = 'Error'
    elseif level == 'warn' then
      highlight = 'WarningMsg'
    elseif level == 'success' then
      highlight = 'String'
    end
    vim.api.nvim_echo({ { str, highlight } }, true, {})
  end
end

function M.is_headless()
  return vim.fn.getenv 'HEADLESS' == 'true'
end

---@param error_message string
function M.raise_error(error_message)
  if M.is_headless() then
    M.print(error_message)
  else
    error(error_message)
  end
end

return M
