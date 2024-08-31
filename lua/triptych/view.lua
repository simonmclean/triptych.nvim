local icons = require 'triptych.icons'
local u = require 'triptych.utils'
local float = require 'triptych.float'
local fs = require 'triptych.fs'
local git = require 'triptych.git'
local diagnostics = require 'triptych.diagnostics'
local autocmds = require 'triptych.autocmds'
local plenary_async = require 'plenary.async'
local syntax_highlighting = require 'triptych.syntax_highlighting'

local M = {}

--- Conditionally filter lines and apply git and diagnostic statuses
---@param path_details PathDetails
---@param show_hidden boolean
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return PathDetails
local function filter_and_encrich_dir_contents(path_details, show_hidden, Diagnostics, Git)
  local filtered_children = u.cond(show_hidden, {
    when_true = path_details.children,
    when_false = function()
      return u.filter(path_details.children, function(child)
        local is_git_ignored = Git and Git:should_ignore(child.display_name, child.is_dir)
        local is_dot_file = string.sub(child.display_name, 1, 1) == '.'
        return not is_git_ignored and not is_dot_file
      end)
    end,
  })

  path_details.children = filtered_children
  path_details.git_status = Git and Git:status_of(path_details.path) or nil
  path_details.diagnostic_status = Diagnostics and Diagnostics:get(path_details.path) or nil

  for index, child in ipairs(path_details.children) do
    path_details.children[index].git_status = Git and Git:status_of(child.path) or nil
    path_details.children[index].diagnostic_status = Diagnostics and Diagnostics:get(child.path) or nil
  end
  return path_details
end

--- Asyncronously read a directory, then publish the results to a User event
---@param path string
---@param show_hidden boolean
---@param win_type WinType
local function read_path_async(path, show_hidden, win_type)
  fs.get_path_details(path, show_hidden, function(path_details)
    autocmds.send_path_read(path_details, win_type)
  end)
end

---Asyncronously read a file, then publish the results to a User event
---@param child_win_buf number
---@param path string
local function read_file_async(child_win_buf, path)
  plenary_async.run(function()
    fs.read_file_async(path, function(err, lines)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
      else
        autocmds.send_file_read(child_win_buf, path, lines)
      end
    end)
  end)
end

---Take a PathDetails and return lines and highlights for an nvim buffer
---@param State TriptychState
---@param path_details PathDetails
---@return string[] # Lines including icons
---@return HighlightDetails[]
local function path_details_to_lines(State, path_details)
  local config_options = vim.g.triptych_config.options
  local icons_enabled = config_options.file_icons.enabled
  local lines = {}
  local highlights = {}

  for _, child in ipairs(path_details.children) do
    local line, highlight_name = u.cond(child.is_dir, {
      when_true = function()
        local icon_length = string.len(config_options.file_icons.directory_icon)
        local highlight = {
          icon = {
            highlight_name = 'Directory',
            length = u.cond(icons_enabled, {
              when_true = icon_length,
              when_false = 0,
            }),
          },
          text = {
            highlight_name = config_options.highlights.directory_names,
            starts = u.cond(icons_enabled, {
              when_true = icon_length,
              when_false = 0,
            }),
          },
        }
        local line = u.cond(icons_enabled, {
          when_true = config_options.file_icons.directory_icon .. ' ' .. child.display_name,
          when_false = child.display_name,
        })
        return line, highlight
      end,
      when_false = function()
        local icon, icon_highlight = u.eval(function()
          local maybe_icon, maybe_highlight = icons.get_icon_by_filetype(child.filetype)
          local highlight = maybe_highlight or 'Comment'
          local fallback_icon = config_options.file_icons.fallback_file_icon
          local icon = maybe_icon or fallback_icon
          return icon, highlight
        end)
        local icon_length = string.len(config_options.file_icons.fallback_file_icon)
        local highlight = {
          icon = {
            highlight_name = icon_highlight,
            length = u.cond(icons_enabled, {
              when_true = icon_length,
              when_false = 0,
            }),
          },
          text = {
            highlight_name = config_options.highlights.file_names,
            starts = u.cond(icons_enabled, {
              when_true = icon_length,
              when_false = 0,
            }),
          },
        }
        local line = u.cond(icons_enabled, {
          when_true = icon .. ' ' .. child.display_name,
          when_false = child.display_name,
        })
        return line, highlight
      end,
    })

    local cut_paths = u.map(State.cut_list, function(value)
      return value.path
    end)

    local copy_paths = u.map(State.copy_list, function(value)
      return value.path
    end)

    -- TODO: Replace these with the state methods
    if u.list_includes(cut_paths, child.path) then
      line = line .. ' (cut)'
    end

    if u.list_includes(copy_paths, child.path) then
      line = line .. ' (copy)'
    end

    table.insert(lines, line)
    table.insert(highlights, highlight_name)
  end

  return lines, highlights
end

---Get the PathDetails that correspond to the path under the cursor
---@param State TriptychState
---@return PathDetails?
function M.get_target_under_cursor(State)
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local contents = State.windows.current.contents
  if contents then
    return contents.children[line_number]
  end
end

---Get a list of PathDetails that correspond to all the paths under the visual selection
---@param State TriptychState
---@return PathDetails[]
function M.get_targets_in_selection(State)
  local from = vim.fn.getpos('v')[2]
  local to = vim.api.nvim_win_get_cursor(0)[1]
  local results = {}
  local paths = State.windows.current.contents.children
  if paths then
    -- need to check min and max to account for the directionality of the visual selection
    for i = math.min(to, from), math.max(to, from), 1 do
      table.insert(results, paths[i])
    end
  end
  return results
end

---Get the line number of a particular path in the buffer
---@param path string
---@param path_details PathDetails
---@return integer
local function line_number_of_path(path, path_details)
  local num = 1
  for i, child in ipairs(path_details) do
    if child.path == path then
      num = i
      break
    end
  end
  return num
end

---Currently just return "(cwd)" if the path == cwd
---@param path string
---@return string?
local function get_title_postfix(path)
  if path == vim.fn.getcwd() then
    return '(cwd)'
  end
end

---@param buf integer
---@param sign_name string
---@param group string
---@param line_num integer
local function place_sign(buf, sign_name, group, line_num)
  -- If the sign isn't defined sign_getdefined will return an empty {}
  if vim.fn.sign_getdefined(sign_name)[1] then
    vim.fn.sign_place(0, group, sign_name, buf, { lnum = line_num })
  end
end

---@param buf integer
---@param children PathDetails
---@param group string # see :h sign-group
---@return nil
local function set_sign_columns(buf, children, group)
  vim.fn.sign_unplace(group)
  for index, entry in ipairs(children) do
    if entry.git_status then
      local sign_name = git.status_to_sign[entry.git_status]
      place_sign(buf, sign_name, group, index)
    end

    if entry.diagnostic_status then
      local sign_name = diagnostics.get_sign(entry.diagnostic_status)
      place_sign(buf, sign_name, group, index)
    end
  end
end

--- On the parent and primary windows, update the title and state, then trigger async directory read
---@param State TriptychState
---@param target_dir string
---@return nil
function M.set_primary_and_parent_window_targets(State, target_dir)

  local focused_win = State.windows.current.win
  local parent_win = State.windows.parent.win
  local child_win = State.windows.child.win

  local focused_title = vim.fs.basename(target_dir)

  local parent_path = vim.fs.dirname(target_dir)
  local parent_title = vim.fs.basename(parent_path)

  float.win_set_title(parent_win, parent_title, '', 'Directory', get_title_postfix(parent_path))
  float.win_set_title(focused_win, focused_title, '', 'Directory', get_title_postfix(target_dir))

  State.windows = {
    parent = {
      path = parent_path,
      contents = nil,
      win = parent_win,
    },
    current = {
      path = target_dir,
      previous_path = State.windows.current.path,
      contents = nil,
      win = focused_win,
    },
    child = { -- This all gets populated by update_child_window
      path = '',
      is_dir = State.windows.child.is_dir,
      contents = nil,
      win = child_win,
    },
  }

  read_path_async(parent_path, State.show_hidden, 'parent')
  read_path_async(target_dir, State.show_hidden, 'primary')
end

--- Set lines for the parent or primary window
---@param State TriptychState
---@param path_details PathDetails
---@param win_type WinType
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return nil
function M.set_parent_or_primary_window_lines(State, path_details, win_type, Diagnostics, Git)

  local state = u.eval(function()
    if win_type == 'parent' then
      return State.windows.parent
    elseif win_type == 'primary' then
      return State.windows.current
    end
    return State.windows.child
  end)

  -- Because of async we may have moved onto a different path
  if path_details.path ~= state.path then
    return nil
  end

  local buf = vim.api.nvim_win_get_buf(state.win)

  local contents = filter_and_encrich_dir_contents(path_details, State.show_hidden, Diagnostics, Git)

  local lines, highlights = path_details_to_lines(State, contents)

  float.win_set_lines(state.win, lines, win_type == 'primary')

  float.buf_apply_highlights(buf, highlights)

  set_sign_columns(buf, contents.children, 'triptych_sign_col_' .. win_type)

  if win_type == 'primary' then
    local line_number = u.eval(function()
      if State.has_initial_cursor_pos_been_set then
        return State.path_to_line_map[path_details.path] or 1
      end
      local opening_buf = vim.api.nvim_win_get_buf(State.opening_win)
      local maybe_opening_buf_name = vim.api.nvim_buf_get_name(opening_buf)
      if maybe_opening_buf_name then
        return line_number_of_path(maybe_opening_buf_name, path_details.children)
      end
      return 1
    end)
    local buf_line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(0, { math.min(line_number, buf_line_count), 0 })
    State.has_initial_cursor_pos_been_set = true
    State.path_to_line_map[path_details.path] = line_number
    State.windows.current.contents = contents
  elseif win_type == 'parent' then
    local line_number = line_number_of_path(State.windows.current.path, contents.children)
    vim.api.nvim_win_set_cursor(state.win, { line_number, 0 })
    State.path_to_line_map[State.windows.parent.path] = line_number
    State.windows.parent.contents = contents
  end
end

---In the child/preview window, update the title and state, then trigger async directory or file read
---@param State TriptychState
---@param path_details PathDetails
---@return nil
function M.set_child_window_target(State, path_details)
  local buf = vim.api.nvim_win_get_buf(State.windows.child.win)

  -- TODO: Can we make path_details mandatory to avoid the repeated checks

  vim.api.nvim_buf_set_var(
    buf,
    'triptych_path',
    u.cond(path_details == nil, {
      when_true = nil,
      when_false = function()
        return path_details.path
      end,
    })
  )

  State.windows.child.is_dir = u.cond(path_details == nil, {
    when_true = false,
    when_false = function()
      return path_details.is_dir
    end,
  })

  State.windows.child.path = u.cond(path_details == nil, {
    when_true = nil,
    when_false = function()
      return path_details.path
    end,
  })

  if path_details == nil then
    float.win_set_title(State.windows.child.win, '[empty directory]')
    float.buf_set_lines(buf, {})
  elseif path_details.is_dir then
    syntax_highlighting.stop(buf)
    float.win_set_title(
      State.windows.child.win,
      path_details.display_name,
      '',
      'Directory',
      get_title_postfix(path_details.path)
    )
    read_path_async(path_details.path, State.show_hidden, 'child')
  else
    local filetype = fs.get_filetype_from_path(path_details.path) -- TODO: De-dupe this
    local icon, highlight = icons.get_icon_by_filetype(filetype)
    float.win_set_title(State.windows.child.win, path_details.display_name, icon, highlight)
    float.buf_set_lines(buf, {})
    local file_size = fs.get_file_size_in_kb(path_details.path)
    if file_size < 300 then
      read_file_async(buf, path_details.path)
    else
      local msg = '[File size too large to preview]'
      float.buf_set_lines(buf, { msg })
    end
  end
end

--- Set lines for the child/preview window
---@param State TriptychState
---@param path_details PathDetails
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return nil
function M.set_child_window_lines(State, path_details, Diagnostics, Git)
  local buf = vim.api.nvim_win_get_buf(State.windows.child.win)

  -- Because of async we may have moved onto a different path
  if path_details.path ~= State.windows.child.path then
    return nil
  end

  if path_details.is_dir then
    local contents = filter_and_encrich_dir_contents(path_details, State.show_hidden, Diagnostics, Git)
    local lines, highlights = path_details_to_lines(State, contents)
    vim.treesitter.stop(buf)
    vim.api.nvim_buf_set_option(buf, 'syntax', 'off')
    float.buf_set_lines(buf, lines)
    float.buf_apply_highlights(buf, highlights)
    set_sign_columns(buf, contents.children, 'triptych_sign_col_child')
  else
    local ft = fs.get_filetype_from_path(path_details.path)
    syntax_highlighting.stop(buf)
    float.buf_set_lines(buf, {})
    if vim.g.triptych_config.options.syntax_highlighting.enabled then
      syntax_highlighting.start(buf, ft)
    end
  end
end

---@param State TriptychState
---@param path string
---@return nil
function M.jump_cursor_to(State, path)
  local line_num
  for index, item in ipairs(State.windows.current.contents.children) do
    if item.path == path then
      line_num = index
      break
    end
  end
  if line_num then
    vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  end
end

---@param State TriptychState
---@return nil
function M.refresh_view(State)
  M.set_primary_and_parent_window_targets(State, State.windows.current.path)
end

return M
