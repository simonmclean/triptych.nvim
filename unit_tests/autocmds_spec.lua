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

describe('AutoCommands.new', function()
  it('creates the expected autocommands', function()
    local autocmd_spy = {}
    local handle_cursor_moved_spy = {}
    local handle_buf_leave_spy = {}
    local nvim_win_get_buf_spy = {}
    _G.triptych_mock_vim = {
      api = {
        nvim_create_autocmd = function(name, config)
          table.insert(autocmd_spy, { name, config })
        end,
        nvim_win_get_buf = function(winid)
          table.insert(nvim_win_get_buf_spy, winid)
        end,
      },
    }
    local event_handlers = {
      handle_cursor_moved = function(state)
        table.insert(handle_cursor_moved_spy, state)
      end,
      handle_buf_leave = function()
        table.insert(handle_buf_leave_spy, {})
      end,
    }
    autocmds.new(event_handlers, mock_state, mock_diagnostic, mock_git)

    -- Test CursorMoved autocommand is created
    local cursor_moved_autocmd = autocmd_spy[1]
    local cursor_moved_autocmd_name = cursor_moved_autocmd[1]
    local cursor_moved_autocmd_config = cursor_moved_autocmd[2]
    assert.equal('CursorMoved', cursor_moved_autocmd_name)
    assert.equal(autocmds.au_group, cursor_moved_autocmd_config.group)

    -- Test BufLeave autocommand is created
    local buf_leave_autocmd = autocmd_spy[2]
    local buf_leave_autocmd_name = buf_leave_autocmd[1]
    local buf_leave_autocmd_config = buf_leave_autocmd[2]
    assert.equal('BufLeave', buf_leave_autocmd_name)
    assert.equal(autocmds.au_group, buf_leave_autocmd_config.group)

    -- Test the CursorMoved callback calls the event handler
    cursor_moved_autocmd_config.callback()
    assert.same({ mock_state }, handle_cursor_moved_spy)

    -- Test the BufLeave callback calls the event handler
    buf_leave_autocmd_config.callback()
    assert.same({ {} }, handle_buf_leave_spy)

    assert.same({ mock_state.windows.current.win, mock_state.windows.current.win }, nvim_win_get_buf_spy)
  end)
end)

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
        nvim_win_get_buf = function(_) end,
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
