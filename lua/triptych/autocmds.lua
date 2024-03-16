local au_group = vim.api.nvim_create_augroup('TriptychAutoCmd', { clear = true })

local AutoCommands = {}

---@param event_handlers any
---@param State TriptychState
---@param FileReader FileReader
---@param Diagnostics? Diagnostics
---@param Git? Git
---@return AutoCommands
function AutoCommands.new(event_handlers, FileReader, State, Diagnostics, Git)
  local vim = _G.triptych_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = AutoCommands })

  instance.autocmds = {
    -- TODO: Should I be using nvim_create_user_autocommand instead?...
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = au_group,
      callback = function()
        event_handlers.handle_cursor_moved(State, FileReader, Diagnostics, Git)
      end,
    }),

    vim.api.nvim_create_autocmd('BufLeave', {
      group = au_group,
      callback = event_handlers.handle_buf_leave,
    }),

    vim.api.nvim_create_autocmd('User', {
      group = au_group,
      pattern = 'TriptychPathRead',
      callback = function(data)
        event_handlers.handle_path_read(State, data.data.path_details, data.data.win_type, FileReader, Diagnostics, Git)
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

return {
  new = AutoCommands.new,
  send_path_read = send_path_read,
  au_group = au_group,
}
