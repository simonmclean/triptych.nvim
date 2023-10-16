local git = require 'tryptic.git'
local config = require 'tryptic.config'
local u = require 'tryptic.utils'
local tu = require 'spec.test_utils'

local mocks = {
  git_status = 'M  lua/foo.lua\nD  lua/bar.lua\nAM docs/README.md\n?? .DS_Store',
  project_root = '/hello/world',
}

describe('get_sign', function()
  it('takes an abbreviated status and returns a sign name', function()
    local conf = config.create_merged_config()

    _G.tryptic_mock_vim = {
      g = {
        tryptic_config = conf,
      },
    }

    local a = git.get_sign 'A'
    local am = git.get_sign 'AM'
    local d = git.get_sign 'D'
    local m = git.get_sign 'M'
    local r = git.get_sign 'R'
    local unknown = git.get_sign '??'
    assert.equals('GitSignsAdd', a)
    assert.equals('GitSignsAdd', am)
    assert.equals('GitSignsDelete', d)
    assert.equals('GitSignsChange', m)
    assert.equals('GitSignsRename', r)
    assert.equals('GitSignsUntracked', unknown)
  end)
end)

describe('Git.new', function()
  it('sets project_root and status', function()
    local spy = {}
    _G.tryptic_mock_vim = {
      fn = {
        getcwd = function()
          return mocks.project_root
        end,
        system = function(cmd)
          table.insert(spy, cmd)
          if cmd == 'git status --porcelain' then
            return mocks.git_status
          elseif cmd == 'git rev-parse --show-toplevel' then
            return mocks.project_root
          end
          return nil
        end,
      },
      fs = {
        parents = tu.iterator {},
      },
    }
    local Git = git.Git.new()
    assert.same({
      'git status --porcelain',
      'git rev-parse --show-toplevel',
    }, spy)
    assert.same(mocks.project_root, Git.project_root)
    assert.same({
      ['/hello/world/lua/foo.lua'] = 'M',
      ['/hello/world/lua/bar.lua'] = 'D',
      ['/hello/world/docs/README.md'] = 'AM',
      ['/hello/world/.DS_Store'] = '??',
    }, Git.status)
  end)
end)

describe('Git:status_of', function()
  it('returns the git status of a path', function()
    _G.tryptic_mock_vim = {
      fn = {
        getcwd = function()
          return mocks.project_root
        end,
        system = function(cmd)
          if cmd == 'git status --porcelain' then
            return mocks.git_status
          elseif cmd == 'git rev-parse --show-toplevel' then
            return mocks.project_root
          end
          return nil
        end,
      },
      fs = {
        parents = tu.iterator {},
      },
    }
    local Git = git.Git.new()
    assert('AM', Git:status_of '/hello/world/lua/bar.lua')
    assert('??', Git:status_of '/hello/world/docs/README.md')
  end)
end)

describe('Git:filter_ignored', function()
  it('filters out path details which are git ignored', function()
    local ignored_paths = {
      '/hello/world/foo/bar.js',
      '/hello/world/bar/baz.lua',
      '/hello/world/hello/world.js',
      '/hello/world/baz/monkey.php',
    }
    local not_ignored_paths = {
      '/hello/world/baz/monkey/monkey.php',
      '/hello/world/file.php',
    }
    local combined_paths = u.list_concat(ignored_paths, not_ignored_paths)
    local spy = {}
    _G.tryptic_mock_vim = {
      fn = {
        getcwd = function()
          return mocks.project_root
        end,
        system = function(cmd)
          if cmd == 'git status --porcelain' then
            return mocks.git_status
          elseif cmd == 'git rev-parse --show-toplevel' then
            return mocks.project_root
          elseif u.string_contains(cmd, 'git check-ignore') then
            table.insert(spy, cmd)
            return u.string_join('\n', ignored_paths)
          end
          return nil
        end,
      },
      fs = {
        parents = tu.iterator {},
      },
    }
    local Git = git.Git.new()
    local result = Git:filter_ignored(combined_paths)
    local expected_spy_result = {
      'git check-ignore ' .. u.string_join(' ', combined_paths),
    }
    assert.same(expected_spy_result, spy)
    assert.same(not_ignored_paths, result)
  end)
end)
