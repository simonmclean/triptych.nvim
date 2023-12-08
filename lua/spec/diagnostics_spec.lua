local diagnostics = require 'triptych.diagnostics'
local tu = require 'spec.test_utils'

describe('get_sign', function()
  it('returns the sign name for a diagnostic severity', function()
    local err = diagnostics.get_sign(1)
    local warn = diagnostics.get_sign(2)
    local info = diagnostics.get_sign(3)
    local hint = diagnostics.get_sign(4)
    assert.equal(err, 'DiagnosticSignError')
    assert.equal(warn, 'DiagnosticSignWarn')
    assert.equal(info, 'DiagnosticSignInfo')
    assert.equal(hint, 'DiagnosticSignHint')
  end)
end)

describe('Diagnostics', function()
  it('exposes diagnostics per path', function()
    _G.triptych_mock_vim = {
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
        parents = tu.iterator { '/a/b/', '/a/', '/' },
      },
      fn = {
        getcwd = function()
          return ''
        end,
      },
    }
    local Diagnostics = diagnostics.new()
    assert.same(1, Diagnostics:get '/a/b/foo.js')
    assert.same(3, Diagnostics:get '/a/b/bar.js')
    assert.same(4, Diagnostics:get '/a/b/baz.js')
    assert.same(1, Diagnostics:get '/a/b/')
    assert.same(1, Diagnostics:get '/a/')
    assert.same(1, Diagnostics:get '/')
    assert.same(nil, Diagnostics:get '/should/not/throw.js')
  end)
end)
