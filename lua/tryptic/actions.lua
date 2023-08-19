local u = require 'tryptic.utils'
local float = require 'tryptic.float'
local view = require 'tryptic.view'
local state = require 'tryptic.state'
local log = require 'tryptic.logger'
local plenary_path = require 'plenary.path'

local function help()
  local win = state.view_state.get().child.win
  float.win_set_title(
    win,
    'Help',
    "󰋗",
    "Directory"
  )
  float.win_set_lines(win, require 'tryptic.help'.help_lines())
end

local function delete(_target, without_confirm)
  local target = _target or view.get_target_under_cursor()

  if without_confirm then
    vim.fn.delete(target.path, "rf")
    view.refresh_view()
  else
    local response = vim.fn.confirm(
      'Are you sure you want to delete "' .. target.display_name .. '"?',
      '&y\n&n',
      "Question"
    )
    if u.is_defined(response) and response == 1 then
      vim.fn.delete(target.path, "rf")
      view.refresh_view()
    end
  end
end

local function add_file_or_dir()
  local current_directory = state.view_state.get().current.path
  local response = vim.fn.trim(vim.fn.input(
    'Enter name for new file or directory (dirs end with a "/"): '
  ))
  if u.is_empty(response) then
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

  view.refresh_view()
end

local function toggle_cut()
  local target = view.get_target_under_cursor()
  local index = state.cut_list.index_of(target.path)
  if index > -1 then
    state.cut_list.remove(index)
  else
    state.cut_list.add(target)
  end
  local lines, highlights = view.tree_to_lines(state.view_state.get().current.contents)
  float.win_set_lines(
    state.view_state.get().current.win,
    lines
  )
  float.buf_apply_highlights(0, highlights)
end

local function copy(_target, _destination)
  local target = _target or view.get_target_under_cursor()

  local destination = u.cond(_destination, {
    when_true = _destination,
    when_false = function()
      local prompt = 'Copy '
      prompt = prompt .. u.cond(target.is_dir, {
        when_true = 'directory "',
        when_false = 'file "',
      })
      prompt = prompt .. u.cond(target.is_dir, {
        when_true = u.trim_last_char(target.display_name),
        when_false = target.display_name
      })
      prompt = prompt .. '" as: '
      local response = vim.fn.trim(vim.fn.input(prompt))
      if u.is_defined(response) and response ~= target.display_name then
        return target.dirname .. '/' .. response
      end
    end
  })

  if destination then
    local p = plenary_path:new(target.path)
    local results = p:copy({
      destination = destination,
      recursive = true,
      override = false,
      interactive = true
    })
    -- TODO: Check results
    view.refresh_view()
  end
end

local function rename()
  local target = view.get_target_under_cursor()
  local display_name = u.cond(target.is_dir, {
    when_true = u.trim_last_char(target.display_name),
    when_false = target.display_name
  })
  local response = vim.fn.trim(vim.fn.input(
    'Enter new name for "' .. display_name .. '": '
  ))
  if u.is_defined(response) and response ~= target.display_name then
    vim.fn.rename(target.path, target.basename .. '/' .. response)
    view.refresh_view()
  end
end

local function paste()
  local cursor_target = view.get_target_under_cursor()
  local destination_dir = u.cond(cursor_target.is_dir, {
    when_true = cursor_target.path,
    when_false = cursor_target.dirname
  })
  local success, result = pcall(function()
    for _, cut_item in ipairs(state.cut_list) do
      local destination = destination_dir .. '/' .. cut_item.basename
      if cut_item.path ~= destination then
        copy(cut_item, destination)
        delete(cut_item, true)
      end
    end
    view.jump_cursor_to(destination_dir)
  end)
  if not success then
    -- TODO: Log this at warning level
    log('PASTE', 'Failed to paste: ' .. result, 'ERROR')
  end
  state.cut_list.remove_all()
  view.refresh_view()
end

local function edit_file(path)
  require 'tryptic'.close_tryptic()
  vim.cmd.edit(path)
end

return {
  help = help,
  rename = rename,
  paste = paste,
  delete = delete,
  copy = copy,
  toggle_cut = toggle_cut,
  add_file_or_dir = add_file_or_dir,
  edit_file = edit_file
}
