local help = require 'triptych.help'

describe('help_lines', function()
  it('returns key bindings', function()
    local mappings = {
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = '<',
      nav_right = '>',
      delete = 'd',
      add = { 'a', 'A' },
      copy = 'c',
      rename = 'r',
      cut = 'x',
      paste = 'p',
      quit = 'q',
      toggle_hidden = '<leader>,',
    }

    _G.triptych_mock_vim = {
      g = {
        triptych_config = {
          mappings = mappings,
        },
      },
    }

    local result = help.help_lines()

    assert.same({
      'Triptych key bindings',
      '',
      '[.]             : jump_to_cwd',
      '[<]             : nav_left',
      '[<leader>,]     : toggle_hidden',
      '[>]             : nav_right',
      '[a, A]          : add',
      '[c]             : copy',
      '[d]             : delete',
      '[g?]            : show_help',
      '[p]             : paste',
      '[q]             : quit',
      '[r]             : rename',
      '[x]             : cut',
    }, result)
  end)
end)
