local mappings = require 'triptych.mappings'
local triptych_config = require 'triptych.config'
local view = require 'triptych.view'
local u = require 'triptych.utils'

describe('new', function()
  it('sets up the expected key bindings', function()
    local mock_state = {}
    local mock_actions = {}
    local mock_refresh = function() end

    local spies = {
      keymap_set = {},
      triptych_close = {},
      triptych_get_state = {},
      isdirectory = {},
      view = {
        nav_to = {},
        get_target_under_cursor = {},
        jump_to_cwd = {},
      },
    }

    _G.triptych_mock_vim = {
      g = {
        triptych_config = triptych_config.create_merged_config {},
        triptych_close = function()
          table.insert(spies.triptych_close, nil)
        end,
        triptych_get_state = function()
          table.insert(spies.triptych_get_state, nil)
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

    view.set_primary_and_parent_window_targets = function(state, parent_path, diagnostics, git, focused_path)
      table.insert(spies.view.nav_to, { state, parent_path, diagnostics, git, focused_path })
    end
    view.jump_to_cwd = function(state, diagnostics, git)
      table.insert(spies.view.jump_to_cwd, { state, diagnostics, git })
    end
    view.get_target_under_cursor = function(state)
      table.insert(spies.view.get_target_under_cursor, state)
    end

    mappings.new(mock_state, mock_actions, mock_refresh)

    local assert_mapping = function(name, mode)
      local results = u.filter(spies.keymap_set, function(entry)
        return entry[2] == _G.triptych_mock_vim.g.triptych_config.mappings[name]
      end)
      assert.same(1, #results)
      local result = results[1]
      assert.same(mode, result[1])
      assert.same({ buffer = 0, nowait = true }, result[4])
    end

    assert_mapping('nav_left', 'n')
  end)

  it('sets up extension mappings', function()
    local spies = {
      keymap_set = {},
      get_target_under_cursor = {},
      ext_fn = {},
    }
    _G.triptych_mock_vim = {
      g = {
        triptych_config = triptych_config.create_merged_config {
          extension_mappings = {
            ['<leader>xxx'] = {
              mode = 'v',
              fn = function(target)
                table.insert(spies.ext_fn, target)
              end,
            },
          },
        },
      },
      keymap = {
        set = function(mode, key_binding, fn, config)
          table.insert(spies.keymap_set, { mode, key_binding, fn, config })
        end,
      },
    }
    local mock_state = { 'mock_state' } ---@as TriptychState
    local mock_target = { 'mock_target' } ---@as PathDetails
    local mock_refresh = function() end
    view.get_target_under_cursor = function(s)
      table.insert(spies.get_target_under_cursor, s)
      return mock_target
    end

    ---@diagnostic disable-next-line: missing-fields
    mappings.new(mock_state, {}, mock_refresh)
    local ext_mapping_index = u.list_index_of(spies.keymap_set, function(entry)
      return entry[2] == '<leader>xxx'
    end)
    local ex_mapping = spies.keymap_set[ext_mapping_index]
    assert.same(ex_mapping[1], 'v')
    assert.same(ex_mapping[2], '<leader>xxx')
    ex_mapping[3]() -- Run the mapped function
    assert.same({ mock_state }, spies.get_target_under_cursor)
    assert.same({ mock_target }, spies.ext_fn)
  end)
end)
