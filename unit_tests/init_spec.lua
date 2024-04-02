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
local file_reader = require 'triptych.file_reader'

describe('setup', function()
  it('creates config and Triptych command', function()
    local spies = {
      fn = {
        has = {},
      },
      api = {
        nvim_create_user_command = {},
      },
    }
    _G.triptych_mock_vim = {
      g = {},
      fn = {
        has = function(str)
          table.insert(spies.fn.has, str)
          return 1
        end,
      },
      api = {
        nvim_create_user_command = function(name, fn, conf)
          table.insert(spies.api.nvim_create_user_command, { name, fn, conf })
        end,
      },
    }
    init.setup {}
    local expected_config = config.create_merged_config {}
    assert.same({ 'nvim-0.9.0' }, spies.fn.has)
    assert.same(expected_config, _G.triptych_mock_vim.g.triptych_config)
    assert.same(1, #spies.api.nvim_create_user_command)
    local create_cmd_args = spies.api.nvim_create_user_command[1]
    assert.same('Triptych', create_cmd_args[1])
    assert.same('function', type(create_cmd_args[2]))
    assert.same({}, create_cmd_args[3])
    assert.same(false, _G.triptych_mock_vim.g.triptych_is_open)
  end)
end)

describe('toggle_triptych', function()
  it('opens triptych, making the expected calls', function()
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
      file_reader = {
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
          nvim_buf_get_option = {},
        },
        fs = {
          dirname = {},
        },
        fn = {
          getcwd = 0,
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
        nvim_buf_get_option = function(bufid, option_name)
          table.insert(spies.vim.api.nvim_buf_get_option, { bufid, option_name })
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

    autocmds.new = function(h, f, s, d, g)
      table.insert(spies.autocmds.new, { h, f, s, d, g })
      return 'mock_autocmds'
    end

    actions.new = function(_state, refresh_fn)
      table.insert(spies.actions.new, { _state, refresh_fn })
      return 'mock_actions'
    end

    file_reader.new = function(debounce_ms)
      table.insert(spies.file_reader.new, debounce_ms)
      return 'mock_file_reader'
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

    init.toggle_triptych()

    assert.same({
      { _G.triptych_mock_vim.g.triptych_config, 66 },
    }, spies.state.new)
    assert.same(1, spies.git.new)
    assert.same(1, spies.diagnostics.new)
    assert.same({ 100 }, spies.file_reader.new)
    assert.same({ { 0, 'buftype' } }, spies.vim.api.nvim_buf_get_option)
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
          is_dir = false,
          win = 6,
        },
      },
    }, mock_state)
    assert.same(
      { { event_handlers, 'mock_file_reader', mock_state, 'mock_diagnostic', 'mock_git' } },
      spies.autocmds.new
    )
    assert.same(mock_state, spies.actions.new[1][1])
    assert.same({ { mock_state, 'mock_actions' } }, spies.mappings.new)
    assert.same({ { mock_state, '/hello', 'mock_diagnostic', 'mock_git', '/hello/world' } }, spies.view.nav_to)
  end)

  it('create a close function', function()
    local spies = {
      autocmd_destroy = 0,
      close_floats = {},
      nvim_set_current_win = {},
      file_reader_destroy = 0,
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
        nvim_buf_get_option = function(_, _) end,
      },
      fs = {
        dirname = function(path)
          return vim.fs.dirname(path)
        end,
      },
      fn = {
        getcwd = function() end,
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

    file_reader.new = function(_)
      return {
        destroy = function()
          spies.file_reader_destroy = spies.file_reader_destroy + 1
        end,
      }
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

    init.toggle_triptych()

    _G.triptych_mock_vim.g.triptych_close()

    assert.same(1, spies.autocmd_destroy)
    assert.same(1, spies.file_reader_destroy)
    assert.same({ { 4, 5, 6 } }, spies.close_floats)
    assert.same({ 9 }, spies.nvim_set_current_win)
  end)

  it("closes triptych if it's currently open", function()
    local close_spy = 0
    _G.triptych_mock_vim = {
      g = {
        triptych_is_open = true,
        triptych_close = function()
          close_spy = close_spy + 1
        end,
      },
    }

    init.toggle_triptych()

    assert.same(1, close_spy)
  end)
end)
