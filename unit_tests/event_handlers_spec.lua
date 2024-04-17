local event_handlers = require 'triptych.event_handlers'

describe('handle_cursor_moved', function()
  it('makes the expected function calls and updates path_to_line_map', function()
    -- spys
    local get_target_under_cursor_spy = {}
    local set_child_window_target_spy = {}
    local nvim_win_get_cursor_spy = {}

    -- mocks
    local mock_target = { 'mock_target' }
    local mock_state = {
      windows = {
        current = {
          path = 'a/b/c',
        },
      },
      path_to_line_map = {
        ['a/b/c'] = 2,
      },
    }
    _G.triptych_mock_vim = {
      api = {
        nvim_win_get_cursor = function(winid)
          table.insert(nvim_win_get_cursor_spy, winid)
          return { 13 }
        end,
      },
    }
    _G.triptych_mock_view = {
      get_target_under_cursor = function(s)
        table.insert(get_target_under_cursor_spy, s)
        return mock_target
      end,
      set_child_window_target = function(s, f)
        table.insert(set_child_window_target_spy, { s, f })
      end,
    }

    event_handlers.handle_cursor_moved(mock_state)

    assert.same({ 0 }, nvim_win_get_cursor_spy)
    assert.same({ { mock_state, mock_target } }, set_child_window_target_spy)
    assert.same({ mock_state }, get_target_under_cursor_spy)
    assert.same(13, mock_state.path_to_line_map['a/b/c'])
  end)
end)
