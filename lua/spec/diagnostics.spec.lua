local diagnostics = require 'tryptic.diagnostics'
local mock_vim = require 'spec.mock_vim'

describe('get_sign', function()
  it('returns the sign name for a diagnostic severity', function()
    local err = diagnostics.get_sign(1)
    local warn = diagnostics.get_sign(2)
    local info = diagnostics.get_sign(3)
    local hint = diagnostics.get_sign(4)
    assert.equals(err, 'DiagnosticSignError')
    assert.equals(warn, 'DiagnosticSignWarn')
    assert.equals(info, 'DiagnosticSignInfo')
    assert.equals(hint, 'DiagnosticSignHint')
  end)
end)

describe('Diagnostics', function()
  it('exposes diagnostics per path', function()
    local v, _ = mock_vim {
      diagnostic = {
        get = function()
          return {
            { bufnr = 12, severity = 1 },
            { bufnr = 14, severity = 3 },
            { bufnr = 4, severity = 4 },
          }
        end,
      },
      api = {
        nvim_buf_get_name = function(bufnr)
          if bufnr == 12 then
            return '/a/b/foo.js'
          end
          if bufnr == 14 then
            return '/a/b/bar.js'
          end
          return '/a/b/baz.js'
        end,
      },
      fs = {
        parents = function(_)
          local i = 0
          local values = { '/a/b/', '/a/', '/' }
          return function()
            i = i + 1
            return values[i]
          end
        end,
      },
      fn = {
        getcwd = function()
          return ''
        end,
      },
      print = function(v)
        vim.print(v)
      end,
    }
    _G.tryptic_mock_vim = v
    local Diagnostics = diagnostics.new()
    assert.are.same(1, Diagnostics:get '/a/b/foo.js')
    assert.are.same(3, Diagnostics:get '/a/b/bar.js')
    assert.are.same(4, Diagnostics:get '/a/b/baz.js')
    assert.are.same(1, Diagnostics:get '/a/b/')
    assert.are.same(1, Diagnostics:get '/a/')
    assert.are.same(1, Diagnostics:get '/')
    assert.are.same(nil, Diagnostics:get '/should/not/throw.js')
  end)
end)
