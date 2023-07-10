local u = require 'tryptic.utils'

local function list_dir_contents(_path, _tree, _current_depth)
  local path = vim.fs.normalize(_path)
  local current_depth = _current_depth or 0

  local tree = _tree or {
    path = nil,
    display_name = nil,
    is_dir = nil,
    children = {}
  }

  if current_depth == 2 then
    return tree
  end

  local index = 1

  for child_name, child_type in vim.fs.dir(path) do
    local is_dir = child_type == 'directory'

    tree.children[index] = {
      path = path .. '/' .. child_name,
      display_name = u.cond(is_dir, {
        when_true = child_name .. '/',
        when_false = child_name
      }),
      is_dir = is_dir,
      children = {}
    }

    if is_dir then
      local child_dir_path = tree.children[index].path
      list_dir_contents(child_dir_path, tree.children[index], current_depth + 1)
    end

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

local function tree_to_lines(tree)
  local lines = {}
  for _, v in ipairs(tree.children) do
    table.insert(lines, v.display_name)
  end
  return lines
end

local function get_filetype_from_path(path)
  local temp_buf = vim.api.nvim_create_buf(false, true)
  local filetype = nil
  vim.api.nvim_buf_call(temp_buf, function ()
    vim.cmd.edit(path)
    filetype = vim.bo.filetype
  end)
  vim.api.nvim_buf_delete(temp_buf, { force = true })
  return filetype
end

return {
  list_dir_contents = list_dir_contents,
  get_dirname_of_current_buffer = get_dirname_of_current_buffer,
  get_parent = get_parent,
  tree_to_lines = tree_to_lines,
  get_filetype_from_path = get_filetype_from_path
}
