local help = require 'triptych.help'
local assert = require 'luassert'
local framework = require 'test_framework.test'
local it = framework.test
local describe = framework.describe

describe('help_lines', {
  it('returns key bindings', function()
    local result = help.help_lines()

    assert.same({
      'Triptych key bindings',
      '',
      '[-]                    : open_hsplit',
      '[.]                    : jump_to_cwd',
      '[<C-t>]                : open_tab',
      '[<leader>.]            : toggle_hidden',
      '[<leader>cd]           : cd',
      '[a]                    : add',
      '[c]                    : copy',
      '[d]                    : delete',
      '[g?]                   : show_help',
      '[h]                    : nav_left',
      '[l, <CR>]              : nav_right',
      '[p]                    : paste',
      '[q]                    : quit',
      '[r]                    : rename',
      '[x]                    : cut',
      '[z]                    : toggle_collapse_dirs',
      '[|]                    : open_vsplit',
    }, result)
  end),
})
