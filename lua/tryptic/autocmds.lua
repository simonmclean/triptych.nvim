local handlers = require 'tryptic.event_handlers'

local au_group = vim.api.nvim_create_augroup("TrypticAutoCmd", { clear = true })

local __autocommands = {}

local function create_autocommands()
  local a = vim.api.nvim_create_autocmd('CursorMoved', {
    group = au_group,
    callback = function()
      handlers.handle_cursor_moved()
    end
  })

  local b = vim.api.nvim_create_autocmd('BufLeave', {
    group = au_group,
    callback = handlers.handle_buf_leave
  })

  __autocommands = { a, b }
end

local function destroy_autocommands()
  for _, autocmd in pairs(__autocommands) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

return {
  create_autocommands = create_autocommands,
  destroy_autocommands = destroy_autocommands
}
