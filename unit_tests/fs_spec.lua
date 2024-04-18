local fs = require 'triptych.fs'
local plenary_filetype = require 'plenary.filetype'

describe('get_filetype_from_path', function()
  it('uses plenary detect', function()
    local spy = {}
    plenary_filetype.detect = function(path)
      table.insert(spy, path)
      return ''
    end
    fs.get_filetype_from_path './hello'
    assert.same({ './hello' }, spy)
  end)
end)

describe('get_file_size_in_kb', function()
  it('returns vim.fn.getfsize / 1000', function()
    local spy = {}
    _G.triptych_mock_vim = {
      fn = {
        getfsize = function(path)
          table.insert(spy, path)
          return 2000
        end,
      },
    }
    local result = fs.get_file_size_in_kb 'hello'
    assert.same({ 'hello' }, spy)
    assert.same(2, result)
  end)
end)
