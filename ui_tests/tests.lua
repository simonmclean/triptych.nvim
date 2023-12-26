local test_setup = require 'ui_tests.setup'
local tu = require 'ui_tests.utils'
local tryptic = require 'triptych.init'
local u = require 'triptych.utils'

-- TODO: Additional tests
-- Cut, copy, paste, delete, rename, quit, show help, open file

local close_triptych

describe('triptych', function()
  before_each(function()
    test_setup.setup()
    tryptic.setup {
      options = {
        syntax_highlighting = {
          enabled = false,
          debounce_ms = 0,
        },
        file_icons = {
          directory_icon = '+',
          fallback_file_icon = '-',
        },
      },
    }
    close_triptych = tryptic.open_triptych(test_setup.test_playground_path .. '/level_1_dir_1/level_2_dir_1')
    test_setup.wait()
  end)

  after_each(function()
    test_setup.cleanup()
    close_triptych()
  end)

  it('opens up with the expected lines', function()
    assert.same({
      '+ level_2_dir_1/',
      '- level_2_file_1.java',
      '- level_2_file_2.sh',
      '- level_2_file_3.php',
    }, tu.get_lines 'parent')
    assert.same({
      '+ level_3_dir_1/',
      '- level_3_file_1.java',
    }, tu.get_lines 'primary')
    assert.same({
      '+ level_4_dir_1/',
      '- level_4_file_1.js',
    }, tu.get_lines 'child')
  end)

  it('handles nav down to a file', function()
    tu.user_input 'j'
    local expected = u.multiline_str_to_table(test_setup.java_lines)
    table.insert(expected, '') -- TODO: Why
    assert.same(expected, tu.get_lines 'child')
  end)

  it('handles nav left', function()
    tu.user_input 'h'
    assert.same({
      '+ level_1_dir_1/',
      '+ level_1_dir_2/',
      '- level_1_file_1.js',
      '- level_1_file_2.ts',
      '- level_1_file_3.lua',
    }, tu.get_lines 'parent')
    assert.same({
      '+ level_2_dir_1/',
      '- level_2_file_1.java',
      '- level_2_file_2.sh',
      '- level_2_file_3.php',
    }, tu.get_lines 'primary')
    assert.same({
      '+ level_3_dir_1/',
      '- level_3_file_1.java',
    }, tu.get_lines 'child')
  end)

  it('handles nav right to a dir', function()
    tu.user_input 'l'
    assert.same({
      '- level_5_file_1.lua',
    }, tu.get_lines 'child')
  end)
end)
