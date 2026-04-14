local u = require 'triptych.utils'

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
  -- Bail out early for fifo files to avoid hangs
  if vim.fn.getftype(path) == 'fifo' then
    return 'fifo'
  end
  local success, result = pcall(vim.filetype.match, { filename = path })
  if success and result then
    return result
  end
  -- Fallback: read a small chunk to sniff the filetype by content
  local f = io.open(path, 'r')
  if f then
    local sample = f:read(512) or ''
    f:close()
    local ok, ft = pcall(vim.filetype.match, { filename = path, contents = vim.split(sample, '\n') })
    if ok and ft then
      return ft
    end
  end
end

---Read a file asynchronously and call callback(err, lines)
---@param file_path string
---@param callback fun(err: string|nil, lines: string[]|nil)
function M.read_file_async(file_path, callback)
  local uv = vim.uv or vim.loop

  uv.fs_open(file_path, 'r', 438, function(open_err, fd)
    if open_err or not fd then
      return callback('Could not open file: ' .. (open_err or 'unknown error'), nil)
    end

    uv.fs_fstat(fd, function(stat_err, stat)
      if stat_err or not stat then
        uv.fs_close(fd, function() end)
        return callback('Could not stat file: ' .. (stat_err or 'unknown error'), nil)
      end

      uv.fs_read(fd, stat.size, 0, function(read_err, data)
        uv.fs_close(fd, function() end)
        if read_err then
          return callback('Could not read file: ' .. read_err, nil)
        end
        callback(nil, u.multiline_str_to_table(data))
      end)
    end)
  end)
end

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
