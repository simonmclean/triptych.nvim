local mappings = require 'tryptic.mappings'
local tryptic_config = require 'tryptic.config'
local view = require 'tryptic.view'
local u = require 'tryptic.utils'

describe('new', function()
  it('sets up the expected key bindings', function()
    local mock_state = {}
    local mock_actions = {}
    local mock_diagnostics = {}
    local mock_git = {}

    local spies = {
      keymap_set = {},
      tryptic_close = {},
      tryptic_get_state = {},
      isdirectory = {},
      view = {
        nav_to = {},
        get_target_under_cursor = {},
        jump_to_cwd = {},
      },
    }

    _G.tryptic_mock_vim = {
      g = {
        tryptic_config = tryptic_config.create_merged_config(),
        tryptic_close = function()
          table.insert(spies.tryptic_close, nil)
        end,
        tryptic_get_state = function()
          table.insert(spies.tryptic_get_state, nil)
        end,
      },
      keymap = {
        set = function(mode, key_binding, fn, config)
          table.insert(spies.keymap_set, { mode, key_binding, fn, config })
        end,
      },
      fn = {
        isdirectory = function(path)
          table.insert(spies.isdirectory, path)
          return false
        end,
      },
    }

    view = {
      nav_to = function(state, parent_path, diagnostics, git, focused_path)
        table.insert(spies.view.nav_to, { state, parent_path, diagnostics, git, focused_path })
      end,
      jump_to_cwd = function (state, diagnostics, git)
        table.insert(spies.view.jump_to_cwd, { state, diagnostics, git })
      end,
      get_target_under_cursor = function (state)
        table.insert(spies.view.get_target_under_cursor, state)
      end
    }

    mappings.new(mock_state, mock_actions, mock_diagnostics, mock_git)

    local assert_mapping = function (name, mode)
      local results = u.filter(spies.keymap_set, function (entry)
        return entry[2] == _G.tryptic_mock_vim.g.tryptic_config.mappings[name]
      end)
      assert.same(1, #results)
      local result = results[1]
      assert.same(mode, result[1])
      assert.same({ buffer = 0 }, result[4])
    end

    assert_mapping('nav_left', 'n')
  end)
end)
