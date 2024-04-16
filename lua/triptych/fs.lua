local u = require 'triptych.utils'
local plenary_filetype = require 'plenary.filetype'
local plenary_path = require 'plenary.path'
local plenary_async = require 'plenary.async'

local M = {}

---@param path string
---@return number
function M.get_file_size_in_kb(path)
  local vim = _G.triptych_mock_vim or vim
  local bytes = vim.fn.getfsize(path)
  return bytes / 1000
end

---@param path string
---@return string?
function M.get_filetype_from_path(path)
  local success, result = pcall(plenary_filetype.detect, path)
  if success then
    return result
  end
end

M.read_file_async = plenary_async.wrap(function(file_path, callback)
  local file = plenary_path:new(file_path)

  if not file:exists() then
    return callback('File does not exist', nil)
  end

  file:read(function(content)
    callback(nil, u.multiline_str_to_table(content))
  end)
end, 2)

---@param _path string
---@param show_hidden boolean
---@param callback fun(path_details: PathDetails): nil
function M.get_path_details(_path, show_hidden, callback)
  local vim = _G.triptych_mock_vim or vim
  local path = vim.fs.normalize(_path)

  local tree = {
    path = path,
    display_name = vim.fs.basename(path),
    dirname = vim.fs.dirname(path), -- i.e. parent dir
    is_dir = vim.fn.isdirectory(path) == 1,
    filetype = nil,
    children = {},
  }

  local handle, _ = vim.loop.fs_scandir(path)
  if not handle then
    -- On error fallback to cwd
    M.get_path_details(vim.fn.getcwd(), show_hidden, callback)
    return
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    local entry_path = path .. '/' .. name
    table.insert(tree.children, {
      display_name = name,
      path = entry_path,
      dirname = path,
      is_dir = type == 'directory',
      filetype = u.eval(function()
        if type == 'directory' then
          return
        end
        return M.get_filetype_from_path(entry_path)
      end),
      children = {},
    })
  end

  if vim.g.triptych_config.options.dirs_first then
    table.sort(tree.children, function(a, b)
      if a.is_dir and not b.is_dir then
        return true
      end
      if not a.is_dir and b.is_dir then
        return false
      end
      return a.path < b.path
    end)
  end

  callback(tree)
end

return M
