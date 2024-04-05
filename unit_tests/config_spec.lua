local config = require 'triptych.config'
local u = require 'triptych.utils'

---@return TriptychConfig
local function expected_default_config()
  return {
    mappings = {
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
      open_hsplit = { '-' },
      open_vsplit = { '|' },
      open_tab = { '<C-t>' },
      delete = 'd',
      add = 'a',
      copy = 'c',
      rename = 'r',
      cut = 'x',
      paste = 'p',
      quit = 'q',
      toggle_hidden = '<leader>.',
    },
    extension_mappings = {},
    options = {
      dirs_first = true,
      show_hidden = false,
      line_numbers = {
        enabled = true,
        relative = false,
      },
      file_icons = {
        enabled = true,
        directory_icon = '',
        fallback_file_icon = '',
      },
      column_widths = { 0.25, 0.25, 0.5 },
      highlights = {
        file_names = 'NONE',
        directory_names = 'NONE',
      },
      syntax_highlighting = {
        enabled = true,
        debounce_ms = 100,
      },
      backdrop = 60,
    },
    git_signs = {
      enabled = true,
      signs = {
        add = '+',
        modify = '~',
        rename = 'r',
        untracked = '?',
      },
    },
    diagnostic_signs = {
      enabled = true,
    },
  }
end

describe('create_merged_config', function()
  it('returns the default config when user config is empty', function()
    _G.triptych_mock_vim = {}
    assert.same(expected_default_config(), config.create_merged_config {})
  end)

  it('merges partial user config with the default', function()
    _G.triptych_mock_vim = {}
    local default_config = expected_default_config()
    local user_config = {
      mappings = {
        rename = 'H',
      },
      git_signs = {
        enabled = false,
      },
    }
    local expected = u.eval(function()
      local result = default_config
      result.mappings.rename = 'H'
      result.git_signs.enabled = false
      return result
    end)
    assert.same(expected, config.create_merged_config(user_config))
  end)

  it('validates the column_widths value', function()
    local spy = {}

    _G.triptych_mock_vim = {
      notify = function(msg, log_level, conf)
        table.insert(spy, { msg, log_level, conf })
      end,
      log = {
        levels = {
          WARN = 4,
        },
      },
    }

    local test = function(column_widths)
      return config.create_merged_config {
        options = {
          column_widths = column_widths,
        },
      }
    end

    local default_config = expected_default_config()

    local result1 = test { 1, 2, 3 }
    assert.same(default_config, result1)

    local result2 = test { 0.1, 0.2, 0.1 }
    assert.same(default_config, result2)

    local result3 = test { 1 }
    assert.same(default_config, result3)

    local result4 = test { 0.1, 0.1, 0.8 }
    assert.same({ 0.1, 0.1, 0.8 }, result4.options.column_widths)

    local expected_warning_a =
      'triptych config.options.column_widths must be a list of 3 decimal numbers. e.g. { 0.25, 0.25, 0.5 }'
    local expected_warning_b =
      'triptych config.options.column_widths must add up to 1 after rounding to 2 decimal places. e.g. { 0.25, 0.25, 0.5 }'

    assert.same({
      {
        expected_warning_b,
        4,
      },
      {
        expected_warning_b,
        4,
      },
      {
        expected_warning_a,
        4,
      },
    }, spy)
  end)
end)
