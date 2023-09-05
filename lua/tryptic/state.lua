local u = require 'tryptic.utils'
local log = require 'tryptic.logger'

---@type ViewState
local initial_view_state = {
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
}
local __view_state = initial_view_state
local view_state = {
  ---@param s ViewState
  ---@return nil
  set = function(s)
    log('view_state.set', s, 'DEBUG')
    __view_state = s
  end,

  ---@return ViewState
  get = function()
    return __view_state
  end,

  ---@return nil
  reset = function()
    __view_state = initial_view_state
  end,
}

local function dir_contents_list_factory()
  ---@type DirContents[]
  local list = {}
  local this = {}
  this = {
    ---@param item_to_add DirContents
    ---@return nil
    add = function(item_to_add)
      local index = u.list_index_of(list, function(item)
        return item_to_add.path == item.path
      end)
      if index == -1 then
        table.insert(list, item_to_add)
      end
    end,

    ---@param target DirContents
    ---@return nil
    remove = function(target)
      local index = u.list_index_of(list, function(list_item)
        return target.path == list_item.path
      end)
      if index > -1 then
        table.remove(list, index)
      end
    end,

    ---@return nil
    remove_all = function()
      list = {}
    end,

    ---@param item DirContents
    ---@return nil
    toggle = function(item)
      if this.contains(item) then
        this.remove(item)
      else
        this.add(item)
      end
    end,

    ---@param item DirContents
    ---@return boolean
    contains = function(item)
      for _, value in ipairs(list) do
        if value.path == item.path then
          return true
        end
      end
      return false
    end,

    ---@return DirContents[]
    get = function()
      return list
    end,
  }
  return this
end

local cut_list = dir_contents_list_factory()

local copy_list = dir_contents_list_factory()

---@type { [string]: integer }
local __path_to_line_map = {}
local path_to_line_map = {
  ---@param path string
  ---@param line_number number
  ---@return nil
  set = function(path, line_number)
    __path_to_line_map[path] = line_number
  end,

  get = function(index)
    return __path_to_line_map[index]
  end,

  ---@return nil
  remove_all = function()
    __path_to_line_map = {}
  end,
}

---@type number | nil
local __opening_win = nil
local opening_win = {
  get = function()
    return __opening_win
  end,

  ---@param win_id number
  set = function(win_id)
    __opening_win = win_id
  end,

  ---@return nil
  to_nil = function()
    __opening_win = nil
  end,
}

local __tryptic_open = false
local tryptic_open = {
  ---@param v boolean
  ---@return nil
  set = function(v)
    __tryptic_open = v
  end,

  is_open = function()
    return __tryptic_open == true
  end,
}

---@return nil
local function initialise_state()
  view_state.reset()
  path_to_line_map.remove_all()
  cut_list.remove_all()
  copy_list.remove_all()
  opening_win.to_nil()
end

return {
  cut_list = cut_list,
  copy_list = copy_list,
  path_to_line_map = path_to_line_map,
  initialise_state = initialise_state,
  opening_win = opening_win,
  view_state = view_state,
  tryptic_open = tryptic_open,
}
