local au_group = vim.api.nvim_create_augroup('TrypticAutoCmd', { clear = true })
local event_handlers = require 'tryptic.event_handlers'

local AutoCommands = {}

---@return AutoCommands
function AutoCommands.new(state)
  local instance = {}
  setmetatable(instance, { __index = AutoCommands })
  instance.state = state
  instance.autocmds = {
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = au_group,
      callback = function()
        event_handlers.handle_cursor_moved(instance.state)
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
