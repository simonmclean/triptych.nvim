local help = require 'triptych.help'
local framework = require 'test_framework.test'
local it = framework.test
local describe = framework.describe
local assert_same = framework.assert_same

describe('help_lines', {
  it('returns key bindings', function()
    local result = help.help_lines()

    assert_same({
      ' Triptych key bindings',
      ' ',
      ' add                   :  a',
      ' cd                    :  <leader>cd',
      ' copy                  :  c',
      ' cut                   :  x',
      ' delete                :  d',
      ' jump_to_cwd           :  .',
      ' nav_left              :  h',
      ' nav_right             :  l, <CR>',
      ' open_hsplit           :  -',
      ' open_tab              :  <C-t>',
      ' open_vsplit           :  |',
      ' paste                 :  p',
      ' quit                  :  q',
      ' rename                :  r',
      ' rename_from_scratch   :  R',
      ' show_help             :  g?',
      ' toggle_collapse_dirs  :  z',
      ' toggle_hidden         :  <leader>.',
    }, result)
  end),
})
