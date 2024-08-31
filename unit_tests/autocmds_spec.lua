local autocmds = require 'triptych.autocmds'

local mock_state = {
  windows = {
    current = {
      win = 4,
    },
  },
}
local mock_diagnostic = { 'mock_diagnostic' }
local mock_git = { 'mock_git' }

describe('AutoCommands:destroy_autocommands', function()
  it('destroys the autocommands', function()
    local spy = {}
    local i = 0
    _G.triptych_mock_vim = {
      api = {
        nvim_create_autocmd = function(_, _)
          i = i + 1
          return i
        end,
        nvim_del_autocmd = function(id)
          table.insert(spy, id)
        end,
        nvim_win_get_buf = function(_)
          return 4
        end,
      },
    }
    local event_handlers = {
      handle_cursor_moved = function(_, _, _) end,
      handle_buf_leave = function() end,
    }
    local AutoCmds = autocmds.new(event_handlers, mock_state, mock_diagnostic, mock_git)
    AutoCmds:destroy_autocommands()
    assert.same({ 1, 2, 3, 4 }, spy)
  end)
end)
