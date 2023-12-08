local u = require 'triptych.utils'

-- Sorted by highest priority last, so that > comparison works intuitively
---@enum GitFileStatusPriority
local sign_priority = {
  '??',
  'R',
  'M',
  'A',
}

local status_to_sign = {
  ['??'] = 'TriptychGitAdd',
  ['R'] = 'TriptychGitRename',
  ['M'] = 'TriptychGitModify',
  ['A'] = 'TriptychGitAdd',
}

local Git = {}

function Git.new()
  local vim = _G.triptych_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = Git })

  local cwd = vim.fn.getcwd()
  local git_status = u.multiline_str_to_table(vim.fn.system 'git status --porcelain')
  local result = {}

  local signs_config = vim.g.triptych_config.git_signs.signs

  local signs_to_text = {
    ['TriptychGitAdd'] = signs_config.add,
    ['TriptychGitModify'] = signs_config.modify,
    ['TriptychGitRename'] = signs_config.rename,
    ['TriptychGitUntracked'] = signs_config.untracked,
  }

  -- Register the signs if they're not already
  for sign_name, text in pairs(signs_to_text) do
    if u.is_empty(vim.fn.sign_getdefined(sign_name)) then
      vim.fn.sign_define(sign_name, { text = text })
    end
  end

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
  instance.project_root = u.multiline_str_to_table(vim.fn.system 'git rev-parse --show-toplevel')[1]

  return instance
end

--- Takes a list of paths and filters out those which are git ignored
---@param paths string[]
---@return PathDetails
function Git:filter_ignored(paths)
  local vim = _G.triptych_mock_vim or vim
  -- If this isn't a git project, then nothing is git ignored
  if u.is_empty(self.project_root) then
    return paths
  end
  local paths_str = u.string_join(' ', paths)
  local git_ignore_matches = u.multiline_str_to_table(vim.fn.system('git check-ignore ' .. paths_str))
  local without_ignored = u.filter(paths, function(path)
    return not u.list_includes(git_ignore_matches, path)
  end)
  return without_ignored
end

---@param path string
---@return GitFileStatus | nil
function Git:status_of(path)
  return self.status[path]
end

return {
  status_to_sign = status_to_sign,
  Git = Git,
}
