-- TODO: I actually think the key/binding should be displayed the other way around

---@return string[]
local function help_lines()
  local mappings = vim.g.triptych_config.mappings
  local left_col_length = 0 -- Used for padding and alignment

  -- Update padding/alignment
  for key, _ in pairs(mappings) do
    if string.len(key) > left_col_length then
      left_col_length = string.len(key)
    end
  end

  ---@type { key: string, action: string }[]
  local mapping_pairs = {}

  for action, keys in pairs(mappings) do
    local keys_display_value
    if type(keys) == 'table' then
      keys_display_value = table.concat(keys, ', ')
    else
      keys_display_value = keys
    end
    table.insert(mapping_pairs, {
      action = action,
      key = keys_display_value,
    })
  end

  table.sort(mapping_pairs, function(a, b)
    return a.action < b.action
  end)

  ---@type string[]
  local lines = {}

  for _, pair in ipairs(mapping_pairs) do
    local keys_str = pair.key
    local padding = ''
    if type(pair.key) == 'table' then
      keys_str = table.concat(pair.key, ', ')
    end
    if string.len(pair.action) < left_col_length then
      local diff = left_col_length - string.len(pair.action)
      padding = string.rep(' ', diff)
    end
    local line = string.format('%s%s  :  %s', pair.action, padding, keys_str)
    table.insert(lines, line)
  end

  table.insert(lines, 1, 'Triptych key bindings')
  table.insert(lines, 2, '')

  for index, line in ipairs(lines) do
    lines[index] = ' ' .. line
  end

  return lines
end

return {
  help_lines = help_lines,
}
