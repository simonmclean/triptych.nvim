local u = require 'tryptic.utils'

describe("set", function ()
  it("returns a copy of the table with the specified value changed", function ()
    local tbl = {
      foo = 1,
      bar = 2
    }
    local result = u.set(tbl, 'foo', 3)
    assert.are.same(3, result.foo)
  end)
end)
