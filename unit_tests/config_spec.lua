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
      cd = '<leader>cd',
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
end)
