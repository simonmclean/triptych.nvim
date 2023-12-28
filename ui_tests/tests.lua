local test_setup = require 'ui_tests.setup'
local tu = require 'ui_tests.utils'
local tryptic = require 'triptych.init'
local u = require 'triptych.utils'

-- TODO:
--
-- Additional test cases:
-- Rename
-- Copy paste
-- Cut and paste
-- Quit
-- Show help
-- Open file
-- Extension mapping
--
-- Figure out why tests fail on Linux (but not Mac) when files icons are enabled

local close_triptych

describe('triptych', function()
  before_each(function()
    test_setup.cleanup()
    test_setup.setup()
    tryptic.setup {
      options = {
        syntax_highlighting = {
          enabled = false,
          debounce_ms = 0,
        },
        file_icons = {
          enabled = false,
          directory_icon = '+',
          fallback_file_icon = '-',
        },
      },
    }
    close_triptych = tryptic.open_triptych(test_setup.test_playground_path .. '/level_1_dir_1/level_2_dir_1')
    tu.wait()
  end)

  after_each(function()
    test_setup.cleanup()
    close_triptych()
  end)

  it('populates the parent, primary and child windows when launched', function()
    assert.same({
      'level_2_dir_1/',
      'level_2_file_1.java',
      'level_2_file_2.sh',
      'level_2_file_3.php',
    }, tu.get_lines 'parent')
    assert.same({
      'level_3_dir_1/',
      'level_3_file_1.java',
    }, tu.get_lines 'primary')
    assert.same({
      'level_4_dir_1/',
      'level_4_file_1.js',
    }, tu.get_lines 'child')
  end)

  it('updates the child window when the cursor moves onto a file', function()
    tu.move 'down'
    local expected = u.multiline_str_to_table(test_setup.java_lines)
    table.insert(expected, '') -- TODO: Why
    assert.same(expected, tu.get_lines 'child')
  end)

  it('updates all windows when navigating to the parent directory', function()
    tu.move 'left'
    assert.same({
      'level_1_dir_1/',
      'level_1_dir_2/',
      'level_1_file_1.js',
      'level_1_file_2.ts',
      'level_1_file_3.lua',
    }, tu.get_lines 'parent')
    assert.same({
      'level_2_dir_1/',
      'level_2_file_1.java',
      'level_2_file_2.sh',
      'level_2_file_3.php',
    }, tu.get_lines 'primary')
    assert.same({
      'level_3_dir_1/',
      'level_3_file_1.java',
    }, tu.get_lines 'child')
  end)

  it('updates all windows when navigating to a child directory', function()
    tu.move 'right'
    assert.same({
      'level_5_file_1.lua',
    }, tu.get_lines 'child')
  end)

  it('deletes a file', function()
    tu.move 'down'
    tu.user_input 'd1<cr>'
    assert.same({
      'level_3_dir_1/',
    }, tu.get_lines 'primary')
  end)

  it('deletes a directory', function()
    tu.user_input 'd1<cr>'
    assert.same({
      'level_3_file_1.java',
    }, tu.get_lines 'primary')
  end)

  it('deletes a selection', function()
    tu.move 'left'
    tu.user_input 'V'
    tu.move 'down'
    tu.user_input 'd1<cr>'
    assert.same({
      'level_2_file_2.sh',
      'level_2_file_3.php',
    }, tu.get_lines 'primary')
  end)

  -- it('renames a directroy', function()
  --   tu.user_input 'r'
  --   tu.user_input 'hellos'
  --   tu.user_input '<cr>'
  --   assert.same({
  --     'hello/',
  --     'level_3_file_1.java',
  --   }, tu.get_lines 'primary')
  -- end)

  -- it('copy pastes single directroy', function()
  --   tu.user_input 'c'
  --   tu.user_input 'hellos'
  --   tu.user_input '<cr>'
  --   assert.same({
  --     'hello/',
  --     'level_3_file_1.java',
  --   }, tu.get_lines 'primary')
  -- end)

  -- it('copy pastes a selection a selection of multiple items', function() end)
  -- it('cut and pastes a single directory', function() end)
  -- it('cut and pastes a selection of multiple items', function() end)
  -- it('closes', function() end)
  -- it('shows help', function() end)
  -- it('opens a file', function() end)
  -- it('handles extension mappings', function() end)
end)
