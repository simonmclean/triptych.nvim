local u = require 'triptych.utils'
local float = require 'triptych.float'

local M = {}

---When the cursor has moved trigger an update of the child/preview window
---@param State TriptychState
---@return nil
function M.handle_cursor_moved(State)
  local vim = _G.triptych_mock_vim or vim
  local view = _G.triptych_mock_view or require 'triptych.view'
  local target = view.get_target_under_cursor(State)
  local current_dir = State.windows.current.path
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  State.path_to_line_map[current_dir] = line_number
  if target then
    view.set_child_window_target(State, target)
  end
end

---Get the line number of a particular path in the buffer
---@param path string
---@param path_details PathDetails[]
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

--Handles the result of a directroy read
---@param State TriptychState
---@param path_details PathDetails
---@param win_type WinType
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return nil
function M.handle_dir_read(State, path_details, win_type, Diagnostics, Git)
  local vim = _G.triptych_mock_vim or vim
  local view = _G.triptych_mock_view or require 'triptych.view'
  view.set_parent_or_primary_window_lines(State, path_details, win_type, Diagnostics, Git)

  -- Set cursor position
  local maybe_cached_line_num = State.path_to_line_map[path_details.path]
  -- Handle new Triptych session
  if win_type == 'primary' and u.is_empty(State.path_to_line_map) then
    local opening_buf = vim.api.nvim_win_get_buf(State.opening_win)
    local maybe_opening_buf_name = vim.api.nvim_buf_get_name(opening_buf)
    if maybe_opening_buf_name then
      local line_num = line_number_of_path(maybe_opening_buf_name, path_details.children)
      vim.api.nvim_win_set_cursor(State.windows.current.win, { line_num or 1, 0 })
      if line_num then
        -- Cache this line number
        State.path_to_line_map[path_details.path] = line_num
      end
    end
  elseif win_type == 'primary' and maybe_cached_line_num then
    local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(State.windows.current.win))
    vim.api.nvim_win_set_cursor(State.windows.current.win, { math.min(line_count, maybe_cached_line_num), 0 })
  elseif win_type == 'primary' and State.windows.current.previous_path then
    local line_num = line_number_of_path(State.windows.current.previous_path, path_details.children)
    vim.api.nvim_win_set_cursor(State.windows.current.win, { line_num or 1, 0 })
  elseif win_type == 'parent' then
    local line_num = line_number_of_path(State.windows.current.path, path_details.children)
    vim.api.nvim_win_set_cursor(State.windows.parent.win, { line_num or 1, 0 })
  end
end

---Handle the result of a file read
---@param child_win_buf number
---@param path string
---@param lines string[]
function M.handle_file_read(child_win_buf, path, lines)
  float.set_child_window_file_preview(child_win_buf, path, lines)
end

---@return nil
function M.handle_buf_leave()
  vim.g.triptych_close()
end

return M
