local fs = require 'tryptic.fs'
local float = require 'tryptic.float'
local u = require 'tryptic.utils'
local plenary_path = require 'plenary.path'
local log = require 'tryptic.logger'
local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

require 'plenary.reload'.reload_module('tryptic')

local path_to_line_map = {}
local cut_list = {}
local opening_win = nil

local au_group = vim.api.nvim_create_augroup("TrypticAutoCmd", { clear = true })

local function initialise_state()
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
  path_to_line_map = {}
  cut_list = {}
  opening_win = nil
end

local function close_tryptic()
  vim.g.tryptic_close()
end

local function tree_to_lines(tree)
  local lines = {}
  local highlights = {}

  for _, child in ipairs(tree.children) do
    local line, highlight_name = u.cond(child.is_dir, {
      when_true = function()
        local line = ''
        if devicons_installed then
          line = line .. " "
        end
        line = line .. child.display_name
        return line, 'Directory'
      end,
      when_false = function()
        if devicons_installed then
          local maybe_icon, maybe_highlight = devicons.get_icon_by_filetype(child.filetype)
          local highlight = maybe_highlight or 'Comment'
          local fallback_icon = ""
          local icon = maybe_icon or fallback_icon
          local line = icon .. ' ' .. child.display_name
          return line, highlight
        end
        return child.display_name
      end
    })

    local cut_paths = u.eval(function()
      local paths = {}
      for _, cut_item in ipairs(cut_list) do
        table.insert(paths, cut_item.path)
      end
      return paths
    end)

    if (u.list_includes(cut_paths, child.path)) then
      line = line .. ' (cut)'
    end

    table.insert(lines, line)
    table.insert(highlights, highlight_name)
  end

  return lines, highlights
end

local function get_title_postfix(path)
  if path == vim.fn.getcwd() then
    return '(cwd)'
  end
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
      target.basename,
      "",
      "Directory",
      get_title_postfix(target.path)
    )
    local lines, highlights = tree_to_lines(fs.list_dir_contents(target.path))
    float.buf_set_lines(buf, lines)
    float.buf_apply_highlights(buf, highlights)
  else
    local filetype = fs.get_filetype_from_path(target.path) -- TODO: De-dupe this
    local icon, highlight = u.cond(devicons_installed, {
      when_true = function()
        return devicons.get_icon_by_filetype(filetype)
      end,
      when_false = function()
        return nil, nil
      end
    })
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      target.basename,
      icon,
      highlight
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

local function index_of_path(path, paths_list)
  local num = 1
  for i, child in ipairs(paths_list) do
    if child.path == path then
      num = i
      break
    end
  end
  return num
end

local function nav_to(target_dir, cursor_target)
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
  float.win_set_lines(focused_win, focused_lines, true)

  float.win_set_title(parent_win, parent_title, "", "Directory", get_title_postfix(parent_path))
  float.win_set_title(focused_win, focused_title, "", "Directory", get_title_postfix(target_dir))

  float.buf_apply_highlights(focused_buf, focused_highlights)
  float.buf_apply_highlights(parent_buf, parent_highlights)

  local focused_win_line_number = u.cond(cursor_target, {
    when_true = function()
      return index_of_path(cursor_target, focused_contents.children)
    end,
    when_false = path_to_line_map[target_dir] or 1
  })
  local buf_line_count = vim.api.nvim_buf_line_count(focused_buf)
  vim.api.nvim_win_set_cursor(0, { math.min(focused_win_line_number, buf_line_count), 0 })

  local parent_win_line_number = index_of_path(target_dir, parent_contents.children)
  vim.api.nvim_win_set_cursor(parent_win, { parent_win_line_number, 0 })

  vim.g.tryptic_state = {
    parent = {
      path = parent_path,
      contents = parent_contents,
      win = parent_win
    },
    current = {
      path = target_dir,
      previous_path = vim.g.tryptic_state.current.path,
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

local function refresh_view()
  -- TODO: This an inefficient way of refreshing the view
  nav_to(vim.g.tryptic_state.current.path)
end

local function open_tryptic()
  if vim.g.tryptic_is_open then
    return
  end

  initialise_state()

  opening_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_buf_get_name(0)
  local buf_dir = vim.fs.dirname(buf)

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
    vim.g.tryptic_is_open = false

    float.close_floats({
      vim.g.tryptic_state.parent.win,
      vim.g.tryptic_state.current.win,
      vim.g.tryptic_state.child.win,
    })

    destroy_autocommands()

    vim.api.nvim_set_current_win(opening_win)

    initialise_state()
  end

  nav_to(buf_dir, buf)
end

local function toggle_tryptic()
  if vim.g.tryptic_is_open then
    close_tryptic()
  else
    open_tryptic()
  end
end

local function edit_file(path)
  close_tryptic()
  vim.cmd.edit(path)
end

local function setup(user_config)
  local default_config = {
    mappings = {
      open_tryptic = '<leader>-',
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
      delete = 'd',
      add = 'a',
      copy = 'c',
      rename = 'r',
      cut = 'x',
      paste = 'p',
      quit = 'q',
      toggle_hidden = '<leader>.' -- TODO implement this
    }
  }

  local final_config = u.merge_tables(default_config, user_config or {})

  vim.g.tryptic_config = final_config
  vim.keymap.set('n', vim.g.tryptic_config.mappings.open_tryptic, ':lua require"tryptic".toggle_tryptic()<CR>')
end

local function delete(_target, without_confirm)
  local target = _target or get_target_under_cursor()

  if without_confirm then
    vim.fn.delete(target.path, "rf")
    refresh_view()
  else
    local response = vim.fn.confirm(
      'Are you sure you want to delete "' .. target.display_name .. '"?',
      '&y\n&n',
      "Question"
    )
    if u.is_defined(response) and response == 1 then
      vim.fn.delete(target.path, "rf")
      refresh_view()
    end
  end
end

local function add_file_or_dir()
  local current_directory = vim.g.tryptic_state.current.path
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

  refresh_view()
end

local function toggle_cut()
  local target = get_target_under_cursor()
  local index = u.list_index_of(cut_list, function(list_item)
    return target.path == list_item.path
  end)
  if index > -1 then
    table.remove(cut_list, index)
  else
    table.insert(cut_list, target)
  end
  local lines, highlights = tree_to_lines(vim.g.tryptic_state.current.contents)
  float.win_set_lines(
    vim.g.tryptic_state.current.win,
    lines
  )
  float.buf_apply_highlights(0, highlights)
end

local function copy(_target, _destination)
  local target = _target or get_target_under_cursor()

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
    refresh_view()
  end
end

local function jump_cursor_to(path)
  local line_num
  for index, item in ipairs(vim.g.tryptic_state.current.contents.children) do
    if item.path == path then
      line_num = index
      break
    end
  end
  if line_num then
    vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  end
end

local function paste()
  local cursor_target = get_target_under_cursor()
  local destination_dir = u.cond(cursor_target.is_dir, {
    when_true = cursor_target.path,
    when_false = cursor_target.dirname
  })
  local success, result = pcall(function()
    for index, cut_item in ipairs(cut_list) do
      local destination = destination_dir .. '/' .. cut_item.basename
      if cut_item.path ~= destination then
        copy(cut_item, destination)
        delete(cut_item, true)
      end
    end
    jump_cursor_to(destination_dir)
  end)
  if not success then
    -- TODO: Log this at warning level
    log('Failed to paste: ' .. result, 'ERROR')
  end
  cut_list = {}
  refresh_view()
end

local function rename()
  local target = get_target_under_cursor()
  local display_name = u.cond(target.is_dir, {
    when_true = u.trim_last_char(target.display_name),
    when_false = target.display_name
  })
  local response = vim.fn.trim(vim.fn.input(
    'Enter new name for "' .. display_name .. '": '
  ))
  if u.is_defined(response) and response ~= target.display_name then
    vim.fn.rename(target.path, target.basename .. '/' .. response)
    refresh_view()
  end
end

local function jump_to_cwd()
  local current = vim.g.tryptic_state.current
  local cwd = vim.fn.getcwd()
  if current.path == cwd and current.previous_path then
    nav_to(current.previous_path)
  else
    nav_to(cwd)
  end
end

local function help()
  local win = vim.g.tryptic_state.child.win
  float.win_set_title(
    win,
    'Help',
    "󰋗",
    "Directory"
  )
  float.win_set_lines(win, require 'tryptic.help'.help_lines())
end

return {
  toggle_tryptic = toggle_tryptic,
  close_tryptic = close_tryptic,
  nav_to = nav_to,
  jump_to_cwd = jump_to_cwd,
  get_target_under_cursor = get_target_under_cursor,
  edit_file = edit_file,
  setup = setup,
  delete = delete,
  add_file_or_dir = add_file_or_dir,
  copy = copy,
  rename = rename,
  toggle_cut = toggle_cut,
  paste = paste,
  help = help
}
