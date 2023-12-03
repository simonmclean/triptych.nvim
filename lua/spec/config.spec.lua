local config = require 'tryptic.config'
local u = require 'tryptic.utils'

---@return TrypticConfig
local function get_default_config()
  return {
    mappings = {
      open_tryptic = '<leader>-',
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
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
    debug = false,
  }
end

describe('create_merged_config', function()
  it('returns the default config when user config is empty', function()
    assert.same(get_default_config(), config.create_merged_config {})
  end)

  it('merges partial user config with the default', function()
    local default_config = get_default_config()
    local user_config = {
      mappings = {
        open_tryptic = 'H',
      },
      git_signs = {
        enabled = false,
      },
    }
    local expected = u.eval(function()
      local result = default_config
      result.mappings.open_tryptic = 'H'
      result.git_signs.enabled = false
      return result
    end)
    assert.same(expected, config.create_merged_config(user_config))
  end)
end)
