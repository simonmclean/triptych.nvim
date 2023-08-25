local u = require 'tryptic.utils'

-- Sorted by highest priority last, so that > comparison works intuitively
---@enum GitFileStatusPriority
local sign_priority = {
  '??',
  'R',
  'D',
  'M',
  'A',
  'AM',
}

---@param status GitFileStatus
---@return string
local function get_sign(status)
  local signs = vim.g.tryptic_config.git_signs.signs
  local map = {
    ['A'] = signs.add,
    ['AM'] = signs.add_modify,
    ['D'] = signs.delete,
    ['M'] = signs.modify,
    ['R'] = signs.rename,
    ['??'] = signs.untracked,
  }
  return map[status]
end

---@type GitStatus | nil
local __git_status = nil
local git_status = {
  ---@return GitStatus
  get = function()
    if __git_status then
      return __git_status
    end

    local cwd = vim.fn.getcwd()
    local git_status = u.multiline_str_to_table(vim.fn.system 'git status --porcelain')
    local result = {}

    -- Propagate the status up through the parent directories
    for _, value in ipairs(git_status) do
      local status, file = u.split_string_at_index(value, 3)
      local status_trimmed = u.trim(status)
      local file_path = cwd .. '/' .. file
      result[file_path] = status_trimmed

      for dir in vim.fs.parents(file_path) do
        if dir == cwd then
          break
        end
        if result[dir] then
          local existing_sign_priority = u.list_index_of(sign_priority, result[dir])
          local this_sign_priority = u.list_index_of(sign_priority, status_trimmed)
          if this_sign_priority > existing_sign_priority then
            result[dir] = status_trimmed
          end
        else
          result[dir] = status_trimmed
        end
      end
    end

    __git_status = result
    return result
  end,

  reset = function()
    __git_status = nil
  end,
}

return {
  git_status = git_status,
  get_sign = get_sign
}
