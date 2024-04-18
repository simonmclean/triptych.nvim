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
--
-- Figure out why tests fail on Linux (but not Mac) when files icons are enabled

---@return TriptychConfig
local function test_config()
  return {
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
end

---@param config? table
---@return fun()
local function open_triptych(config)
  tryptic.setup(config or test_config())
  local close_fn = tryptic.toggle_triptych(test_setup.test_playground_path .. '/level_1_dir_1/level_2_dir_1')
  tu.wait()
  ---@diagnostic disable-next-line: return-type-mismatch
  return close_fn
end

--- Opens tripytic with the config defined above, runs the test case, then closes tripytic
---@param fn function - test
---@return nil
local function with_default_config_and_close(fn)
  local close = open_triptych()
  fn()
  close()
end

describe('triptych', function()
  before_each(function()
    test_setup.cleanup()
    test_setup.setup()
  end)

  after_each(function()
    test_setup.cleanup()
  end)

  it('closes when user inputs the configured key (default q).', function()
    local close = open_triptych()
    tu.user_input 'q'
    local success, _ = pcall(close)
    assert(success == false, 'Expected close to fail because triptic should already be closed')
  end)

  it('closes when user calls the Triptych() command and triptych is already open', function()
    local close = open_triptych()
    vim.cmd.Triptych()
    local success, _ = pcall(close)
    assert(success == false, 'Expected close to fail because triptic should already be closed')
  end)

  it('populates the parent, primary and child windows when launched', function()
    with_default_config_and_close(function()
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
  end)

  it('updates the child window when the cursor moves onto a file', function()
    with_default_config_and_close(function()
      tu.move 'down'
      local expected = u.multiline_str_to_table(test_setup.java_lines)
      table.insert(expected, '') -- TODO: Why
      assert.same(expected, tu.get_lines 'child')
    end)
  end)

  it('updates all windows when navigating to the parent directory', function()
    with_default_config_and_close(function()
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
  end)

  it('updates all windows when navigating to a child directory', function()
    with_default_config_and_close(function()
      tu.move 'right'
      assert.same({
        'level_5_file_1.lua',
      }, tu.get_lines 'child')
    end)
  end)

  it('shows key binding when user inputs the configured help binding (default g?)', function()
    with_default_config_and_close(function()
      tu.user_input 'g?'
      assert.same('Triptych key bindings', tu.get_lines('child')[1])
    end)
  end)

  it('passes the expected values to an extension mapping function', function()
    local result
    local close = open_triptych {
      extension_mappings = {
        ['+'] = {
          mode = 'n',
          fn = function(arg)
            result = arg
          end,
        },
      },
    }
    tu.user_input '+'
    assert.same({
      children = {},
      dirname = './test_playground/level_1_dir_1/level_2_dir_1',
      display_name = 'level_3_dir_1/',
      is_dir = true,
      path = './test_playground/level_1_dir_1/level_2_dir_1/level_3_dir_1',
    }, result)
    close()
  end)

  -- it('copies a file', function()
  --   with_default_config_and_close(function()
  --     tu.move 'down'
  --     tu.user_input 'c'
  --     assert.same({
  --       'level_3_dir_1/',
  --       'level_3_file_1.java (copy)',
  --     }, tu.get_lines 'primary')
  --     tu.move 'left'
  --     tu.move 'down'
  --     tu.user_input 'p'
  --     assert.same({
  --       'level_2_dir_1/',
  --       'level_2_file_1.java',
  --       'level_2_file_2.sh',
  --       'level_2_file_3.php',
  --       'level_3_file_1.java',
  --     }, tu.get_lines 'primary')
  --   end)
  -- end)

  it('deletes a file', function()
    with_default_config_and_close(function()
      tu.move 'down'
      tu.user_input 'd1<CR>'
      assert.same({
        'level_3_dir_1/',
      }, tu.get_lines 'primary')
    end)
  end)

  it('deletes a directory', function()
    with_default_config_and_close(function()
      tu.user_input 'd1<cr>'
      assert.same({
        'level_3_file_1.java',
      }, tu.get_lines 'primary')
    end)
  end)

  it('deletes a selection', function()
    with_default_config_and_close(function()
      tu.move 'left'
      tu.user_input 'V'
      tu.move 'down'
      tu.user_input 'd1<cr>'
      assert.same({
        'level_2_file_2.sh',
        'level_2_file_3.php',
      }, tu.get_lines 'primary')
    end)
  end)
end)
