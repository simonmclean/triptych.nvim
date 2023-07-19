local fs = require 'tryptic.fs'
local float = require 'tryptic.float'
local u = require 'tryptic.utils'
local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

require 'plenary.reload'.reload_module('tryptic')

-- Globals
vim.g.tryptic_state = {
  parent = {
    win = nil
  },
  current = {
    win = nil,
  },
  child = {
    win = nil
  },
}
vim.g.tryptic_is_open = false
vim.g.tryptic_autocmds = {}
local path_to_line_map = {}

vim.keymap.set('n', '<leader>0', ':lua require"tryptic".toggle_tryptic()<CR>')

local au_group = vim.api.nvim_create_augroup("TrypticAutoCmd", { clear = true })

local function tree_to_lines(tree)
  local lines = {}
  local highlights = {}

  for _, child in ipairs(tree.children) do
    local line, highlight_name = u.cond(child.is_dir, {
      when_true = function()
        local line = " " .. child.display_name
        return line, 'Directory'
      end,
      when_false = function()
        local maybe_icon, highlight_name = devicons.get_icon_by_filetype(child.filetype)
        local fallback = ""
        local icon = u.cond(maybe_icon ~= nil, {
          when_true = function()
            return maybe_icon
          end,
          when_false = fallback
        })
        local line = icon .. ' ' .. child.display_name
        return line, highlight_name or 'Comment'
      end
    })
    table.insert(lines, line)
    table.insert(highlights, highlight_name)
  end

  return lines, highlights
end

local function update_child_window(target)
  local buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.child.win)

  vim.g.tryptic_state.child.path = u.cond(target == nil, {
    when_true = nil,
    when_false = function()
      return target.path
    end
  })

  if (target == nil) then
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      '[empty directory]'
    )
    float.buf_set_lines(buf, {})
  elseif target.is_dir then
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      vim.fs.basename(target.path),
      "",
      "Directory"
    )
    local lines, highlights = tree_to_lines(target)
    float.buf_set_lines(buf, lines)
    float.buf_apply_highlights(buf, highlights)
  else
    local filetype = fs.get_filetype_from_path(target.path) -- TODO: De-dupe this
    local maybe_icon, maybe_highlight = devicons.get_icon_by_filetype(filetype)
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      vim.fs.basename(target.path),
      maybe_icon,
      maybe_highlight
    )
    float.buf_set_lines_from_path(buf, target.path)
  end
end

local function get_target_under_cursor()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return vim.g.tryptic_state.current.contents.children[line_number]
end

local function handle_cursor_moved()
  if vim.g.tryptic_is_open then
    local target = get_target_under_cursor()
    local current_dir = vim.g.tryptic_state.current.path
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    path_to_line_map[current_dir] = line_number
    update_child_window(target)
  end
end

local function handle_buf_leave()
  if vim.g.tryptic_is_open then
    vim.g.tryptic_close()
  end
end

local function create_autocommands()
  local a = vim.api.nvim_create_autocmd('CursorMoved', {
    group = au_group,
    callback = function()
      handle_cursor_moved()
    end
  })

  local b = vim.api.nvim_create_autocmd('BufLeave', {
    group = au_group,
    callback = handle_buf_leave
  })

  vim.g.tryptic_autocmds = { a, b }
end

local function destroy_autocommands()
  for _, autocmd in pairs(vim.g.tryptic_autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

local function nav_to(target_dir)
  local focused_win = vim.g.tryptic_state.current.win
  local parent_win = vim.g.tryptic_state.parent.win
  local child_win = vim.g.tryptic_state.child.win

  local focused_buf = vim.api.nvim_win_get_buf(focused_win)
  local focused_contents = fs.list_dir_contents(target_dir)
  local focused_title = vim.fs.basename(target_dir)
  local focused_lines, focused_highlights = tree_to_lines(focused_contents)

  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  local parent_path = fs.get_parent(target_dir)
  local parent_title = vim.fs.basename(parent_path)
  local parent_contents = fs.list_dir_contents(parent_path)
  local parent_lines, parent_highlights = tree_to_lines(parent_contents)

  float.win_set_lines(parent_win, parent_lines)
  float.win_set_lines(focused_win, focused_lines)

  float.win_set_title(parent_win, parent_title, "", "Directory")
  float.win_set_title(focused_win, focused_title, "", "Directory")

  float.buf_apply_highlights(focused_buf, focused_highlights)
  float.buf_apply_highlights(parent_buf, parent_highlights)

  local focused_win_line_number = path_to_line_map[target_dir] or 1
  vim.api.nvim_win_set_cursor(0, { focused_win_line_number, 0 })

  local parent_win_line_number = 1
  for i, child in ipairs(parent_contents.children) do
    if child.path == target_dir then
      parent_win_line_number = i
      break
    end
  end
  vim.api.nvim_win_set_cursor(parent_win, { parent_win_line_number, 0 })

  vim.g.tryptic_state = {
    parent = {
      path = parent_path,
      contents = parent_contents,
      win = parent_win
    },
    current = {
      path = target_dir,
      contents = focused_contents,
      win = focused_win,
    },
    child = {
      path = nil,
      contents = nil,
      lines = nil,
      win = child_win
    }
  }
end

local function open_tryptic()
  if vim.g.tryptic_is_open then
    return
  end

  local file_path_dir = fs.get_dirname_of_current_buffer()

  vim.g.tryptic_is_open = true

  local windows = float.create_three_floating_windows()

  vim.g.tryptic_state = {
    parent = {
      win = windows[1]
    },
    current = {
      win = windows[2],
    },
    child = {
      win = windows[3]
    },
  }

  create_autocommands()

  vim.g.tryptic_close = function()
    vim.print("CLOSE")
    vim.g.tryptic_is_open = false

    float.close_floats({
      vim.g.tryptic_state.parent.win,
      vim.g.tryptic_state.current.win,
      vim.g.tryptic_state.child.win,
    })

    destroy_autocommands()

    vim.g.tryptic_target_buffer = nil
    vim.g.tryptic_state = nil
  end

  nav_to(file_path_dir)
end

local function toggle_tryptic()
  if vim.g.tryptic_is_open then
    vim.g.tryptic_close()
  else
    open_tryptic()
  end
end

local function edit_file(path)
  vim.g.tryptic_close()
  vim.cmd.edit(path)
end

local function setup()
  vim.print('SETUP')
end

local function delete()
  local target = get_target_under_cursor()
  local response = vim.fn.confirm(
    'Are you sure you want to delete "' .. target.display_name .. '"?',
    '&y\n&n',
    "Question"
  )
  if response and response == 1 then
    vim.fn.delete(target.path, "rf")
    -- TODO: This an inefficient way of refreshing the view
    nav_to(vim.g.tryptic_state.current.path)
  end
end

local function add_file_or_dir()
  local current_directory = vim.g.tryptic_state.current.path
  local response = vim.fn.trim(vim.fn.input(
    'Enter name for new file or directory (dirs end with a "/"): '
  ))
  if not response then
    return
  end
  local response_length = string.len(response)
  local includes_file = string.sub(response, response_length, response_length) ~= '/'
  if includes_file then
    local includes_dirs = string.find(response, '/') ~= nil

    if includes_dirs then
      local length_of_filename = string.find(string.reverse(response), '/') - 1
      local filename = string.sub(response, response_length - length_of_filename + 1, response_length)
      local dirs_to_create = string.sub(response, 1, response_length - length_of_filename)
      local absolute_dir_path = current_directory .. '/' .. dirs_to_create
      vim.fn.mkdir(absolute_dir_path, "p")
      -- TODO: writefile is destructive. Add checking
      vim.fn.writefile({}, absolute_dir_path .. filename)
    else
      vim.fn.writefile({}, current_directory .. '/' .. response)
    end
  else
    vim.fn.mkdir(current_directory .. '/' .. response, "p")
  end

  -- TODO: This an inefficient way of refreshing the view
  nav_to(vim.g.tryptic_state.current.path)
end

local function duplicate()
  local target = get_target_under_cursor()
  local response = vim.fn.trim(vim.fn.input(
    'Copy "' .. target.display_name .. '" as: '
  ))
  if response and response ~= target.display_name then
    vim.fn.writefile(
      fs.read_lines_from_file(target.path),
      vim.g.tryptic_state.current.path .. '/' .. response
    )
    -- TODO: This an inefficient way of refreshing the view
    nav_to(vim.g.tryptic_state.current.path)
  end
end

local function rename()
  local target = get_target_under_cursor()
  local response = vim.fn.trim(vim.fn.input(
    'Enter new name for ' .. target.display_name .. ': '
  ))
  if response and response ~= target.display_name then
    local basename = vim.fs.dirname(target.path)
    vim.fn.rename(target.path, basename .. '/' .. response)
    -- TODO: This an inefficient way of refreshing the view
    nav_to(vim.g.tryptic_state.current.path)
  end
end

return {
  toggle_tryptic = toggle_tryptic,
  nav_to = nav_to,
  get_target_under_cursor = get_target_under_cursor,
  edit_file = edit_file,
  setup = setup,
  delete = delete,
  add_file_or_dir = add_file_or_dir,
  duplicate = duplicate,
  rename = rename
}
