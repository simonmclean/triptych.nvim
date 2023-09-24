local au_group = vim.api.nvim_create_augroup('TrypticAutoCmd', { clear = true })
local event_handlers = require 'tryptic.event_handlers'

local AutoCommands = {}

---@param State TrypticState
---@param Diagnostics Diagnostics
---@param GitStatus GitStatus
---@param GitIgnore GitIgnore
---@return AutoCommands
function AutoCommands.new(State, Diagnostics, GitStatus, GitIgnore)
  local vim = _G.tryptic_mock_vim or vim
  local instance = {}
  setmetatable(instance, { __index = AutoCommands })
  instance.autocmds = {
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = au_group,
      callback = function()
        event_handlers.handle_cursor_moved(State, Diagnostics, GitStatus, GitIgnore)
      end,
    }),

    vim.api.nvim_create_autocmd('BufLeave', {
      group = au_group,
      callback = event_handlers.handle_buf_leave,
    }),
  }
  return instance
end

function AutoCommands:create_autocommands() end

function AutoCommands:destroy_autocommands()
  for _, autocmd in pairs(self.autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

return {
  new = AutoCommands.new,
}
