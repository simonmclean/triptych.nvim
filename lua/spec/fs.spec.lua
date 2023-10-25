local fs = require 'tryptic.fs'
local tu = require 'spec.test_utils'
local plenary_filetype = require 'plenary.filetype'

describe('get_path_details', function()
  it('returns the contents of a path', function()
    local spies = {
      fs = {
        normalize = {},
        basename = {},
        dirname = {},
        dir = {},
      },
      plenary_filetype = {
        detect = {},
      },
    }

    _G.tryptic_mock_vim = {
      g = {
        tryptic_config = {
          options = {
            dirs_first = false,
          },
        },
      },
      fs = {
        normalize = function(path)
          table.insert(spies.fs.normalize, path)
          return vim.fs.normalize(path)
        end,
        dir = tu.iterator({
          { 'd_file', 'file' },
          { 'a_file', 'file' },
          { 'b_dir', 'directory' },
          { 'x_dir', 'directory' },
        }, spies.fs.dir),
        basename = function(path)
          table.insert(spies.fs.basename, path)
          return vim.fs.basename(path)
        end,
        dirname = function(path)
          table.insert(spies.fs.dirname, path)
          return vim.fs.dirname(path)
        end,
      },
    }

    plenary_filetype.detect = function(path)
      table.insert(spies.plenary_filetype.detect, path)
      return ''
    end

    local result = fs.get_path_details '/hello/world'

    assert.same({ '/hello/world' }, spies.fs.normalize)

    assert.same({ '/hello/world' }, spies.fs.dir)

    assert.same({
      '/hello/world/d_file',
      '/hello/world/a_file',
    }, spies.plenary_filetype.detect)

    assert.same({
      children = {
        {
          path = '/hello/world/d_file',
          display_name = 'd_file',
          basename = 'd_file',
          dirname = '/hello/world',
          is_dir = false,
          filetype = '',
          children = {},
        },
        {
          path = '/hello/world/a_file',
          display_name = 'a_file',
          basename = 'a_file',
          dirname = '/hello/world',
          is_dir = false,
          filetype = '',
          children = {},
        },
        {
          path = '/hello/world/b_dir',
          display_name = 'b_dir/',
          basename = 'b_dir',
          dirname = '/hello/world',
          is_dir = true,
          children = {},
        },
        {
          path = '/hello/world/x_dir',
          display_name = 'x_dir/',
          basename = 'x_dir',
          dirname = '/hello/world',
          is_dir = true,
          children = {},
        },
      },
    }, result)
  end)

  it('sorts dirs first when the config option is true', function()
    _G.tryptic_mock_vim = {
      g = {
        tryptic_config = {
          options = {
            dirs_first = true,
          },
        },
      },
      fs = {
        normalize = function(path)
          return vim.fs.normalize(path)
        end,
        dir = tu.iterator {
          { 'd_file', 'file' },
          { 'a_file', 'file' },
          { 'b_dir', 'directory' },
          { 'x_dir', 'directory' },
        },
        basename = function(path)
          return vim.fs.basename(path)
        end,
        dirname = function(path)
          return vim.fs.dirname(path)
        end,
      },
    }

    local result = fs.get_path_details '/hello/world'

    assert.same({
      children = {
        {
          path = '/hello/world/b_dir',
          display_name = 'b_dir/',
          basename = 'b_dir',
          dirname = '/hello/world',
          is_dir = true,
          children = {},
        },
        {
          path = '/hello/world/x_dir',
          display_name = 'x_dir/',
          basename = 'x_dir',
          dirname = '/hello/world',
          is_dir = true,
          children = {},
        },
        {
          path = '/hello/world/a_file',
          display_name = 'a_file',
          basename = 'a_file',
          dirname = '/hello/world',
          is_dir = false,
          filetype = '',
          children = {},
        },
        {
          path = '/hello/world/d_file',
          display_name = 'd_file',
          basename = 'd_file',
          dirname = '/hello/world',
          is_dir = false,
          filetype = '',
          children = {},
        },
      },
    }, result)
  end)
end)

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
    _G.tryptic_mock_vim = {
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
