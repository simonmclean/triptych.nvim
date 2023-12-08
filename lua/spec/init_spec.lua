local init = require 'triptych.init'
local config = require 'triptych.config'
local float = require 'triptych.float'
local autocmds = require 'triptych.autocmds'
local state = require 'triptych.state'
local mappings = require 'triptych.mappings'
local actions = require 'triptych.actions'
local view = require 'triptych.view'
local git = require 'triptych.git'
local diagnostics = require 'triptych.diagnostics'
local event_handlers = require 'triptych.event_handlers'

describe('setup', function()
  it('creates config and keymap for open', function()
    local spy = {}
    _G.triptych_mock_vim = {
      g = {},
      keymap = {
        set = function(mode, key, cmd)
          table.insert(spy, { mode, key, cmd })
        end,
      },
    }
    init.setup {}
    local expected_config = config.create_merged_config {}
    assert.same(expected_config, _G.triptych_mock_vim.g.triptych_config)
    assert.same({ { 'n', expected_config.mappings.open_triptych, ':lua require"triptych".open_triptych()<CR>' } }, spy)
  end)
end)

describe('open_triptych', function()
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

    _G.triptych_mock_vim = {
      g = {
        triptych_config = config.create_merged_config {},
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

    view.refresh_view = function(s, d, g)
      table.insert(spies.view.refresh_view, { s, d, g })
    end

    view.nav_to = function(s, buf_dir, d, g, buf)
      table.insert(spies.view.nav_to, { s, buf_dir, d, g, buf })
    end

    mappings.new = function(s, a)
      table.insert(spies.mappings.new, { s, a })
    end

    float.create_three_floating_windows = function()
      spies.float.create_three_floating_windows = spies.float.create_three_floating_windows + 1
      return { 4, 5, 6 }
    end

    init.open_triptych()

    assert.same({
      { _G.triptych_mock_vim.g.triptych_config, 66 },
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
    assert.same({ { mock_state, 'mock_actions' } }, spies.mappings.new)
    assert.same({ { mock_state, '/hello', 'mock_diagnostic', 'mock_git', '/hello/world' } }, spies.view.nav_to)
  end)

  it('create a close function', function()
    local spies = {
      autocmd_destroy = 0,
      close_floats = {},
      nvim_set_current_win = {},
    }

    _G.triptych_mock_vim = {
      g = {
        triptych_config = config.create_merged_config {},
      },
      api = {
        nvim_buf_get_name = function(_)
          return '/hello/world'
        end,
        nvim_get_current_win = function()
          return 66
        end,
        nvim_set_current_win = function(winid)
          table.insert(spies.nvim_set_current_win, winid)
        end,
      },
      fs = {
        dirname = function(path)
          return vim.fs.dirname(path)
        end,
      },
    }

    local mock_state = {
      opening_win = 9,
      windows = {},
    }

    state.new = function(_, _)
      return mock_state
    end

    git.Git.new = function()
      return 'mock_git'
    end

    diagnostics.new = function()
      return 'mock_diagnostic'
    end

    autocmds.new = function(_, _, _, _)
      return {
        destroy_autocommands = function(_)
          spies.autocmd_destroy = spies.autocmd_destroy + 1
        end,
      }
    end

    actions.new = function(_, _)
      return 'mock_actions'
    end

    view.refresh_view = function(_, _, _) end

    view.nav_to = function(_, _, _, _, _) end

    mappings.new = function(_, _) end

    float.create_three_floating_windows = function()
      return { 4, 5, 6 }
    end

    float.close_floats = function(winids)
      table.insert(spies.close_floats, winids)
    end

    init.open_triptych()

    _G.triptych_mock_vim.g.triptych_close()

    assert.same(1, spies.autocmd_destroy)
    assert.same({ { 4, 5, 6 } }, spies.close_floats)
    assert.same({ 9 }, spies.nvim_set_current_win)
  end)
end)
