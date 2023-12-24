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
  }
  return instance
end

function AutoCommands:destroy_autocommands()
  local vim = _G.triptych_mock_vim or vim
  for _, autocmd in pairs(self.autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

return {
  new = AutoCommands.new,
  au_group = au_group,
}
