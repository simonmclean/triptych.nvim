local u = require 'tryptic.utils'
local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

local function get_filetype_from_path(path)
  -- There are more robust ways than just using the filetype
  -- Check the help docs
  -- Might be worth improving in future
  return vim.filetype.match({ filename = path })
end

local function list_dir_contents(_path, _tree, _current_depth)
  local path = vim.fs.normalize(_path)
  local current_depth = _current_depth or 0

  local tree = _tree or {
    path = nil,
    display_name = nil,
    is_dir = nil,
    filetype = nil,
    children = {}
  }

  if current_depth == 2 then
    return tree
  end

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
      filetype = get_filetype_from_path(child_path),
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
  for _, child in ipairs(tree.children) do
    local line = u.cond(child.is_dir, {
      when_true = function()
        return " " .. child.display_name
      end,
      when_false = function()
        local maybe_icon, color = devicons.get_icon_color_by_filetype(child.filetype)
        local fallback = ""
        local icon = u.cond(maybe_icon ~= nil, {
          when_true = function ()
	    -- TODO: Icon color
            return maybe_icon
          end,
          when_false = fallback
        })
        return icon .. ' ' .. child.display_name
      end
    })
    table.insert(lines, line)
  end
  return lines
end

return {
  list_dir_contents = list_dir_contents,
  get_dirname_of_current_buffer = get_dirname_of_current_buffer,
  get_parent = get_parent,
  tree_to_lines = tree_to_lines,
  get_filetype_from_path = get_filetype_from_path
}
