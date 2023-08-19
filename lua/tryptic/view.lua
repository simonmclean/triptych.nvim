local u = require 'tryptic.utils'
local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')
local float = require 'tryptic.float'
local state = require 'tryptic.state'
local fs = require 'tryptic.fs'

local function tree_to_lines(tree)
  local lines = {}
  local highlights = {}

  for _, child in ipairs(tree.children) do
    local line, highlight_name = u.cond(child.is_dir, {
      when_true = function()
        local line = ''
        if devicons_installed then
          line = line .. ' '
        end
        line = line .. child.display_name
        return line, 'Directory'
      end,
      when_false = function()
        if devicons_installed then
          local maybe_icon, maybe_highlight = devicons.get_icon_by_filetype(child.filetype)
          local highlight = maybe_highlight or 'Comment'
          local fallback_icon = ''
          local icon = maybe_icon or fallback_icon
          local line = icon .. ' ' .. child.display_name
          return line, highlight
        end
        return child.display_name
      end,
    })

    local cut_paths = u.eval(function()
      local paths = {}
      for _, cut_item in ipairs(state.cut_list.get()) do
        table.insert(paths, cut_item.path)
      end
      return paths
    end)

    if u.list_includes(cut_paths, child.path) then
      line = line .. ' (cut)'
    end

    table.insert(lines, line)
    table.insert(highlights, highlight_name)
  end

  return lines, highlights
end

local function get_target_under_cursor()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return state.view_state.get().current.contents.children[line_number]
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

local function get_title_postfix(path)
  if path == vim.fn.getcwd() then
    return '(cwd)'
  end
end

local function nav_to(target_dir, cursor_target)
  local view_state = state.view_state.get()

  local focused_win = view_state.current.win
  local parent_win = view_state.parent.win
  local child_win = view_state.child.win

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

  float.win_set_title(parent_win, parent_title, '', 'Directory', get_title_postfix(parent_path))
  float.win_set_title(focused_win, focused_title, '', 'Directory', get_title_postfix(target_dir))

  float.buf_apply_highlights(focused_buf, focused_highlights)
  float.buf_apply_highlights(parent_buf, parent_highlights)

  local focused_win_line_number = u.cond(cursor_target, {
    when_true = function()
      return index_of_path(cursor_target, focused_contents.children)
    end,
    when_false = state.path_to_line_map.get(target_dir) or 1,
  })
  local buf_line_count = vim.api.nvim_buf_line_count(focused_buf)
  vim.api.nvim_win_set_cursor(0, { math.min(focused_win_line_number, buf_line_count), 0 })

  local parent_win_line_number = index_of_path(target_dir, parent_contents.children)
  vim.api.nvim_win_set_cursor(parent_win, { parent_win_line_number, 0 })

  state.view_state.set {
    parent = {
      path = parent_path,
      contents = parent_contents,
      win = parent_win,
    },
    current = {
      path = target_dir,
      previous_path = view_state.current.path,
      contents = focused_contents,
      win = focused_win,
    },
    child = {
      path = nil,
      contents = nil,
      lines = nil,
      win = child_win,
    },
  }
end

local function jump_to_cwd()
  local current = state.view_state.get().current
  local cwd = vim.fn.getcwd()
  if current.path == cwd and current.previous_path then
    nav_to(current.previous_path)
  else
    nav_to(cwd)
  end
end

local function update_child_window(target)
  local buf = vim.api.nvim_win_get_buf(state.view_state.get().child.win)

  state.view_state.get().child.path = u.cond(target == nil, {
    when_true = nil,
    when_false = function()
      return target.path
    end,
  })

  if target == nil then
    float.win_set_title(state.view_state.get().child.win, '[empty directory]')
    float.buf_set_lines(buf, {})
  elseif target.is_dir then
    float.win_set_title(
      state.view_state.get().child.win,
      target.basename,
      '',
      'Directory',
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
      end,
    })
    float.win_set_title(state.view_state.get().child.win, target.basename, icon, highlight)
    float.buf_set_lines_from_path(buf, target.path)
  end
end

local function jump_cursor_to(path)
  local line_num
  for index, item in ipairs(state.view_state.get().current.contents.children) do
    if item.path == path then
      line_num = index
      break
    end
  end
  if line_num then
    vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  end
end

local function refresh_view()
  -- TODO: This an inefficient way of refreshing the view
  nav_to(state.view_state.get().current.path)
end

return {
  tree_to_lines = tree_to_lines,
  refresh_view = refresh_view,
  jump_cursor_to = jump_cursor_to,
  update_child_window = update_child_window,
  get_target_under_cursor = get_target_under_cursor,
  jump_to_cwd = jump_to_cwd,
  nav_to = nav_to,
}
