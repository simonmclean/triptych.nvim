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
  local vim = _G.tryptic_mock_vim or vim
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

-- TODO: Can we make these private memebers?
local GitIgnore = {
  ---@type string[]
  entries = {},
}

---@return GitIgnore
function GitIgnore.new()
  local instance = {}
  setmetatable(instance, { __index = GitIgnore })
  -- TODO: Handle when file is not present
  local lines = fs.read_lines_from_file './.gitignore'
  for _, line in pairs(lines) do
    table.insert(instance.entries, line)
  end
  return instance
end

---@param path string
---@return boolean
function GitIgnore:is_ignored(path)
  local parts = u.path_split(path)
  local is_dir = vim.fn.isdirectory(path) == 1
  for index, part in ipairs(parts) do
    local is_part_dir = is_dir or index < #parts
    if u.list_includes(self.entries, part) or (is_part_dir and u.list_includes(self.entries, part .. '/')) then
      return true
    end
  end
  return false
end

local GitStatus = {
  status = {},
}

function GitStatus.new()
  local instance = {}
  setmetatable(instance, { __index = GitStatus })

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

  instance.status = result

  return instance
end

---@param path string
---@return GitFileStatus | nil
function GitStatus:get(path)
  return self.status[path]
end

return {
  get_sign = get_sign,
  GitIgnore = GitIgnore,
  GitStatus = GitStatus,
}
