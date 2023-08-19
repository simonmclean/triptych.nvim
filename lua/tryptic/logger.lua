local function log_err(message)
  -- TODO: Figure out how to properly log errors
  vim.print(message)
end

-- TODO: Include tracing
local function log(label, message, level)
  if level ~= 'INFO' and level ~= 'WARN' and level ~= 'ERROR' and level ~= 'DEBUG' then
    log_err 'echoerr Invalid log level'
    return
  end

  local prefix = 'TRYPTIC[' .. level .. '][' .. label .. '] '

  local debug_mode = vim.g.tryptic_config.debug

  -- If message is a table, the table is printed on its own line
  if type(message) == 'table' then
    if level == 'ERROR' then
      log_err(prefix)
      log_err(message)
    elseif level ~= 'DEBUG' or (level == 'DEBUG' and debug_mode) then
      vim.print(prefix)
      vim.print(message)
    end
  else
    local final_message = prefix .. tostring(message)
    if level == 'ERROR' then
      log_err(final_message)
    elseif level ~= 'DEBUG' or (level == 'DEBUG' and debug_mode) then
      vim.print(final_message)
    end
  end
end

return log
