local test_u = require 'tests.utils'
local u = require 'triptych.utils'
local framework = require 'test_framework.test'
local it = framework.test
local describe = framework.describe

describe('set', {
  it('returns a copy of the table with the specified value changed', function()
    local tbl = {
      foo = 1,
      bar = 2,
    }
    local result = u.set(tbl, 'foo', 3)
    test_u.assert_same(3, result.foo)
  end),
})

describe('merge_tables', {
  it('merges tables - none empty', function()
    local a = {
      foo = 'bar',
      options = {
        relative_numbers = false,
        show_hidden = true,
      },
    }
    local b = {
      options = {
        show_hidden = false,
      },
    }
    local expected = {
      foo = 'bar',
      options = {
        relative_numbers = false,
        show_hidden = false,
      },
    }
    local result = u.merge_tables(a, b)
    test_u.assert_same(expected, result)
  end),

  it('merges tables - first one is empty', function()
    local a = {}
    local b = {
      options = {
        show_hidden = false,
      },
    }
    local expected = {
      options = {
        show_hidden = false,
      },
    }
    local result = u.merge_tables(a, b)
    test_u.assert_same(expected, result)
  end),

  it('merges tables - second one empty', function()
    local a = {
      foo = 'bar',
      options = {
        show_hidden = true,
      },
    }
    local b = {}
    local expected = {
      foo = 'bar',
      options = {
        show_hidden = true,
      },
    }
    local result = u.merge_tables(a, b)
    test_u.assert_same(expected, result)
  end),
})

describe('round', {
  it('rounds to x decimal places', function()
    test_u.assert_same(0.33, u.round(0.333, 2))
    test_u.assert_same(0.333, u.round(0.333, 3))
    test_u.assert_same(1.2, u.round(1.16, 1))
    test_u.assert_same(1.1, u.round(1.11, 1))
    test_u.assert_same(1, u.round(1.16, 0))
    test_u.assert_same(200.99, u.round(200.99, 3))
  end),
})
