local u = require 'triptych.utils'

describe('set', function()
  it('returns a copy of the table with the specified value changed', function()
    local tbl = {
      foo = 1,
      bar = 2,
    }
    local result = u.set(tbl, 'foo', 3)
    assert.are.same(3, result.foo)
  end)
end)

describe('merge_tables', function()
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
    assert.same(expected, result)
  end)

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
    assert.same(expected, result)
  end)

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
    assert.same(expected, result)
  end)
end)
