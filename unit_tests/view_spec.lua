local view = require 'triptych.view'
local float = require 'triptych.float'
local diagnostics = require 'triptych.diagnostics'
local fs = require 'triptych.fs'
local icons = require 'triptych.icons'

describe('refresh_view', function()
  it('calls nav_to', function()
    local spy = {}
    local nav_to_actual = view.set_primary_and_parent_window_targets

    view.set_primary_and_parent_window_targets = function(s, p, d, g)
      table.insert(spy, { s, p, d, g })
    end

    local mock_state = {
      windows = {
        current = {
          path = '/hello/',
        },
      },
    }
    local mock_diagnostics = { 'mock_diagnostics' }
    local mock_git = { 'mock_git' }

    view.refresh_view(mock_state, mock_diagnostics, mock_git)

    assert.same({ { mock_state, '/hello/', mock_diagnostics, mock_git } }, spy)

    view.set_primary_and_parent_window_targets = nav_to_actual
  end)
end)

describe('jump_cursor_to', function()
  it('jumps cursor to line', function()
    local spies = {
      api = {
        nvim_win_set_cursor = {},
      },
    }

    _G.triptych_mock_vim = {
      api = {
        nvim_win_set_cursor = function(winid, pos)
          table.insert(spies.api.nvim_win_set_cursor, { winid, pos })
        end,
      },
    }

    local mock_state = {
      windows = {
        current = {
          contents = {
            children = {
              { path = '/hello/world.js' },
              { path = '/hello/foo.js' },
            },
          },
        },
      },
    }

    view.jump_cursor_to(mock_state, '/hello/foo.js')

    assert.same({ { 0, { 2, 0 } } }, spies.api.nvim_win_set_cursor)
  end)
end)

describe('update_child_window', function()
  it('makes the expected calls', function()
    local spies = {
      api = {
        nvim_win_get_buf = {},
        nvim_buf_set_option = {},
        nvim_buf_set_var = {},
      },
      float = {
        win_set_title = {},
        buf_set_lines = {},
        buf_apply_highlights = {},
      },
      fs = {
        get_path_details = {},
      },
      fn = {
        sign_unplace = {},
        getcwd = 0,
      },
      git = {
        filter_ignored = {},
        status_of = {},
      },
      diagnostics = {
        get_sign = {},
        get = {},
      },
      icons = {
        get_icon_by_filetype = {},
      },
      treesitter = {
        stop = {},
      },
    }

    _G.triptych_mock_vim = {
      g = {
        triptych_config = require('triptych.config').create_merged_config {},
      },
      api = {
        nvim_win_get_buf = function(winid)
          table.insert(spies.api.nvim_win_get_buf, winid)
          return 11
        end,
        nvim_buf_set_option = function(bufid, opt, value)
          table.insert(spies.api.nvim_buf_set_option, { bufid, opt, value })
        end,
        nvim_buf_set_var = function(buf, varname, value)
          table.insert(spies.api.nvim_buf_set_var, { buf, varname, value })
        end,
      },
      fn = {
        sign_unplace = function(group)
          table.insert(spies.fn.sign_unplace, group)
        end,
        getcwd = function()
          spies.fn.getcwd = spies.fn.getcwd + 1
          return '/wow/'
        end,
      },
      treesitter = {
        stop = function(bufid)
          table.insert(spies.treesitter.stop, bufid)
        end,
      },
    }

    icons.get_icon_by_filetype = function(ft)
      table.insert(spies.icons.get_icon_by_filetype, ft)
      return 'x'
    end

    float.win_set_title = function(winid, title, icon, highlight, postfix)
      table.insert(spies.float.win_set_title, { winid, title, icon, highlight, postfix })
    end

    float.buf_set_lines = function(bufid, lines)
      table.insert(spies.float.buf_set_lines, { bufid, lines })
    end

    float.buf_apply_highlights = function(bufid, highlight)
      table.insert(spies.float.buf_apply_highlights, { bufid, highlight })
    end

    diagnostics.get_sign = function(status)
      table.insert(spies.diagnostics.get_sign, status)
      return '👻'
    end

    fs.get_path_details = function(path)
      table.insert(spies.fs.get_path_details, path)
      return {
        win = 6,
        path = '/hello/',
        basename = 'hello',
        is_dir = true,
        children = {
          {
            display_name = 'a/',
            is_dir = true,
            children = {},
          },
          {
            display_name = 'b',
            is_dir = false,
            children = {},
          },
          {
            display_name = 'c',
            is_dir = false,
            children = {},
          },
        },
        git_status = 'M',
        diagnostic_status = 3,
      }
    end

    local mock_state = {
      show_hidden = true,
      windows = {
        child = {
          win = 6,
          path = '/hello/',
          basename = 'hello',
          is_dir = true,
          children = {},
          git_status = 'M',
          diagnostic_status = 3,
        },
      },
      cut_list = {},
      copy_list = {},
    }

    local mock_git = {
      filter_ignored = function(_, paths)
        table.insert(spies.git.filter_ignored, paths)
        return paths
      end,
      status_of = function(_, path)
        table.insert(spies.git.status_of, path)
        return 'M'
      end,
    }

    local mock_diagnostics = {
      get = function(_, path)
        table.insert(spies.diagnostics.get, path)
        return '🎸'
      end,
    }

    local mock_file_reader = {}

    view.set_child_window_lines(mock_state, mock_file_reader, mock_state.windows.child, mock_diagnostics, mock_git)

    assert.same({ 6 }, spies.api.nvim_win_get_buf)
    assert.same({ {
      6,
      'hello',
      '',
      'Directory',
    } }, spies.float.win_set_title)
    assert.same({ 11 }, spies.treesitter.stop)
    assert.same({ { 11, 'syntax', 'off' } }, spies.api.nvim_buf_set_option)
    assert.same(1, spies.fn.getcwd)
    assert.same({ '/hello/' }, spies.fs.get_path_details)
    assert.same({}, spies.git.filter_ignored)
    assert.same({ '/hello/' }, spies.git.status_of)
    assert.same({ '/hello/' }, spies.diagnostics.get)
    assert.same({ { 11, {
      ' a/',
      'x b',
      'x c',
    } } }, spies.float.buf_set_lines)
    assert.same({
      {
        11,
        {
          { icon = { highlight_name = 'Directory', length = 3 }, text = { highlight_name = 'NONE', starts = 3 } },
          { icon = { highlight_name = 'Comment', length = 3 }, text = { highlight_name = 'NONE', starts = 3 } },
          { icon = { highlight_name = 'Comment', length = 3 }, text = { highlight_name = 'NONE', starts = 3 } },
        },
      },
    }, spies.float.buf_apply_highlights)
    assert.same({ 'triptych_sign_col_child' }, spies.fn.sign_unplace)
    assert.same({ '🎸', '🎸', '🎸' }, spies.diagnostics.get_sign)
  end)
end)

describe('nav_to', function()
  it('makes the expected calls', function()
    local spies = {
      vim = {
        api = {
          nvim_win_get_buf = {},
          nvim_win_set_cursor = {},
          nvim_buf_line_count = {},
        },
        fs = {
          basename = {},
          dirname = {},
        },
        fn = {
          sign_unplace = {},
          sign_get_defined = {},
          sign_place = {},
          getcwd = 0,
        },
      },
      fs = {
        get_path_details = {},
      },
      float = {
        win_set_lines = {},
        win_set_title = {},
        buf_apply_highlights = {},
      },
      git = {
        status_of = {},
        get_sign = {},
      },
      diagnostics = {
        get = {},
        get_sign = {},
      },
    }

    local mock_state = {
      show_hidden = true,
      windows = {
        parent = {
          win = 2,
          path = '/level_1',
          children = {
            { path = '/level_1/level_2/', is_dir = true, display_name = 'level_2/' },
          },
        },
        current = {
          win = 1,
          path = '/level_1/level_2',
          children = {
            {
              path = '/level_1/level_2/level_3/',
              display_name = 'level_3/',
              is_dir = true,
            },
            {
              path = '/level_1/level_2/file_a.js',
              display_name = 'file_a.js',
              is_dir = false,
            },
          },
        },
        child = {
          win = 3,
          path = '/level_1/level_2/level_3',
          children = {
            {
              path = '/level_1/level_2/level_3/file_b.js',
              display_name = 'file_b.js',
              is_dir = false,
            },
          },
        },
      },
      path_to_line_map = {},
      cut_list = {},
      copy_list = {},
    }

    fs.get_path_details = function(path)
      table.insert(spies.fs.get_path_details, path)
      if path == '/level_1/level_2/level_3' then
        return {
          path = '/level_1/level_2/level_3',
          display_name = 'level_3/',
          is_dir = true,
          children = {
            {
              path = '/level_1/level_2/level_3/file_b.js',
              display_name = 'file_b.js',
              is_dir = false,
            },
          },
        }
      end
      return {
        path = '/level_1/level_2',
        display_name = 'level_2/',
        is_dir = true,
        children = {
          {
            path = '/level_1/level_2/level_3',
            display_name = 'level_3/',
            is_dir = true,
          },
          {
            path = '/level_1/level_2/file_a.js',
            display_name = 'file_a.js',
            is_dir = false,
          },
        },
      }
    end

    float.win_set_lines = function(winid, lines, scroll_top)
      table.insert(spies.float.win_set_lines, { winid, lines, scroll_top })
    end

    float.win_set_title = function(winid, title, icon, hi, postfix)
      table.insert(spies.float.win_set_title, { winid, title, icon, hi, postfix })
    end

    float.buf_apply_highlights = function(bufid, hi)
      table.insert(spies.float.buf_apply_highlights, { bufid, hi })
    end

    local mock_git = {
      status_of = function(_, path)
        table.insert(spies.git.status_of, path)
        return 'A'
      end,
    }

    local mock_diagnostics = {
      get = function(_, path)
        table.insert(spies.diagnostics.get, path)
        return 'x'
      end,
    }

    diagnostics.get_sign = function(status)
      table.insert(spies.diagnostics.get_sign, status)
    end

    _G.triptych_mock_vim = {
      g = {
        triptych_config = require('triptych.config').create_merged_config {},
      },
      api = {
        nvim_win_get_buf = function(winid)
          table.insert(spies.vim.api.nvim_win_get_buf, winid)
          if winid == 1 then
            return 7
          end
          if winid == 2 then
            return 8
          end
          return 9
        end,
        nvim_buf_line_count = function(bufid)
          table.insert(spies.vim.api.nvim_buf_line_count, bufid)
          return 2
        end,
        nvim_win_set_cursor = function(winid, pos)
          table.insert(spies.vim.api.nvim_win_set_cursor, { winid, pos })
        end,
      },
      fn = {
        sign_unplace = function(group)
          table.insert(spies.vim.fn.sign_unplace, group)
        end,
        getcwd = function()
          spies.vim.fn.getcwd = spies.vim.fn.getcwd + 1
        end,
      },
      fs = {
        basename = function(path)
          table.insert(spies.vim.fs.basename, path)
          return vim.fs.basename(path)
        end,
        dirname = function(path)
          table.insert(spies.vim.fs.dirname, path)
          return vim.fs.dirname(path)
        end,
      },
    }

    require('triptych.view').set_primary_and_parent_window_targets(mock_state, '/level_1/level_2/level_3', mock_diagnostics, mock_git)

    assert.same({ 1, 2 }, spies.vim.api.nvim_win_get_buf)
    assert.same({
      '/level_1/level_2/level_3',
      '/level_1/level_2',
    }, spies.fs.get_path_details)
    assert.same({ '/level_1/level_2/level_3', '/level_1/level_2' }, spies.vim.fs.basename)
    assert.same({ '/level_1/level_2/level_3' }, spies.vim.fs.dirname)
    assert.same({
      {
        2,
        {
          ' level_3/',
          'x file_a.js',
        },
      },
      {
        1,
        {
          'x file_b.js',
        },
        true,
      },
    }, spies.float.win_set_lines)
    assert.same({
      { 2, 'level_2', '', 'Directory' },
      { 1, 'level_3', '', 'Directory' },
    }, spies.float.win_set_title)
    assert.same({
      {
        7,
        {
          {
            icon = { highlight_name = 'Comment', length = 3 },
            text = { highlight_name = 'NONE', starts = 3 },
          },
        },
      },
      {
        8,
        {
          {
            icon = { highlight_name = 'Directory', length = 3 },
            text = { highlight_name = 'NONE', starts = 3 },
          },
          {
            icon = { highlight_name = 'Comment', length = 3 },
            text = { highlight_name = 'NONE', starts = 3 },
          },
        },
      },
    }, spies.float.buf_apply_highlights)
    assert.same({ 7 }, spies.vim.api.nvim_buf_line_count)
    assert.same({
      { 0, { 1, 0 } },
      { 2, { 1, 0 } },
    }, spies.vim.api.nvim_win_set_cursor)
    assert.same({
      parent = {
        path = '/level_1/level_2',
        contents = {
          children = {
            {
              diagnostic_status = 'x',
              display_name = 'level_3/',
              git_status = 'A',
              is_dir = true,
              path = '/level_1/level_2/level_3',
            },
            {
              diagnostic_status = 'x',
              display_name = 'file_a.js',
              git_status = 'A',
              is_dir = false,
              path = '/level_1/level_2/file_a.js',
            },
          },
          diagnostic_status = 'x',
          display_name = 'level_2/',
          git_status = 'A',
          is_dir = true,
          path = '/level_1/level_2',
        },
        win = 2,
      },
      current = {
        path = '/level_1/level_2/level_3',
        previous_path = '/level_1/level_2',
        contents = {
          children = {
            {
              diagnostic_status = 'x',
              display_name = 'file_b.js',
              git_status = 'A',
              is_dir = false,
              path = '/level_1/level_2/level_3/file_b.js',
            },
          },
          diagnostic_status = 'x',
          display_name = 'level_3/',
          git_status = 'A',
          is_dir = true,
          path = '/level_1/level_2/level_3',
        },
        win = 1,
      },
      child = {
        path = '',
        contents = nil,
        lines = nil,
        win = 3,
      },
    }, mock_state.windows)
  end)
end)

describe('get_targets_in_selection', function()
  it('gets targets in the visuals selection', function()
    local spies = {
      vim = {
        api = {
          nvim_win_get_cursor = {},
        },
        fn = {
          getpos = {},
        },
      },
    }

    _G.triptych_mock_vim = {
      fn = {
        getpos = function(value)
          table.insert(spies.vim.fn.getpos, value)
          return { 1, 2 }
        end,
      },
      api = {
        nvim_win_get_cursor = function(winid)
          table.insert(spies.vim.api.nvim_win_get_cursor, winid)
          return { 4, 5 }
        end,
      },
    }

    local mock_state = {
      windows = {
        current = {
          contents = {
            children = { 'hello', 'world', 'monkey' },
          },
        },
      },
    }

    local result = view.get_targets_in_selection(mock_state)

    assert.same({ 'world', 'monkey' }, result)
  end)
end)

describe('get_target_under_cursor', function()
  it('gets target under cursor', function()
    local spy = {}
    _G.triptych_mock_vim = {
      api = {
        nvim_win_get_cursor = function(winid)
          table.insert(spy, winid)
          return { 3, 4 }
        end,
      },
    }
    local mock_state = {
      windows = {
        current = {
          contents = {
            children = { 'hello', 'world', 'monkey' },
          },
        },
      },
    }
    local result = view.get_target_under_cursor(mock_state)
    assert.same({ 0 }, spy)
    assert.same('monkey', result)
  end)
end)
