---@return string[]
local function help_lines()
  local vim = _G.tryptic_mock_vim or vim
  local mappings = vim.g.tryptic_config.mappings
  local lines = {
    'Tryptic key bindings',
    '',
  }

  local left_col_length = 0
  for _, value in pairs(mappings) do
    local str_value = value
    if type(value) == 'table' then
      str_value = table.concat(value, ', ')
    end
    if string.len(str_value) > left_col_length then
      left_col_length = string.len(str_value)
    end
  end

  for key, value in pairs(mappings) do
    local display_value = value
    local padding = ''
    if type(value) == 'table' then
      display_value = table.concat(value, ', ')
    end
    if string.len(display_value) < left_col_length then
      local diff = left_col_length - string.len(display_value)
      padding = string.rep(' ', diff)
    end
    local line = '[' .. display_value .. ']' .. padding .. ' : ' .. key
    table.insert(lines, line)
  end
  return lines
end

return {
  help_lines = help_lines,
}
