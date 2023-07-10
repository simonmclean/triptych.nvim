local fs = require 'tryptic.fs'
local float = require 'tryptic.float'

require 'plenary.reload'.reload_module('tryptic')

-- Globals
vim.g.tryptic_state = nil

vim.keymap.set('n', '<leader>9', ':lua vim.g.tryptic_close()<CR>')
vim.keymap.set('n', '<leader>0', ':lua require"tryptic".open_tryptic()<CR>')

local function update_child_window(target)
  vim.print('update_child_window', target)
  if (target == nil) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.child.win)
  vim.g.tryptic_state.child.path = target.path

  if target.is_dir then
    local lines = fs.tree_to_lines(target)
    float.buf_set_lines(buf, lines)
  else
    float.buf_set_lines_from_path(buf, target.path)
  end
end

local function open_tryptic(_path, _windows)
  -- TODO: I should only need to do call list_dir_contents once, because it's recurssive
  local focused_path = _path or fs.get_dirname_of_current_buffer()
  local focused_contents = fs.list_dir_contents(focused_path)
  local focused_lines = fs.tree_to_lines(focused_contents)

  local parent_path = fs.get_parent(focused_path)
  local parent_contents = fs.list_dir_contents(parent_path)
  local parent_lines = fs.tree_to_lines(parent_contents)

  local configs = {
    {
      title = parent_path,
      lines = parent_lines
    },
    {
      title = focused_path,
      lines = focused_lines
    },
    {
      title = 'todo',
      lines = {}
    },
  }

  -- TODO: create or update
  local windows = _windows or float.create_three_floating_windows(configs)

  vim.g.tryptic_state = {
    parent = {
      path = parent_path,
      contents = parent_contents,
      lines = parent_lines,
      win = windows[1]
    },
    current = {
      path = focused_path,
      contents = focused_contents,
      lines = focused_lines,
      win = windows[2]
    },
    child = {
      path = nil,
      contents = nil,
      lines = nil,
      win = windows[3]
    }
  }

  update_child_window(focused_contents.children[1])

  vim.g.tryptic_close = function()
    float.close_floats({
      vim.g.tryptic_state.parent.win,
      vim.g.tryptic_state.current.win,
      vim.g.tryptic_state.child.win,
    })

    vim.g.tryptic_target_buffer = nil
    vim.g.tryptic_state = nil
  end

end

local au_group = vim.api.nvim_create_augroup("TrypticAutoCmd", { clear = true })

local function get_target_under_cursor()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return vim.g.tryptic_state.current.contents.children[line_number]
end

local function handle_cursor_moved()
  if vim.bo.filetype == 'tryptic' and vim.g.tryptic_state ~= nil then
    local target = get_target_under_cursor()
    update_child_window(target)
  end
end

local function nav_to(target_path)
  local focused_contents = fs.list_dir_contents(target_path)
  local focused_lines = fs.tree_to_lines(focused_contents)

  local parent_path = fs.get_parent(target_path)
  local parent_contents = fs.list_dir_contents(parent_path)
  local parent_lines = fs.tree_to_lines(parent_contents)

  float.win_set_lines(vim.g.tryptic_state.parent.win, parent_lines)
  float.win_set_lines(vim.g.tryptic_state.current.win, focused_lines)

  vim.g.tryptic_state = {
    parent = {
      path = parent_path,
      contents = parent_contents, -- TODO: Do I need this in the state?
      lines = parent_lines, -- TODO: Do I need this in the state?
      win = vim.g.tryptic_state.parent.win
    },
    current = {
      path = target_path,
      contents = focused_contents,
      lines = focused_lines,
      win = vim.g.tryptic_state.current.win
    },
    child = {
      path = nil,
      contents = nil,
      lines = nil,
      win = vim.g.tryptic_state.child.win
    }
  }
end

local function edit_file(path)
  vim.g.tryptic_close()
  vim.cmd.edit(path)
end

vim.api.nvim_create_autocmd('CursorMoved', {
  group = au_group,
  callback = handle_cursor_moved
})

return {
  open_tryptic = open_tryptic,
  nav_to = nav_to,
  get_target_under_cursor = get_target_under_cursor,
  edit_file = edit_file
}
