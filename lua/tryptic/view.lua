local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')
local u = require 'tryptic.utils'
local float = require 'tryptic.float'
local state = require 'tryptic.state'
local fs = require 'tryptic.fs'
local git = require 'tryptic.git'
local diagnostics = require 'tryptic.diagnostics'

-- TODO: Rename tree_to_lines as it doesn't take a tree

---Take a DirContents and return lines and highlights for an nvim buffer
---@param tree DirContents
---@return string[] # Lines including icons
---@return string[] # Highlights for icons
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

---Get the DirContents that correspond to the path under the cursor
---@return DirContents
local function get_target_under_cursor()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return state.view_state.get().current.contents.children[line_number]
end

---Get a list of DirContents that correspond to all the paths under the visual selection
---@return DirContents[]
local function get_targets_in_selection()
  local from = vim.fn.getpos('v')[2]
  local to = vim.api.nvim_win_get_cursor(0)[1]
  local results = {}
  local paths = state.view_state.get().current.contents.children
  if paths then
    -- need to check min and max to account for the directionality of the visual selection
    for i = math.min(to, from), math.max(to, from), 1 do
      table.insert(results, paths[i])
    end
  end
  return results
end

-- TODO: Rename to line number? Also the params

---Get the line number of a particular path in the buffer
---@param path string
---@param paths_list DirContents
---@return integer
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

---Currently just return "(cwd)" if the path == cwd
---@param path string
---@return string?
local function get_title_postfix(path)
  if path == vim.fn.getcwd() then
    return '(cwd)'
  end
end

---@param buf integer
---@param children DirContents
---@param group string # see :h sign-group
---@return nil
local function set_sign_columns(buf, children, group)
  vim.fn.sign_unplace(group)
  for index, entry in ipairs(children) do
    -- TODO: De-dupe code below
    if entry.git_status then
      local sign_name = git.get_sign(entry.git_status)
      -- If the sign isn't defined sign_getdefined will return an empty {}
      if vim.fn.sign_getdefined(sign_name)[1] then
        vim.fn.sign_place(0, group, sign_name, buf, { lnum = index })
      end
    end

    if entry.diagnostic_status then
      local sign_name = diagnostics.get_sign(entry.diagnostic_status)
      -- If the sign isn't defined sign_getdefined will return an empty {}
      if vim.fn.sign_getdefined(sign_name)[1] then
        vim.fn.sign_place(0, group, sign_name, buf, { lnum = index })
      end
    end
  end
end

---@param target_dir string full path
---@param cursor_target? string full path
---@return nil
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

  set_sign_columns(focused_buf, focused_contents.children, 'tryptic_sign_col_focused')
  set_sign_columns(parent_buf, parent_contents.children, 'tryptic_sign_col_parent')

  float.win_set_title(parent_win, parent_title, '', 'Directory', get_title_postfix(parent_path))
  float.win_set_title(focused_win, focused_title, '', 'Directory', get_title_postfix(target_dir))

  float.buf_apply_highlights(focused_buf, focused_highlights)
  float.buf_apply_highlights(parent_buf, parent_highlights)

  ---@type integer
  local focused_win_line_number = u.cond(cursor_target, {
    when_true = function()
      return index_of_path(cursor_target --[[@as string]], focused_contents.children)
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
      path = '',
      contents = nil,
      lines = nil,
      win = child_win,
    },
  }
end

---@return nil
local function jump_to_cwd()
  local current = state.view_state.get().current
  local cwd = vim.fn.getcwd()
  if current.path == cwd and current.previous_path then
    nav_to(current.previous_path)
  else
    nav_to(cwd)
  end
end

---@param target DirContents
---@return nil
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
    local contents = fs.list_dir_contents(target.path)
    local lines, highlights = tree_to_lines(contents)
    float.buf_set_lines(buf, lines)
    float.buf_apply_highlights(buf, highlights)
    set_sign_columns(buf, contents.children, 'tryptic_sign_col_child')
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

---@param path DirContents
---@return nil
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

---@return nil
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
  get_targets_in_selection = get_targets_in_selection,
  jump_to_cwd = jump_to_cwd,
  nav_to = nav_to,
}
