local u = require 'triptych.utils'

local M = {}

-- Sorted by highest priority last, so that > comparison works intuitively
---@enum GitFileStatusPriority
local sign_priority = {
  '??',
  'R',
  'M',
  'A',
}

M.status_to_sign = {
  ['??'] = 'TriptychGitAdd',
  ['R'] = 'TriptychGitRename',
  ['M'] = 'TriptychGitModify',
  ['A'] = 'TriptychGitAdd',
}

---Convert gitignore globs into lua patterns (which are like very simplified regex)
local function glob_to_lua_pattern(glob)
  return glob:gsub('%.', '%%.'):gsub('%*', '.*'):gsub('%?', '.') .. '$'
end

---Reads the .gitignore file of a given directory (if it exists) and returns the ignore patterns
---@param dir string path
---@return string[]
local function read_gitignore(dir)
  local ignore_patterns = {}
  local gitignore_path = dir .. '/.gitignore'
  local gitignore_file = io.open(gitignore_path, 'r')
  if gitignore_file then
    for line in gitignore_file:lines() do
      if not (line:match '^#' or line:match '^%s*$') then
        table.insert(ignore_patterns, glob_to_lua_pattern(line))
      end
    end
    gitignore_file:close()
  end
  return ignore_patterns
end

M.Git = {}

function M.Git.new()
  local vim = _G.triptych_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = M.Git })

  local cwd = vim.fn.getcwd()
  local git_status = u.multiline_str_to_table(vim.fn.system 'git status --porcelain')
  local git_status_result = {}

  local signs_config = vim.g.triptych_config.git_signs.signs

  local signs_to_text = {
    ['TriptychGitAdd'] = signs_config.add,
    ['TriptychGitModify'] = signs_config.modify,
    ['TriptychGitRename'] = signs_config.rename,
    ['TriptychGitUntracked'] = signs_config.untracked,
  }

  -- Register the signs if they're not already
  for sign_name, opts in pairs(signs_to_text) do
    if u.is_empty(vim.fn.sign_getdefined(sign_name)) then
      if type(opts) == 'string' then
        vim.fn.sign_define(sign_name, { text = opts })
      elseif type(opts) == 'table' then
        vim.fn.sign_define(sign_name, opts)
      end
    end
  end

  -- Propagate the status up through the parent directories
  for _, value in ipairs(git_status) do
    local status, file = u.split_string_at_index(value, 3)
    local status_trimmed = u.trim(status)
    local file_path = u.path_join(cwd, file)
    git_status_result[file_path] = status_trimmed

    for dir in vim.fs.parents(file_path) do
      if dir == cwd then
        break
      end
      if git_status_result[dir] then
        local existing_sign_priority = u.list_index_of(sign_priority, git_status_result[dir])
        local this_sign_priority = u.list_index_of(sign_priority, status_trimmed)
        if this_sign_priority > existing_sign_priority then
          git_status_result[dir] = status_trimmed
        end
      else
        git_status_result[dir] = status_trimmed
      end
    end
  end

  instance.status = git_status_result
  instance.git_ignore_patterns = read_gitignore '.'
  instance.project_root = u.multiline_str_to_table(vim.fn.system 'git rev-parse --show-toplevel')[1]

  return instance
end

---@param name string
---@param is_dir boolean
---@return boolean
function M.Git:should_ignore(name, is_dir)
  -- .git isn't usually included in the gitignore, so we're hard-coding here
  if is_dir and name == '.git' then
    return true
  end

  for _, pattern in ipairs(self.git_ignore_patterns) do
    if name:match(pattern) then
      return true
    end
    -- Directories can be with or without trailing slash, so we check this as well
    if is_dir and (name .. '/'):match(pattern) then
      return true
    end
  end

  return false
end

---@param path string
---@return GitFileStatus | nil
function M.Git:status_of(path)
  return self.status[path]
end

return M
