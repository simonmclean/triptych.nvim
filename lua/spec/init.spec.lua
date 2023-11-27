local init = require 'tryptic.init'
local config = require 'tryptic.config'
local float = require 'tryptic.float'
local autocmds = require 'tryptic.autocmds'
local state = require 'tryptic.state'
local mappings = require 'tryptic.mappings'
local actions = require 'tryptic.actions'
local view = require 'tryptic.view'
local git = require 'tryptic.git'
local diagnostics = require 'tryptic.diagnostics'
local event_handlers = require 'tryptic.event_handlers'

describe('setup', function()
  it('creates config and keymap for open', function()
    local spy = {}
    _G.tryptic_mock_vim = {
      g = {},
      keymap = {
        set = function(mode, key, cmd)
          table.insert(spy, { mode, key, cmd })
        end,
      },
    }
    init.setup {}
    local expected_config = config.create_merged_config {}
    assert.same(expected_config, _G.tryptic_mock_vim.g.tryptic_config)
    assert.same({ { 'n', expected_config.mappings.open_tryptic, ':lua require"tryptic".open_tryptic()<CR>' } }, spy)
  end)
end)

describe('open_tryptic', function()
  -- TODO: Test the close and refresh functions
  it('makes the expected calls', function()
    local spies = {
      state = {
        new = {},
      },
      git = {
        new = 0,
      },
      diagnostics = {
        new = 0,
      },
      float = {
        create_three_floating_windows = 0,
      },
      autocmds = {
        new = {},
      },
      actions = {
        new = {},
      },
      mappings = {
        new = {},
      },
      view = {
        refresh_view = {},
        nav_to = {},
      },
      vim = {
        api = {
          nvim_buf_get_name = {},
          nvim_get_current_win = 0,
          nvim_set_current_win = {},
        },
        fs = {
          dirname = {},
        },
      },
    }

    _G.tryptic_mock_vim = {
      g = {
        tryptic_config = config.create_merged_config {},
      },
      api = {
        nvim_buf_get_name = function(bufid)
          table.insert(spies.vim.api.nvim_buf_get_name, bufid)
          return '/hello/world'
        end,
        nvim_get_current_win = function()
          spies.vim.api.nvim_get_current_win = spies.vim.api.nvim_get_current_win + 1
          return 66
        end,
        nvim_set_current_win = function(winid)
          table.insert(spies.vim.api.nvim_set_current_win, winid)
        end,
      },
      fs = {
        dirname = function(path)
          table.insert(spies.vim.fs.dirname, path)
          return vim.fs.dirname(path)
        end,
      },
    }

    local mock_state = {
      windows = {},
    }

    state.new = function(conf, opening_winid)
      table.insert(spies.state.new, { conf, opening_winid })
      return mock_state
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    git.Git.new = function()
      spies.git.new = spies.git.new + 1
      return 'mock_git'
    end

    diagnostics.new = function()
      spies.diagnostics.new = spies.diagnostics.new + 1
      return 'mock_diagnostic'
    end

    autocmds.new = function(h, s, d, g)
      table.insert(spies.autocmds.new, { h, s, d, g })
      return 'mock_autocmds'
    end

    actions.new = function(_state, refresh_fn)
      table.insert(spies.actions.new, { _state, refresh_fn })
      return 'mock_actions'
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    view.refresh_view = function(s, d, g)
      table.insert(spies.view.refresh_view, { s, d, g })
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    view.nav_to = function(s, buf_dir, d, g, buf)
      table.insert(spies.view.nav_to, { s, buf_dir, d, g, buf })
    end

    mappings.new = function(s, a, d, g)
      table.insert(spies.mappings.new, { s, a, d, g })
    end

    float.create_three_floating_windows = function()
      spies.float.create_three_floating_windows = spies.float.create_three_floating_windows + 1
      return { 4, 5, 6 }
    end

    init.open_tryptic()

    assert.same({
      { _G.tryptic_mock_vim.g.tryptic_config, 66 },
    }, spies.state.new)
    assert.same(1, spies.git.new)
    assert.same(1, spies.diagnostics.new)
    assert.same({ 0 }, spies.vim.api.nvim_buf_get_name)
    assert.same({ '/hello/world' }, spies.vim.fs.dirname)
    assert.same(1, spies.float.create_three_floating_windows)
    assert.same({
      windows = {
        parent = {
          path = '',
          win = 4,
        },
        current = {
          path = '',
          previous_path = '',
          win = 5,
        },
        child = {
          win = 6,
        },
      },
    }, mock_state)
    assert.same({ { event_handlers, mock_state, 'mock_diagnostic', 'mock_git' } }, spies.autocmds.new)
    assert.same(mock_state, spies.actions.new[1][1])
    assert.same({ { mock_state, 'mock_actions', 'mock_diagnostic', 'mock_git' } }, spies.mappings.new)
    assert.same({ { mock_state, '/hello', 'mock_diagnostic', 'mock_git', '/hello/world' } }, spies.view.nav_to)
  end)
end)
