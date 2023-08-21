local u = require 'tryptic.utils'
local git = require 'tryptic.git'
local plenary_filetype = require 'plenary.filetype'

local function get_file_size_in_kb(path)
  local bytes = vim.fn.getfsize(path)
  return bytes / 1000
end

local function get_filetype_from_path(path)
  return plenary_filetype.detect(path)
end

local function list_dir_contents(_path)
  local git_status = git.git_status.get()
  local path = vim.fs.normalize(_path)

  local tree = {
    path = nil,
    display_name = nil,
    basename = nil, -- i.e file or folder name
    dirname = nil, -- i.e. parent
    is_dir = nil,
    filetype = nil,
    cutting = false,
    git_status = nil,
    children = {},
  }

  local children = {}
  for child_name, child_type in vim.fs.dir(path) do
    table.insert(children, { child_name, child_type })
  end

  if vim.g.tryptic_config.options.dirs_first then
    table.sort(children, function(a, b)
      if a[2] == 'directory' and b[2] ~= 'directory' then
        return true
      end
      if a[2] ~= 'directory' and b[2] == 'directory' then
        return false
      end
      return a[1] < b[1]
    end)
  end

  for index, name_and_type in ipairs(children) do
    local child_name = name_and_type[1]
    local is_dir = name_and_type[2] == 'directory'
    local child_path = path .. '/' .. child_name

    tree.children[index] = {
      path = child_path,
      display_name = u.cond(is_dir, {
        when_true = child_name .. '/',
        when_false = child_name,
      }),
      filetype = u.cond(is_dir, {
        when_true = nil,
        when_false = function()
          return get_filetype_from_path(child_path)
        end,
      }),
      basename = vim.fs.basename(child_path),
      dirname = vim.fs.dirname(child_path),
      is_dir = is_dir,
      git_status = u.cond(git_status, {
        when_true = function ()
          return git_status[child_path]
        end,
        when_false = nil
      }),
      children = {},
    }
  end

  return tree
end

local function get_dirname_of_current_buffer()
  return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
end

local function get_parent(path)
  return vim.fs.dirname(path)
end

local function read_lines_from_file(path)
  local temp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_call(temp_buf, function()
    vim.cmd.read(path)
    -- TODO: This is kind of hacky
    vim.api.nvim_exec2('normal! 1G0dd', {})
  end)
  return vim.api.nvim_buf_get_lines(temp_buf, 0, -1, true)
end

return {
  list_dir_contents = list_dir_contents,
  get_dirname_of_current_buffer = get_dirname_of_current_buffer,
  get_parent = get_parent,
  get_filetype_from_path = get_filetype_from_path,
  read_lines_from_file = read_lines_from_file,
  get_file_size_in_kb = get_file_size_in_kb,
}
