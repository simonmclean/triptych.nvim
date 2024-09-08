local assert = require 'luassert'
local u = require 'tests.utils'
local framework = require 'tests.test_framework'
local describe = framework.describe
local test = framework.test_async

local cwd = vim.fn.getcwd()
local opening_dir = u.join_path(cwd, 'tests/test_playground/level_1/level_2/level_3')

---@param callback function
local function open_triptych(callback)
  u.open_triptych(opening_dir)
  u.on_all_wins_updated(callback)
end

---@param callback function
local function close_triptych(callback)
  u.on_event('TriptychDidClose', callback)
  u.press_keys 'q'
end

describe('Triptych UI', {
  test('opens on Triptych command, with cursor on current file', function(done)
    u.setup_triptych()
    vim.cmd 'Triptych'
    u.on_all_wins_updated(function()
      local is_open = vim.g.triptych_is_open
      local current_line = vim.api.nvim_get_current_line()
      close_triptych(function()
        done {
          assertions = function()
            assert.same(is_open, true)
            -- This is kinda janky, but basically this test could be called from one of 2 places
            assert(current_line == 'run_specs.lua' or current_line == 'ui_spec.spec')
          end,
        }
      end)
    end)
  end):only(),

  test('closes on Triptych command', function(done)
    open_triptych(function()
      u.on_event('TriptychDidClose', function()
        done {
          assertions = function()
            assert.same(vim.g.triptych_is_open, false)
          end,
        }
      end)
      vim.cmd 'Triptych'
    end)
  end),

  test('populates windows with files and folders', function(done)
    local expected_lines = {
      child = { 'level_5/', 'level_4_file_1.lua' },
      primary = { 'level_4/', 'level_3_file_1.md' },
      parent = { 'level_3/', 'level_2_file_1.lua' },
    }

    local expected_winbars = {
      child = '%#WinBar#%=%#WinBar#level_4/%=',
      primary = '%#WinBar#%=%#WinBar#level_3%=',
      parent = '%#WinBar#%=%#WinBar#level_2%=',
    }

    local result

    open_triptych(function()
      result = u.get_state()
      close_triptych(function()
        done {
          assertions = function()
            assert.same(expected_lines, result.lines)
            assert.same(expected_winbars, result.winbars)
          end,
        }
      end)
    end)
  end),

  test('navigates down the filesystem', function(done)
    local expected_lines = {
      child = { 'level_5_file_1.lua' },
      primary = { 'level_5/', 'level_4_file_1.lua' },
      parent = { 'level_4/', 'level_3_file_1.md' },
    }

    local expected_winbars = {
      child = '%#WinBar#%=%#WinBar#level_5/%=',
      primary = '%#WinBar#%=%#WinBar#level_4%=',
      parent = '%#WinBar#%=%#WinBar#level_3%=',
    }

    open_triptych(function()
      u.press_keys 'l'
      u.on_all_wins_updated(function()
        local result = u.get_state()
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_lines, result.lines)
              assert.same(expected_winbars, result.winbars)
            end,
          }
        end)
      end)
    end)
  end),

  test('navigates up the filesystem', function(done)
    local expected_lines = {
      child = { 'level_4/', 'level_3_file_1.md' },
      primary = { 'level_3/', 'level_2_file_1.lua' },
      parent = { 'level_2/', 'level_1_file_1.lua' },
    }

    local expected_winbars = {
      child = '%#WinBar#%=%#WinBar#level_3/%=',
      primary = '%#WinBar#%=%#WinBar#level_2%=',
      parent = '%#WinBar#%=%#WinBar#level_1%=',
    }

    open_triptych(function()
      u.press_keys 'h'
      u.on_all_wins_updated(function()
        local result = u.get_state()
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_lines, result.lines)
              assert.same(expected_winbars, result.winbars)
            end,
          }
        end)
      end)
    end)
  end),

  test('opens a file', function(done)
    -- Used to return to this buffer, after the file is opened
    local current_buf = vim.api.nvim_get_current_buf()

    open_triptych(function()
      u.on_event('TriptychDidClose', function()
        done {
          assertions = function()
            assert.same(vim.g.triptych_is_open, false)
          end,
          cleanup = function()
            vim.api.nvim_set_current_buf(current_buf)
          end,
        }
      end)
      u.press_keys 'j'
      u.on_child_window_updated(function()
        u.press_keys 'l'
      end)
    end)
  end),

  test('shows a file preview', function(done)
    local expected_file_preview = {
      '# This is markdown',
      '',
      'Just some text',
      '',
    }

    open_triptych(function()
      u.on_child_window_updated(function()
        local state = u.get_state()
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_file_preview, state.lines.child)
            end,
          }
        end)
      end)
      u.press_keys 'j'
    end)
  end),

  test('creates files and folders', function(done)
    local expected_lines = {
      primary = {
        'a_new_dir/',
        'level_4/',
        'a_new_file.lua',
        'level_3_file_1.md',
      },
      child = {
        'another_new_file.md',
      },
    }

    open_triptych(function()
      u.press_keys 'a'
      u.press_keys 'a_new_file.lua<cr>'
      u.press_keys 'a'
      u.press_keys 'a_new_dir/another_new_file.md<cr>'
      u.on_wins_updated({ 'primary', 'child' }, function()
        local state = u.get_state()
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_lines.primary, state.lines.primary)
              assert.same(expected_lines.child, state.lines.child)
            end,
            cleanup = function()
              vim.fn.delete(u.join_path(opening_dir, 'a_new_dir'), 'rf')
              vim.fn.delete(u.join_path(opening_dir, 'a_new_file.lua'))
            end,
          }
        end)
      end)
    end)
  end),

  test('publishes public events on file/folder creation', function(done)
    local expected_events = {
      ['TriptychWillCreateNode'] = {
        { path = u.join_path(opening_dir, 'a_new_file.lua') },
        { path = u.join_path(opening_dir, 'a_new_dir/another_new_file.md') },
      },
      ['TriptychDidCreateNode'] = {
        { path = u.join_path(opening_dir, 'a_new_file.lua') },
        { path = u.join_path(opening_dir, 'a_new_dir/another_new_file.md') },
      },
    }

    open_triptych(function()
      u.press_keys 'a'
      u.press_keys 'a_new_file.lua<cr>'
      u.press_keys 'a'
      u.press_keys 'a_new_dir/another_new_file.md<cr>'
      u.on_events({
        { name = 'TriptychWillCreateNode', wait_for_n = 2 },
        { name = 'TriptychDidCreateNode', wait_for_n = 2 },
      }, function(events)
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_events, events)
            end,
            cleanup = function()
              vim.fn.delete(u.join_path(opening_dir, 'a_new_dir'), 'rf')
              vim.fn.delete(u.join_path(opening_dir, 'a_new_file.lua'))
            end,
          }
        end)
      end)
    end)
  end),

  -- Having trouble with this
  -- How to programatically input a selection in vim.ui.select
  test('deletes files and folders', function(done)
    local expected_lines = {
      primary = {
        'level_4/',
        'level_3_file_1.md',
      },
      child = {
        'another_new_file.md',
      },
    }

    open_triptych(function()
      -- Add things
      u.press_keys 'a'
      u.press_keys 'a_new_file.lua<cr>'
      u.press_keys 'a'
      u.press_keys 'a_new_dir/another_new_file.md<cr>'
      -- Then remove them
      u.on_wins_updated({ 'primary', 'child' }, function()
        local state = u.get_state()
        u.press_keys 'd1<cr>'
        u.on_wins_updated({ 'primary', 'child' }, function()
          close_triptych(function()
            done {
              assertions = function()
                assert.same(expected_lines.primary, state.lines.primary)
                assert.same(expected_lines.child, state.lines.child)
              end,
            }
          end)
        end)
      end)
    end)
  end):skip(),

  -- TODO: Skipped this because there seems to be a bug with dir pasting!
  test('copies file and folders', function(done)
    local expected_lines = {
      primary = {
        'level_4/',
        'level_3_file_1.md',
        'level_3_file_1_copy1.md',
      },
      child = {
        'level_4/',
        'level_5/',
        'level_4_file_1.lua',
      },
    }
    open_triptych(function()
      u.press_keys 'c'
      u.on_primary_window_updated(function()
        u.press_keys 'p'
        u.on_primary_window_updated(function()
          u.press_keys 'j'
          u.press_keys 'c'
          u.on_primary_window_updated(function()
            u.press_keys 'p'
            u.on_primary_window_updated(function()
              -- Go back to the top, so we can the new dir we've pasted in the the child directory
              u.press_keys 'gg'
              u.on_child_window_updated(function()
                local state = u.get_state()
                close_triptych(function()
                  done {
                    assertions = function()
                      assert.same(expected_lines.child, state.lines.child)
                      assert.same(expected_lines.primary, state.lines.primary)
                    end,
                    cleanup = function()
                      vim.fn.delete(u.join_path(opening_dir, 'level_3_file_1_copy1.md'))
                      vim.fn.delete(u.join_path(opening_dir, 'level_4/level_4', 'rf'))
                    end,
                  }
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end):skip(),

  -- TODO: This once the dir pasting bug has been fixed
  -- test('moves files and folders', function (done) end):skip()

  -- TODO: This once the dir pasting bug has been fixed
  -- test('copies files and folders', function(done) end):skip()

  test('renames files and folders', function(done)
    local expected_lines = {
      primary = {
        'renamed_dir/',
        'renamed_file.lua',
      },
    }

    open_triptych(function()
      u.press_keys 'r'
      u.press_keys 'renamed_dir<cr>'
      u.on_primary_window_updated(function()
        u.press_keys 'j'
        u.press_keys 'r'
        u.press_keys 'renamed_file.lua<cr>'
        u.on_primary_window_updated(function()
          local state = u.get_state()
          close_triptych(function()
            done {
              assertions = function()
                assert.same(expected_lines.primary, state.lines.primary)
              end,
              cleanup = function()
                vim.fn.rename(u.join_path(opening_dir, 'renamed_dir'), u.join_path(opening_dir, 'level_4'))
                vim.fn.rename(
                  u.join_path(opening_dir, 'renamed_file.lua'),
                  u.join_path(opening_dir, 'level_3_file_1.md')
                )
              end,
            }
          end)
        end)
      end)
    end)
  end),

  test('publishes public events on renaming files/folders', function(done)
    local expected_data = {
      { from_path = u.join_path(opening_dir, 'level_4'), to_path = u.join_path(opening_dir, 'renamed_dir') },
      {
        from_path = u.join_path(opening_dir, 'level_3_file_1.md'),
        to_path = u.join_path(opening_dir, 'renamed_file.lua'),
      },
    }

    local expected_events = {
      ['TriptychWillMoveNode'] = expected_data,
      ['TriptychDidMoveNode'] = expected_data,
    }

    open_triptych(function()
      u.press_keys 'r'
      u.press_keys 'renamed_dir<cr>'
      u.on_primary_window_updated(function()
        u.press_keys 'j'
        u.press_keys 'r'
        u.press_keys 'renamed_file.lua<cr>'
      end)
      u.on_events({
        { name = 'TriptychWillMoveNode', wait_for_n = 2 },
        { name = 'TriptychDidMoveNode', wait_for_n = 2 },
      }, function(events)
        close_triptych(function()
          done {
            assertions = function()
              assert.same(expected_events, events)
            end,
            cleanup = function()
              vim.fn.rename(u.join_path(opening_dir, 'renamed_dir'), u.join_path(opening_dir, 'level_4'))
              vim.fn.rename(u.join_path(opening_dir, 'renamed_file.lua'), u.join_path(opening_dir, 'level_3_file_1.md'))
            end,
          }
        end)
      end)
    end)
  end),

  test('toggles hidden files (dot and gitignored)', function(done)
    local expected_lines_without_hidden = {
      primary = {
        'level_4/',
        'level_3_file_1.md',
      },
    }
    local expected_lines_with_hidden = {
      primary = {
        'level_4/',
        '.hidden_dot_file',
        'git_ignored_file',
        'level_3_file_1.md',
      },
    }

    open_triptych(function()
      local first_state = u.get_state()
      u.press_keys '<leader>.'
      u.on_primary_window_updated(function()
        local second_state = u.get_state()
        u.press_keys '<leader>.'
        u.on_primary_window_updated(function()
          local third_state = u.get_state()
          close_triptych(function()
            done {
              assertions = function()
                assert.same(expected_lines_without_hidden.primary, first_state.lines.primary)
                assert.same(expected_lines_with_hidden.primary, second_state.lines.primary)
                assert.same(expected_lines_without_hidden.primary, third_state.lines.primary)
              end,
            }
          end)
        end)
      end)
    end)
  end),

  test('jumps to cwd and back', function(done)
    -- Using the winbar as a proxy for directory
    local expected_winbar_after_first_jump = '%#WinBar#%=%#WinBar#triptych %#Comment#(cwd)%='
    local expected_winbar_after_second_jump = '%#WinBar#%=%#WinBar#level_3%='

    local winbar_after_first_jump
    local winbar_after_second_jump

    open_triptych(function()
      u.press_keys '.'
      u.on_all_wins_updated(function()
        local state = u.get_state()
        winbar_after_first_jump = state.winbars.primary
        u.press_keys '.'
        u.on_all_wins_updated(function()
          local state_2 = u.get_state()
          winbar_after_second_jump = state_2.winbars.primary
          close_triptych(function()
            done {
              assertions = function()
                assert.same(expected_winbar_after_first_jump, winbar_after_first_jump)
                assert.same(expected_winbar_after_second_jump, winbar_after_second_jump)
              end,
            }
          end)
        end)
      end)
    end)
  end),
})
