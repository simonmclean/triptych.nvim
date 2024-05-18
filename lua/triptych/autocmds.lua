local au_group = vim.api.nvim_create_augroup('TriptychAutoCmd', { clear = true })

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
      group = au_group,
      buffer = vim.api.nvim_win_get_buf(State.windows.current.win),
      callback = function()
        event_handlers.handle_cursor_moved(State)
      end,
    }),

    vim.api.nvim_create_autocmd('BufLeave', {
      group = au_group,
      buffer = vim.api.nvim_win_get_buf(State.windows.current.win),
      callback = event_handlers.handle_buf_leave,
    }),

    -- User autocmd for asynchronously handling the result a directory read
    vim.api.nvim_create_autocmd('User', {
      group = au_group,
      pattern = 'TriptychPathRead',
      callback = function(data)
        event_handlers.handle_dir_read(State, data.data.path_details, data.data.win_type, Diagnostics, Git)
      end,
    }),

    -- User autocmd for asynchronously handling the result a file read
    vim.api.nvim_create_autocmd('User', {
      group = au_group,
      pattern = 'TriptychFileRead',
      callback = function(data)
        event_handlers.handle_file_read(data.data.child_win_buf, data.data.path, data.data.lines)
      end,
    }),
  }

  return instance
end

function AutoCommands:destroy_autocommands()
  local vim = _G.triptych_mock_vim or vim
  for _, autocmd in pairs(self.autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

---Publish the results of an async directory read
---@param path_details PathDetails
---@param win_type WinType
---@return nil
local function send_path_read(path_details, win_type)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', {
      group = au_group,
      pattern = 'TriptychPathRead',
      data = {
        path_details = path_details,
        win_type = win_type,
      },
    })
  end)
end

---Publish the results of an async file read
---@param child_win_buf number
---@param path string
---@param lines string[]
---@return nil
local function send_file_read(child_win_buf, path, lines)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', {
      group = au_group,
      pattern = 'TriptychFileRead',
      data = {
        child_win_buf = child_win_buf,
        path = path,
        lines = lines,
      },
    })
  end)
end

return {
  new = AutoCommands.new,
  send_path_read = send_path_read,
  send_file_read = send_file_read,
  au_group = au_group,
}
