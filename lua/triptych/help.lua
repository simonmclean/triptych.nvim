-- TODO: I actually think the key/binding should be displayed the other way around

---@return string[]
local function help_lines()
  local mappings = vim.g.triptych_config.mappings
  local lines = {}
  local left_col_length = 0 -- Used for padding and alignment

  -- Update padding/alignment
  for key, _ in pairs(mappings) do
    if string.len(key) > left_col_length then
      left_col_length = string.len(key)
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

  table.sort(lines)

  table.insert(lines, 1, 'Triptych key bindings')
  table.insert(lines, 2, '')

  return lines
end

return {
  help_lines = help_lines,
}
