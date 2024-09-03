local assert = require 'luassert'
local u = require 'tests.utils'
local test_runner = require 'tests.test_runner'
local run_tests = test_runner.run_tests
local test = test_runner.test

local function open_triptych(callback)
  local cwd = vim.fn.getcwd()
  local opening_dir = u.join_path(cwd, 'tests/test_playground/level_1/level_2/level_3')
  u.open_triptych(opening_dir)
  u.on_all_wins_updated(callback)
end

local function close_triptych(callback)
  u.on_event('TriptychDidClose', callback)
  u.press_key 'q'
end

run_tests {
  test('when opened - populates windows with files and folders', function(done)
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
        done(function()
          assert.same(expected_lines, result.lines)
          assert.same(expected_winbars, result.winbars)
        end)
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
      -- Nav right
      u.press_key 'l'
      u.on_all_wins_updated(function()
        local result = u.get_state()
        close_triptych(function()
          done(function()
            assert.same(expected_lines, result.lines)
            assert.same(expected_winbars, result.winbars)
          end)
        end)
      end)
    end)
  end),
}

-- it('navigates up the filesystem', function() end)
--
-- it('opens a file', function() end)
--
-- it('closes on key press', function() end)
--
-- it('closes on command', function() end)
--
-- it('shows files previews', function() end)
--
-- it('shows a help screen', function() end)
--
-- it('creates files and dirs', function() end)
--
-- it('deletes files and dirs', function() end)
--
-- it('does copy-paste', function() end)
--
-- it('does cut-and-paste', function() end)
--
-- it('renames files and dirs', function() end)
--
-- it('jumps to cwd and back', function() end)
--
-- it('toggles hidden files', function() end)
