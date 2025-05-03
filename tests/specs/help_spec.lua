local help = require 'triptych.help'
local assert = require 'luassert'
local framework = require 'test_framework.test'
local it = framework.test
local describe = framework.describe

describe('help_lines', {
  it('returns key bindings', function()
    local result = help.help_lines()

    assert.same({
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
