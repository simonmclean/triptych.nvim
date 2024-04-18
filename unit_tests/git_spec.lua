local git = require 'triptych.git'
local tu = require 'unit_tests.test_utils'
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
