---@param State TriptychState
---@param FileReader FileReader
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return nil
local function handle_cursor_moved(State, FileReader, Diagnostics, Git)
  local vim = _G.triptych_mock_vim or vim
  local view = _G.triptych_mock_view or require 'triptych.view'
  local target = view.get_target_under_cursor(State)
  local current_dir = State.windows.current.path
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  if current_dir then
    State.path_to_line_map[current_dir] = line_number
    view.update_child_window(State, FileReader, target, Diagnostics, Git)
  end
end

---@return nil
local function handle_buf_leave()
  vim.g.triptych_close()
end

return {
  handle_cursor_moved = handle_cursor_moved,
  handle_buf_leave = handle_buf_leave,
}
