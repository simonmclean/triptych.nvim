local u = require 'triptych.utils'
local plenary_filetype = require 'plenary.filetype'
local plenary_path = require 'plenary.path'
local plenary_async = require 'plenary.async'

local M = {}

---@param path string
---@return number
function M.get_file_size_in_kb(path)
  local bytes = vim.fn.getfsize(path)
  return bytes / 1000
end

---@param path string
---@return string?
function M.get_filetype_from_path(path)
  -- plenary locks up when trying to read a fifo file, so we're sniffing this out first
  if vim.fn.getftype(path) == 'fifo' then
    return 'fifo'
  end
  -- We still want to use plenary though, because it has more advanced filetype detection
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

---Keep recursively reading into sub-directories, so long as each sub-directory contains only a single directory and no files
---@param path string
---@param display_name string
---@return string
---@return string
local function read_collapsed_dirs(path, display_name)
  local handle, _ = vim.loop.fs_scandir(path)
  if not handle then
    return path, display_name
  end

  local dirs = {}
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if type ~= 'directory' or #dirs > 1 then
      return path, display_name
    end
    table.insert(dirs, name)
  end

  if #dirs == 1 then
    return read_collapsed_dirs(path .. '/' .. dirs[1], display_name .. dirs[1] .. '/')
  end

  return path, display_name
end

---@param _path string
---@param show_hidden boolean
function M.read_path(_path, show_hidden)
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
    return M.get_path_details(vim.fn.getcwd(), show_hidden)
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    local entry_path = path .. '/' .. name
    local is_dir = type == 'directory'
    local display_name = is_dir and (name .. '/') or name
    local entry = {
      display_name = display_name,
      path = entry_path,
      dirname = path,
      is_dir = is_dir,
      filetype = u.eval(function()
        if type == 'directory' then
          return
        end
        return M.get_filetype_from_path(entry_path)
      end),
      children = {},
    }
    if is_dir then
      local collapsed_path, collapsed_display_name = read_collapsed_dirs(entry_path, display_name)
      entry.collapse_path = collapsed_path
      entry.collapse_display_name = collapsed_display_name
    end
    table.insert(tree.children, entry)
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

  return tree
end

return M
