local git = require 'triptych.git'
local u = require 'triptych.utils'
local tu = require 'spec.test_utils'
local config = require 'triptych.config'

local mocks = {
  git_status = 'M  lua/foo.lua\nA  lua/bar.lua\nR  docs/README.md\n?? .DS_Store',
  project_root = '/hello/world',
}

describe('Git.new', function()
  it('sets project_root and status', function()
    local spies = {
      system = {},
      sign_getdefined = {},
      sign_define = {},
    }
    _G.triptych_mock_vim = {
      g = {
        triptych_config = config.create_merged_config {},
      },
      fn = {
        getcwd = function()
          return mocks.project_root
        end,
        system = function(cmd)
          table.insert(spies.system, cmd)
          if cmd == 'git status --porcelain' then
            return mocks.git_status
          elseif cmd == 'git rev-parse --show-toplevel' then
            return mocks.project_root
          end
          return nil
        end,
        sign_getdefined = function(name)
          table.insert(spies.sign_getdefined, name)
          return {}
        end,
        sign_define = function(name, conf)
          table.insert(spies.sign_define, { name, conf.text, conf.texthl })
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
    }, spies.system)
    assert.same(mocks.project_root, Git.project_root)
    assert.same({
      ['/hello/world/lua/foo.lua'] = 'M',
      ['/hello/world/lua/bar.lua'] = 'A',
      ['/hello/world/docs/README.md'] = 'R',
      ['/hello/world/.DS_Store'] = '??',
    }, Git.status)
    table.sort(spies.sign_getdefined)
    assert.same(
      { 'TriptychGitAdd', 'TriptychGitModify', 'TriptychGitRename', 'TriptychGitUntracked' },
      spies.sign_getdefined
    )
  end)
end)

describe('Git:status_of', function()
  it('returns the git status of a path', function()
    _G.triptych_mock_vim = {
      g = {
        triptych_config = config.create_merged_config {},
      },
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
        sign_getdefined = function(_)
          return { name = 'foo', text = '+', texthl = 'Error' }
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
    _G.triptych_mock_vim = {
      g = {
        triptych_config = config.create_merged_config {},
      },
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
        sign_getdefined = function(_)
          return { name = 'foo', text = '+', texthl = 'Error' }
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
