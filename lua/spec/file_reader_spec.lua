local file_reader = require 'triptych.file_reader'
local float = require 'triptych.float'
local utils = require 'triptych.utils'

describe('read', function()
  it('reads file instantly when "bypass_debounce" param is true', function()
    local spies = {
      debounced_fn = 0,
      float = {
        buf_set_lines_from_path = {},
      },
      vim = {
        fn = {
          reltime = {},
        },
      },
      utils = {
        debounce_trailing = {},
      },
    }

    _G.triptych_mock_vim = {
      fn = {
        reltime = function(x)
          table.insert(spies.vim.fn.reltime, x or 'nil')
          return 1
        end,
      },
    }

    float.buf_set_lines_from_path = function(buf, path)
      table.insert(spies.float.buf_set_lines_from_path, { buf, path })
    end

    utils.debounce_trailing = function(fn, ms)
      table.insert(spies.utils.debounce_trailing, { type(fn), ms })
      return function(_, _)
        spies.debounced_fn = spies.debounced_fn + 1
      end
    end

    local fr = file_reader.new(250)
    fr:read(12, '/hello/world.scala', true)

    assert.same({ { 'function', 250 } }, spies.utils.debounce_trailing)
    assert.same({ 'nil' }, spies.vim.fn.reltime)
    assert.same({ { 12, '/hello/world.scala' } }, spies.float.buf_set_lines_from_path)
    assert.same(0, spies.debounced_fn)
  end)

  it('reads file instantly on first call', function()
    local spies = {
      debounced_fn = 0,
      float = {
        buf_set_lines_from_path = {},
      },
      vim = {
        fn = {
          reltime = {},
        },
      },
      utils = {
        debounce_trailing = {},
      },
    }

    _G.triptych_mock_vim = {
      fn = {
        reltime = function(x)
          table.insert(spies.vim.fn.reltime, x or 'nil')
          return 1
        end,
      },
    }

    float.buf_set_lines_from_path = function(buf, path)
      table.insert(spies.float.buf_set_lines_from_path, { buf, path })
    end

    utils.debounce_trailing = function(fn, ms)
      table.insert(spies.utils.debounce_trailing, { type(fn), ms })
      return function(_, _)
        spies.debounced_fn = spies.debounced_fn + 1
      end
    end

    local fr = file_reader.new(250)
    fr:read(12, '/hello/world.scala')

    assert.same({ { 'function', 250 } }, spies.utils.debounce_trailing)
    assert.same({ 'nil' }, spies.vim.fn.reltime)
    assert.same({ { 12, '/hello/world.scala' } }, spies.float.buf_set_lines_from_path)
    assert.same(0, spies.debounced_fn)
  end)

  it('debounces the fn', function()
    local spies = {
      debounced_fn = {},
      vim = {
        fn = {
          reltime = {},
          reltimefloat = {},
        },
      },
      utils = {
        debounce_trailing = {},
      },
    }

    _G.triptych_mock_vim = {
      fn = {
        reltime = function(x)
          table.insert(spies.vim.fn.reltime, x or 'nil')
          return 1
        end,
        reltimefloat = function(x)
          table.insert(spies.vim.fn.reltimefloat, x)
          return 0.001
        end,
      },
    }

    utils.debounce_trailing = function(fn, ms)
      table.insert(spies.utils.debounce_trailing, { type(fn), ms })
      return function(buf, path)
        table.insert(spies.debounced_fn, { buf, path })
      end
    end

    local fr = file_reader.new(250)
    fr.last_called = 123 -- value doesn't matter, just bypassing nil check
    fr:read(12, '/hello/world.scala')

    assert.same({ { 'function', 250 } }, spies.utils.debounce_trailing)
    assert.same({ 123, 'nil' }, spies.vim.fn.reltime)
    assert.same({ 1 }, spies.vim.fn.reltimefloat)
    assert.same({ { 12, '/hello/world.scala' } }, spies.debounced_fn)
  end)
end)

describe('destroy', function()
  it('calls close on the timer', function()
    local spy = 0

    _G.triptych_mock_vim = {
      fn = {
        reltime = function(_)
          return 1
        end,
      },
    }

    utils.debounce_trailing = function(_, _)
      local noop = function() end
      local mock_timer = {
        close = function()
          spy = spy + 1
        end,
      }
      return noop, mock_timer
    end

    local fr = file_reader.new(250)

    fr:destroy()

    assert.same(1, spy)
  end)
end)
