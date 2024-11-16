local assert = require 'luassert'
local u = require 'tests.utils'
local config = require 'triptych.config'
local framework = require 'test_framework.test'
local it = framework.test
local describe = framework.describe

local function expected_default_config()
  return {
    debug = false,
    mappings = {
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
      open_hsplit = { '-' },
      open_vsplit = { '|' },
      open_tab = { '<C-t>' },
      cd = '<leader>cd',
      delete = 'd',
      add = 'a',
      copy = 'c',
      rename = 'r',
      cut = 'x',
      paste = 'p',
      quit = 'q',
      toggle_hidden = '<leader>.',
      toggle_collapse_dirs = 'z',
    },
    extension_mappings = {},
    options = {
      dirs_first = true,
      collapse_dirs = true,
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
      responsive_column_widths = {
        ['0'] = { 0, 0.5, 0.5 },
        ['120'] = { 0.2, 0.3, 0.5 },
        ['200'] = { 0.25, 0.25, 0.5 },
      },
      highlights = {
        file_names = 'NONE',
        directory_names = 'NONE',
      },
      syntax_highlighting = {
        enabled = true,
        debounce_ms = 100,
      },
      backdrop = 60,
      transparency = 0,
      border = 'single',
      max_height = 45,
      max_width = 220,
      margin_x = 4,
      margin_y = 4,
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

describe('create_merged_config', {
  it('returns the default config when user config is empty', function()
    assert.same(expected_default_config(), config.create_merged_config {})
  end),

  it('merges partial user config with the default', function()
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
  end),
})
