local u = require 'triptych.utils'
local plenary_filetype = require 'plenary.filetype'
local plenary_scandir = require 'plenary.scandir'

---@param path string
---@return number
local function get_file_size_in_kb(path)
  local vim = _G.triptych_mock_vim or vim
  local bytes = vim.fn.getfsize(path)
  return bytes / 1000
end

---@param path string
---@return string?
local function get_filetype_from_path(path)
  local success, result = pcall(plenary_filetype.detect, path)
  if success then
    return result
  end
end

---@param _path string
---@param callback fun(path_details: PathDetails): nil
local function get_path_details(_path, callback)
  local vim = _G.triptych_mock_vim or vim
  local path = vim.fs.normalize(_path)

  local tree = {
    path = path,
    display_name = vim.fs.basename(path),
    dirname = nil, -- i.e. parent dir
    is_dir = vim.fn.isdirectory(path) == 1,
    filetype = nil,
    children = {},
  }

  plenary_scandir.scan_dir_async(path, {
    depth = 1,
    add_dirs = true,
    respect_gitignore = true, -- TODO: Config
    hidden = false, -- TODO: Config
    silent = true,
    on_exit = function(children)
      ---@type { path: string, is_dir: boolean }[]
      local children_with_type = u.eval(function()
        local result = {}
        for _, child in ipairs(children) do
          table.insert(result, { path = child, is_dir = vim.fn.isdirectory(child) == 1 })
        end
        return result
      end)

      if vim.g.triptych_config.options.dirs_first then
        table.sort(children_with_type, function(a, b)
          if a.is_dir and not b.is_dir then
            return true
          end
          if not a.is_dir and b.is_dir then
            return false
          end
          return a.path < b.path
        end)
      end

      for index, child in ipairs(children_with_type) do
        tree.children[index] = {
          path = child.path,
          display_name = u.cond(child.is_dir, {
            when_true = vim.fs.basename(child.path) .. '/',
            when_false = vim.fs.basename(child.path),
          }),
          filetype = u.cond(child.is_dir, {
            when_true = nil,
            when_false = function()
              return get_filetype_from_path(child.path)
            end,
          }),
          basename = vim.fs.basename(child.path),
          dirname = vim.fs.dirname(child.path),
          is_dir = child.is_dir,
          children = {},
        }
      end

      callback(tree)
    end,
  })
end

return {
  get_path_details = get_path_details,
  get_filetype_from_path = get_filetype_from_path,
  get_file_size_in_kb = get_file_size_in_kb,
}
