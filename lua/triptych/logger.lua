return {
  ---@param function_name string
  ---@param data? table
  debug = function(function_name, data)
    if vim.g.triptych_config.debug then
      local log_line = '[triptych][' .. function_name .. '] '
      if data then
        log_line = log_line .. ' ' .. vim.inspect(data)
      end
      vim.print(log_line)
    end
  end,
}
