local u = require 'tests.utils'
local api = vim.api

local function open_and_get_state(callback)
  local cwd = vim.fn.getcwd()
  local opening_dir = u.join_path(cwd, 'tests/test_playground/level_1/level_2/level_3')

  u.open_triptych(opening_dir)
  u.on_all_wins_updated(function()
    callback(u.get_state())
  end)
end

-- open_and_get_state(vim.print)

describe('UI', function()
  it('when opened - populates windows with files and folders', function()
    local expected_lines = {
      child = { 'level_5/', 'level_4_file_1.js' },
      primary = { 'level_4/', 'level_3_file_1.js' },
      parent = { 'level_3/', 'level_2_file_1.js' },
    }

    local expected_winbars = {
      child = '%#WinBar#%=%#WinBar#level_4/%=',
      primary = '%#WinBar#%=%#WinBar#level_3%=',
      parent = '%#WinBar#%=%#WinBar#level_2%=',
    }

    local result

    u.await(function(done)
      open_and_get_state(function(state)
        result = state
        done()
      end)
    end)()


    assert.same(expected_lines, result.lines)
    assert.same(expected_winbars, result.winbars)
  end)

  it('navigates up and down the filesystem', function ()

  end)

  it('closes on key press', function ()

  end)

  it('closes on command', function ()

  end)

  it('shows files previews', function ()

  end)

  it('shows a help screen', function ()

  end)

  it('creates files and dirs', function ()

  end)

  it('deletes files and dirs', function ()

  end)

  it('does copy-paste', function ()

  end)

  it('does cut-and-paste', function ()

  end)

  it('renames files and dirs', function ()

  end)

  it('jumps to cwd and back', function ()

  end)

  it('toggles hidden files', function ()

  end)
end)
