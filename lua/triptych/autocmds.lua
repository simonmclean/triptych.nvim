local au_group_internal = vim.api.nvim_create_augroup('TriptychEventsInternal', { clear = true })
local au_group_public = vim.api.nvim_create_augroup('TriptychEvents', { clear = true })

local M = {}

local AutoCommands = {}

---@param event_handlers any
---@param State TriptychState
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return AutoCommands
function AutoCommands.new(event_handlers, State, Diagnostics, Git)
  local vim = _G.triptych_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = AutoCommands })

  instance.autocmds = {
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = au_group_internal,
      buffer = vim.api.nvim_win_get_buf(State.windows.current.win),
      callback = function()
        event_handlers.handle_cursor_moved(State)
      end,
    }),

    vim.api.nvim_create_autocmd('BufLeave', {
      group = au_group_internal,
      buffer = vim.api.nvim_win_get_buf(State.windows.current.win),
      callback = event_handlers.handle_buf_leave,
    }),

    -- User autocmd for asynchronously handling the result a directory read
    vim.api.nvim_create_autocmd('User', {
      group = au_group_internal,
      pattern = 'TriptychPathRead',
      callback = function(data)
        event_handlers.handle_dir_read(State, data.data.path_details, data.data.win_type, Diagnostics, Git)
      end,
    }),

    -- User autocmd for asynchronously handling the result a file read
    vim.api.nvim_create_autocmd('User', {
      group = au_group_internal,
      pattern = 'TriptychFileRead',
      callback = function(data)
        event_handlers.handle_file_read(data.data.child_win_buf, data.data.path, data.data.lines)
      end,
    }),
  }

  return instance
end

M.new = AutoCommands.new

function AutoCommands:destroy_autocommands()
  local vim = _G.triptych_mock_vim or vim
  for _, autocmd in pairs(self.autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

---@param group string
---@param pattern string
---@param schedule boolean
---@param data? any
local function exec_autocmd(group, pattern, schedule, data)
  local exec = function()
    vim.api.nvim_exec_autocmds('User', {
      group = group,
      pattern = pattern,
      data = data,
    })
  end
  if schedule then
    vim.schedule(exec)
  else
    exec()
  end
end

---@param pattern string
---@param data any
local function exec_internal_autocmd(pattern, data)
  exec_autocmd(au_group_internal, pattern, true, data)
end

---@param pattern string
---@param data? table
local function exec_public_autocmd(pattern, data)
  exec_autocmd(au_group_public, pattern, false, data)
end

---Publish the results of an async directory read
---@param path_details PathDetails
---@param win_type WinType
---@return nil
function M.send_path_read(path_details, win_type)
  exec_internal_autocmd('TriptychPathRead', {
    path_details = path_details,
    win_type = win_type,
  })
end

---Publish the results of an async file read
---@param child_win_buf number
---@param path string
---@param lines string[]
---@return nil
function M.send_file_read(child_win_buf, path, lines)
  exec_internal_autocmd('TriptychFileRead', {
    child_win_buf = child_win_buf,
    path = path,
    lines = lines,
  })
end

-- NOTE: "publish" functions are intended as public hooks.
-- Don't use these to add any internal logic (like with the "send" functions)

function M.publish_did_close()
  exec_public_autocmd 'TriptychDidClose'
end

---@param win_type WinType
function M.publish_did_update_window(win_type)
  exec_public_autocmd('TriptychDidUpdateWindow', {
    win_type = win_type
  })
end

---@param path string
function M.publish_will_delete_node(path)
  exec_public_autocmd('TriptychWillDeleteNode', {
    path = path,
  })
end

---@param path string
function M.publish_did_delete_node(path)
  exec_public_autocmd('TriptychDidDeleteNode', {
    path = path,
  })
end

---@param path string
function M.publish_will_create_node(path)
  exec_public_autocmd('TriptychWillCreateNode', {
    path = path,
  })
end

---@param path string
function M.publish_did_create_node(path)
  exec_public_autocmd('TriptychDidCreateNode', {
    path = path,
  })
end

---@param from_path string
---@param to_path string
function M.publish_will_move_node(from_path, to_path)
  exec_public_autocmd('TriptychWillMoveNode', {
    from_path = from_path,
    to_path = to_path,
  })
end

---@param from_path string
---@param to_path string
function M.publish_did_move_node(from_path, to_path)
  exec_public_autocmd('TriptychDidMoveNode', {
    from_path = from_path,
    to_path = to_path,
  })
end

return M
