local view = require 'tryptic.view'
local git = require 'tryptic.git'

---@param state TrypticState
---@return nil
local function handle_cursor_moved(state)
  local target = view.get_target_under_cursor(state)
  local current_dir = state.windows.current.path
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  if current_dir then
    state.path_to_line_map[current_dir] = line_number
    view.update_child_window(state, target, git.git_ignore())
  end
end

---@return nil
local function handle_buf_leave()
  vim.g.tryptic_close()
end

return {
  handle_cursor_moved = handle_cursor_moved,
  handle_buf_leave = handle_buf_leave,
}
