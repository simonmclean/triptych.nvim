local u = require 'tryptic.utils'

local TrypticState = {}

---@return TrypticState
function TrypticState.new(config, opening_win)
  local instance = {}
  setmetatable(instance, { __index = TrypticState })

  instance.show_hidden = config.options.show_hidden
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

  return instance
end

---Add to either cut or copy list
---@param list_type 'cut' | 'copy'
---@param item_to_add PathDetails
---@return nil
function TrypticState:list_add(list_type, item_to_add)
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
function TrypticState:list_remove(list_type, item_to_remove)
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
function TrypticState:list_remove_all(list_type)
  if list_type == 'cut' then
    self.cut_list = {}
  else
    self.copy_list = {}
  end
end

---@param list_type 'cut' | 'copy'
---@param item PathDetails
---@return boolean
function TrypticState:list_contains(list_type, item)
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
function TrypticState:list_toggle(list_type, item)
  if self:list_contains(list_type, item) then
    self:list_remove(list_type, item)
  else
    self:list_add(list_type, item)
  end
end

return {
  new = TrypticState.new,
}
