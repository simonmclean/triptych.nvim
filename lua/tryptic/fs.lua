local u = require 'tryptic.utils'

local function get_file_size_in_kb(path)
  local bytes = vim.fn.getfsize(path)
  return bytes / 1000
end

local function get_filetype_from_path(path)
  local filename = vim.fs.basename(path)
  local extension = vim.fn.fnamemodify(filename, ':e')
  local ft = vim.filetype.match({ filename = filename })

  -- TODO: This extension to filetype mapping is a hack
  -- I should be able to use filetype.match but it isn't working
  if ft == nil then
    if extension == 'ts' then return 'typescript' end
    if extension == 'txt' then return 'text' end
  end

  -- if ft == nil and get_file_size_in_kb(path) < 300 then
  --   vim.print('getting thing for ' .. filename)
  --   local lines = vim.fn.readfile(path)
  --   if filename == 'config.ts' then
  --     vim.print('lines', lines)
  --   end
  --   local x = vim.filetype.match({ filename = filename, contents = lines })
  --   vim.print('ft = ' .. (x or ''))
  --   return x
  -- end

  return ft
end

local function list_dir_contents(_path)
  local path = vim.fs.normalize(_path)

  local tree = {
    path = nil,
    display_name = nil,
    basename = nil, -- i.e file or folder name
    dirname = nil, -- i.e. parent
    is_dir = nil,
    filetype = nil,
    cutting = false,
    children = {}
  }

  local index = 1

  for child_name, child_type in vim.fs.dir(path) do
    local is_dir = child_type == 'directory'
    local child_path = path .. '/' .. child_name

    tree.children[index] = {
      path = child_path,
      display_name = u.cond(is_dir, {
        when_true = child_name .. '/',
        when_false = child_name
      }),
      filetype = u.cond(is_dir, {
        when_true = nil,
        when_false = function()
          return get_filetype_from_path(child_path)
        end
      }),
      basename = vim.fs.basename(child_path),
      dirname = vim.fs.dirname(child_path),
      is_dir = is_dir,
      children = {}
    }

    index = index + 1
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
