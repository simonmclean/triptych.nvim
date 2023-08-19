local u = require 'tryptic.utils'
local log = require 'tryptic.logger'

local initial_view_state = {
  parent = {
    win = nil,
  },
  current = {
    win = nil,
  },
  child = {
    win = nil,
  },
}
local __view_state = initial_view_state
local view_state = {
  set = function(s)
    log('view_state.set', s, 'DEBUG')
    __view_state = s
  end,

  get = function()
    return __view_state
  end,

  reset = function()
    __view_state = initial_view_state
  end,
}

local __cut_list = {}
local cut_list = {
  add = function(item)
    table.insert(__cut_list, item)
  end,

  remove = function(index)
    table.remove(__cut_list, index)
  end,

  remove_all = function()
    __cut_list = {}
  end,

  index_of = function(needle)
    return u.list_index_of(__cut_list, function(list_item)
      return needle == list_item.path
    end)
  end,

  get = function()
    return __cut_list
  end,
}

local __path_to_line_map = {}
local path_to_line_map = {
  set = function(path, line_number)
    __path_to_line_map[path] = line_number
  end,

  get = function(index)
    return __path_to_line_map[index]
  end,

  remove_all = function()
    __path_to_line_map = {}
  end,
}

local __opening_win = nil
local opening_win = {
  get = function()
    return __opening_win
  end,

  set = function(win_id)
    __opening_win = win_id
  end,

  to_nil = function()
    __opening_win = nil
  end,
}

local __tryptic_open = false
local tryptic_open = {
  set = function(v)
    __tryptic_open = v
  end,

  is_open = function()
    return __tryptic_open == true
  end,
}

local function initialise_state()
  view_state.reset()
  path_to_line_map.remove_all()
  cut_list.remove_all()
  opening_win.to_nil()
end

return {
  cut_list = cut_list,
  path_to_line_map = path_to_line_map,
  initialise_state = initialise_state,
  opening_win = opening_win,
  view_state = view_state,
  tryptic_open = tryptic_open,
}
