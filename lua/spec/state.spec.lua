local u = require 'tryptic.utils'
local state = require 'tryptic.state'
local config = require 'tryptic.config'

---@return DirContents
local function create_dir_contents()
  return {
    path = '/hello/world.js',
    display_name = 'world.js',
    dirname = '/hello/',
    basename = 'world.js',
    is_dir = false,
    is_git_ignored = false,
    cutting = false,
  }
end

local conf = config.create_merged_config {}

describe('new', function()
  it('sets initial values', function()
    local opening_winid = 4
    local s = state.new(conf, opening_winid)
    assert.are.same(s.windows, {
      parent = {
        path = '',
        win = -1,
      },
      current = {
        previous_path = '',
        win = -1,
      },
      child = {
        win = -1,
      },
    })
    assert.are.equal(s.show_hidden, conf.options.show_hidden)
    assert.are.same({}, s.cut_list)
    assert.are.same({}, s.copy_list)
    assert.are.same({}, s.path_to_line_map)
    assert.are.equal(opening_winid, s.opening_win)
  end)
end)

describe('list_add', function()
  it('adds to the copy list', function()
    local s = state.new(conf)
    local item = create_dir_contents()
    s:list_add('copy', item)
    assert.are.equal(#s.copy_list, 1)
    assert.are.same(item, s.copy_list[1])
  end)

  it('adds to the cut list', function()
    local s = state.new(conf)
    local item = create_dir_contents()
    s:list_add('cut', item)
    assert.are.equal(#s.cut_list, 1)
    assert.are.same(item, s.cut_list[1])
  end)
end)

describe('list_remove', function()
  it('removes from the copy list', function()
    local s = state.new(conf)
    local item1 = create_dir_contents()
    local item2 = u.set(item1, 'path', 'foo')
    local item3 = u.set(item1, 'path', 'bar')
    s:list_add('copy', item1)
    s:list_add('copy', item2)
    s:list_add('copy', item3)
    s:list_remove('copy', item1)
    assert.are.same(2, #s.copy_list)
    assert.are.same(item2, s.copy_list[1])
    assert.are.same(item3, s.copy_list[2])
  end)

  it('removes from the cut list', function()
    local s = state.new(conf)
    local item1 = create_dir_contents()
    local item2 = u.set(item1, 'path', 'foo')
    local item3 = u.set(item1, 'path', 'bar')
    s:list_add('cut', item1)
    s:list_add('cut', item2)
    s:list_add('cut', item3)
    s:list_remove('cut', item1)
    assert.are.same(2, #s.cut_list)
    assert.are.same(item2, s.cut_list[1])
    assert.are.same(item3, s.cut_list[2])
  end)
end)

describe('list_remove_all', function()
  it('removes all items from the copy list', function()
    local item1 = create_dir_contents()
    local item2 = u.set(item1, 'path', 'foo')
    local s = state.new(conf)
    s:list_add('copy', item1)
    s:list_add('copy', item2)
    s:list_remove_all 'copy'
    assert.are.same(0, #s.copy_list)
  end)

  it('removes all items from the cut list', function()
    local item1 = create_dir_contents()
    local item2 = u.set(item1, 'path', 'foo')
    local s = state.new(conf)
    s:list_add('cut', item1)
    s:list_add('cut', item2)
    s:list_remove_all 'cut'
    assert.are.same(0, #s.cut_list)
  end)
end)

describe('list_contains', function()
  it('returns true if item is in copy list', function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local item2 = u.set(create_dir_contents(), 'path', 'bar')
    local s = state.new(conf)
    s:list_add('copy', item1)
    s:list_add('copy', item2)
    local result = s:list_contains('copy', item2)
    assert.is_true(result)
  end)

  it('returns true if item is in cut list', function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local item2 = u.set(create_dir_contents(), 'path', 'bar')
    local s = state.new(conf)
    s:list_add('cut', item1)
    s:list_add('cut', item2)
    local result = s:list_contains('cut', item2)
    assert.is_true(result)
  end)

  it('returns false if item is not in copy list', function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local item2 = u.set(create_dir_contents(), 'path', 'bar')
    local item3 = u.set(create_dir_contents(), 'path', 'baz')
    local s = state.new(conf)
    s:list_add('copy', item1)
    s:list_add('copy', item2)
    local result = s:list_contains('copy', item3)
    assert.is_false(result)
  end)

  it('returns false if item is not in cut list', function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local item2 = u.set(create_dir_contents(), 'path', 'bar')
    local item3 = u.set(create_dir_contents(), 'path', 'baz')
    local s = state.new(conf)
    s:list_add('cut', item1)
    s:list_add('cut', item2)
    local result = s:list_contains('cut', item3)
    assert.is_false(result)
  end)
end)

describe('list_toggle', function()
  it("add item to copy list if it's not already present", function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local s = state.new(conf)
    s:list_toggle('copy', item1)
    assert.are.same(item1, s.copy_list[1])
  end)

  it("removes item from copy list if it's already present", function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local s = state.new(conf)
    s:list_add('copy', item1)
    s:list_toggle('copy', item1)
    assert.are.same(0, #s.copy_list)
  end)

  it("add item to cut list if it's not already present", function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local s = state.new(conf)
    s:list_toggle('cut', item1)
    assert.are.same(item1, s.cut_list[1])
  end)

  it("removes item from cut list if it's already present", function()
    local item1 = u.set(create_dir_contents(), 'path', 'foo')
    local s = state.new(conf)
    s:list_add('cut', item1)
    s:list_toggle('cut', item1)
    assert.are.same(0, #s.cut_list)
  end)
end)
