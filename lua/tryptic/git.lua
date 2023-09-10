local u = require 'tryptic.utils'
local fs = require 'tryptic.fs'

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

---@type string[]
local __git_ignore = {}
local __git_ignore_checked = false

---@return GitIgnore
local git_ignore = function()
  if not __git_ignore_checked then
    local lines = fs.read_lines_from_file './.gitignore'
    for _, line in pairs(lines) do
      table.insert(__git_ignore, line)
    end
    __git_ignore_checked = true
  end

  ---@return string[]
  local function get()
    return __git_ignore
  end

  ---@param path string
  ---@return boolean
  local is_ignored = function(path)
    local parts = u.path_split(path)
    local is_dir = vim.fn.isdirectory(path) == 1
    for index, part in ipairs(parts) do
      local is_part_dir = is_dir or index < #parts
      if u.list_includes(__git_ignore, part) or (is_part_dir and u.list_includes(__git_ignore, part .. '/')) then
        return true
      end
    end
    return false
  end

  ---@return nil
  local function reset()
    __git_ignore = {}
    __git_ignore_checked = false
  end

  return {
    get = get,
    is_ignored = is_ignored,
    reset = reset
  }
end

---Dictionary of path to status
---@type GitStatus
local __git_status = {}

local git_status = {
  ---@return GitStatus
  get = function()
    if u.is_defined(__git_status) then
      return __git_status
    end

    local cwd = vim.fn.getcwd()
    local git_status = u.multiline_str_to_table(vim.fn.system 'git status --porcelain')
    local result = {}

    -- Propagate the status up through the parent directories
    for _, value in ipairs(git_status) do
      local status, file = u.split_string_at_index(value, 3)
      local status_trimmed = u.trim(status)
      local file_path = u.path_join(cwd, file)
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
    __git_status = {}
  end,
}

return {
  git_status = git_status,
  get_sign = get_sign,
  git_ignore = git_ignore,
}
