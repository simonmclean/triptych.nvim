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
---@return string - full path
---@return string - display name
local function read_collapsed_dirs(path, display_name)
  local handle, _ = vim.loop.fs_scandir(path)
  if not handle then
    return path, display_name
  end

  local first_node_name, first_node_type = vim.loop.fs_scandir_next(handle)

  -- Empty dir, or node is not a directory
  if not first_node_name or first_node_type ~= 'directory' then
    return path, display_name
  end

  local second_node_name, _ = vim.loop.fs_scandir_next(handle)

  -- Directory contains more than 1 node
  if second_node_name then
    return path, display_name
  end

  return read_collapsed_dirs(path .. '/' .. first_node_name, display_name .. first_node_name .. '/')
end

---@param path string
---@param include_collapsed boolean whether to drill recursively into collapsed dirs
---@param callback function(tree) end
function M.read_path(path, include_collapsed, callback)
  local path_normalized = vim.fs.normalize(path)

  local tree = {
    path = path_normalized,
    display_name = vim.fs.basename(path_normalized),
    dirname = vim.fs.dirname(path_normalized),
    is_dir = vim.fn.isdirectory(path_normalized) == 1,
    filetype = nil,
    children = {},
  }

  local handle = vim.loop.fs_scandir(path_normalized)
  if not handle then
    -- Fallback to cwd asynchronously
    return M.read_path(vim.fn.getcwd(), include_collapsed, callback)
  end

  local function process_entries()
    local name, entry_type = vim.loop.fs_scandir_next(handle)
    if name then
      local entry_path = path_normalized .. '/' .. name
      local is_dir = entry_type == 'directory' or (entry_type == 'link' and vim.fn.isdirectory(entry_path) == 1)
      local display_name = is_dir and (name .. '/') or name

      local entry = {
        display_name = display_name,
        path = entry_path,
        dirname = path_normalized,
        is_dir = is_dir,
        filetype = nil,
        children = {},
      }

      if not is_dir then
        entry.filetype = M.get_filetype_from_path(entry_path)
      elseif include_collapsed then
        local collapsed_path, collapsed_display_name = read_collapsed_dirs(entry_path, display_name)
        entry.collapse_path = collapsed_path
        entry.collapse_display_name = collapsed_display_name
      end

      table.insert(tree.children, entry)
      -- Schedule next iteration to yield to the event loop
      vim.schedule(process_entries)
    else
      if vim.g.triptych_config.options.dirs_first then
        table.sort(tree.children, function(a, b)
          if a.is_dir and not b.is_dir then
            return true
          elseif not a.is_dir and b.is_dir then
            return false
          else
            return a.path < b.path
          end
        end)
      end
      callback(tree)
    end
  end

  process_entries()
end

return M
