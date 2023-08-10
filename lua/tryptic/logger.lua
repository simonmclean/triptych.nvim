local function log_err(message)
  -- TODO: Figure out how to properly log errors
  vim.print(message)
end

-- TODO: Include tracing
local function log(message, level)
  if level ~= 'INFO' and level ~= 'WARN' and level ~= 'ERROR' then
    log_err('echoerr Invalid log level')
    return
  end

  if type(message) ~= 'string' then
    log_err(
      'Expected message to be string, got ' .. tostring(type(message))
    )
  end

  local prefix = 'Tryptic [' .. level .. '] '
  local final_message = prefix .. message

  if level == 'ERROR' then
    log_err(final_message)
  else
    vim.print(final_message)
  end
end

return log
