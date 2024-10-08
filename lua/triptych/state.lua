local u = require 'triptych.utils'

---@class TriptychState
---@field new fun(config: TriptychConfig, opening_win: integer): TriptychState
---@field list_add fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_remove fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_remove_all fun(self: TriptychState, list_type: 'cut' | 'copy'): nil
---@field list_toggle fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_contains fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field windows ViewState
---@field cut_list PathDetails[]
---@field copy_list PathDetails[]
---@field path_to_line_map { [string]: integer }
---@field opening_win integer
---@field show_hidden boolean
---@field collapse_dirs boolean
---@field has_initial_cursor_pos_been_set boolean
local TriptychState = {}

---@return TriptychState
function TriptychState.new(config, opening_win)
  local instance = {}
  setmetatable(instance, { __index = TriptychState })

  instance.show_hidden = config.options.show_hidden
  instance.collapse_dirs = config.options.collapse_dirs
  instance.windows = {
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
  instance.copy_list = {}
  instance.cut_list = {}
  instance.opening_win = opening_win
  instance.path_to_line_map = {}
  instance.has_initial_cursor_pos_been_set = false

  return instance
end

---Add to either cut or copy list
---@param list_type 'cut' | 'copy'
---@param item_to_add PathDetails
---@return nil
function TriptychState:list_add(list_type, item_to_add)
  local list = u.cond(list_type == 'cut', {
    when_true = self.cut_list,
    when_false = self.copy_list,
  })
  local index = u.list_index_of(list, function(list_item)
    return item_to_add.path == list_item.path
  end)
  if index == -1 then
    table.insert(list, item_to_add)
  end
end

---@param list_type 'cut' | 'copy'
---@param item_to_remove PathDetails
---@return nil
function TriptychState:list_remove(list_type, item_to_remove)
  local list = u.cond(list_type == 'cut', {
    when_true = self.cut_list,
    when_false = self.copy_list,
  })
  local index = u.list_index_of(list, function(list_item)
    return item_to_remove.path == list_item.path
  end)
  if index > -1 then
    table.remove(list, index)
  end
end

---@param list_type 'cut' | 'copy'
---@return nil
function TriptychState:list_remove_all(list_type)
  if list_type == 'cut' then
    self.cut_list = {}
  else
    self.copy_list = {}
  end
end

---@param list_type 'cut' | 'copy'
---@param item PathDetails
---@return boolean
function TriptychState:list_contains(list_type, item)
  local list = u.cond(list_type == 'cut', {
    when_true = self.cut_list,
    when_false = self.copy_list,
  })
  for _, value in ipairs(list) do
    if value.path == item.path then
      return true
    end
  end
  return false
end

---@param list_type 'cut' | 'copy'
---@param item PathDetails
---@return nil
function TriptychState:list_toggle(list_type, item)
  if self:list_contains(list_type, item) then
    self:list_remove(list_type, item)
  else
    self:list_add(list_type, item)
  end
end

return {
  new = TriptychState.new,
}
