local u = require 'tryptic.utils'
local float = require 'tryptic.float'
local view = require 'tryptic.view'
local plenary_path = require 'plenary.path'
local tryptic_help = require 'tryptic.help'

local Actions = {}

--- TODO: Return type
---@param State TrypticState
---@param refresh_view fun(): nil
---@param Diagnostics? Diagnostics
---@param Git? Git
function Actions.new(State, refresh_view, Diagnostics, Git)
  local vim = _G.tryptic_mock_vim or vim

  local M = {}

  ---@return nil
  M.help = function()
    local win = State.windows.child.win
    float.win_set_title(win, 'Help', '󰋗', 'Directory')
    float.win_set_lines(win, tryptic_help.help_lines())
  end

  ---@return nil
  M.delete = function()
    local target = view.get_target_under_cursor(State)
    local prompt = 'Are you sure you want to delete "' .. target.display_name .. '"?'
    vim.ui.select({ 'Yes', 'No' }, { prompt = prompt }, function(response)
      if u.is_defined(response) and response == 'Yes' then
        vim.fn.delete(target.path, 'rf')
        refresh_view()
      end
    end)
  end

  ---@param _targets PathDetails[]
  ---@param skip_confirm boolean
  ---@return nil
  M.bulk_delete = function(_targets, skip_confirm)
    local targets = _targets or view.get_targets_in_selection(State)

    if skip_confirm then
      for _, target in ipairs(targets) do
        vim.fn.delete(target.path, 'rf')
      end
      refresh_view()
    else
      local prompt = 'Are you sure you want to delete these ' .. #targets .. ' items?'
      vim.ui.select({ 'Yes', 'No' }, {
        prompt = prompt,
      }, function(response)
        if u.is_defined(response) and response == 'Yes' then
          for _, target in ipairs(targets) do
            local success, result = pcall(function()
              vim.fn.delete(target.path, 'rf')
            end)
            if not success then
              vim.print('Error deleting item', result)
            end
          end
          refresh_view()
        end
      end)
    end
  end

  ---@return nil
  M.add_file_or_dir = function()
    vim = _G.tryptic_mock_vim or vim
    local current_directory = State.windows.current.path
    local response = vim.fn.trim(vim.fn.input 'Enter name for new file or directory (dirs end with a "/"): ')
    if u.is_empty(response) then
      return
    end
    local response_length = string.len(response)
    local includes_file = string.sub(response, response_length, response_length) ~= '/'
    if includes_file then
      local includes_dirs = string.find(response, '/') ~= nil

      if includes_dirs then
        local length_of_filename = string.find(string.reverse(response), '/') - 1
        local filename = string.sub(response, response_length - length_of_filename + 1, response_length)
        local dirs_to_create = string.sub(response, 1, response_length - length_of_filename)
        local absolute_dir_path = u.path_join(current_directory, dirs_to_create)
        vim.fn.mkdir(absolute_dir_path, 'p')
        -- TODO: writefile is destructive. Add checking
        vim.fn.writefile({}, absolute_dir_path .. filename)
      else
        vim.fn.writefile({}, u.path_join(current_directory, response))
      end
    else
      vim.fn.mkdir(u.path_join(current_directory, response), 'p')
    end

    refresh_view()
  end

  ---@return nil
  M.toggle_cut = function()
    local target = view.get_target_under_cursor(State)
    State:list_remove('copy', target)
    State:list_toggle('cut', target)
    refresh_view()
  end

  ---@return nil
  M.toggle_copy = function()
    local target = view.get_target_under_cursor(State)
    State:list_remove('cut', target)
    State:list_toggle('copy', target)
    refresh_view()
  end

  ---@return nil
  M.bulk_toggle_cut = function()
    local targets = view.get_targets_in_selection(State)
    local contains_cut_items = false
    local contains_uncut_items = false
    for _, target in ipairs(targets) do
      if State:list_contains('cut', target) then
        contains_cut_items = true
      else
        contains_uncut_items = true
      end
    end
    local is_mixed = contains_cut_items and contains_uncut_items
    for _, target in ipairs(targets) do
      if is_mixed or not State:list_contains('cut', target) then
        State:list_add('cut', target)
      else
        State:list_remove('cut', target)
      end
    end
    State:list_remove_all 'copy'
    refresh_view()
  end

  ---@param target PathDetails
  ---@param destination string
  ---@return nil
  M.duplicate_file_or_dir = function(target, destination)
    local p = plenary_path:new(target.path)
    p:copy {
      destination = destination,
      recursive = true,
      override = false,
      interactive = true,
    }
  end

  M.bulk_toggle_copy = function()
    local targets = view.get_targets_in_selection(State)
    local contains_copy_items = false
    local contains_noncopy_items = false
    for _, target in ipairs(targets) do
      if State:list_contains('copy', target) then
        contains_copy_items = true
      else
        contains_noncopy_items = true
      end
    end
    local is_mixed = contains_copy_items and contains_noncopy_items
    for _, target in ipairs(targets) do
      if is_mixed or not State:list_contains('copy', target) then
        State:list_add('copy', target)
      else
        State:list_remove('copy', target)
      end
    end
    State:list_remove_all 'cut'
    refresh_view()
  end

  ---@return nil
  M.rename = function()
    local target = view.get_target_under_cursor(State)
    local display_name = u.cond(target.is_dir, {
      when_true = u.trim_last_char(target.display_name),
      when_false = target.display_name,
    })
    local response = vim.fn.trim(vim.fn.input('Enter new name for "' .. display_name .. '": '))
    if u.is_defined(response) and response ~= target.display_name then
      vim.fn.rename(target.path, u.path_join(target.dirname, response))
      refresh_view()
    end
  end

  ---@return nil
  M.paste = function()
    local cursor_target = view.get_target_under_cursor(State)
    local destination_dir = u.cond(cursor_target.is_dir, {
      when_true = cursor_target.path,
      when_false = cursor_target.dirname,
    })
    ---@type PathDetails[]
    local delete_list = {}

    local success, result = pcall(function()
      -- Handle cut items
      for _, item in ipairs(State.cut_list) do
        local destination = u.path_join(destination_dir, item.basename)
        if item.path ~= destination then
          -- TODO: Don't add to delete list unless the copy was successful
          M.duplicate_file_or_dir(item, destination)
          table.insert(delete_list, item)
        end
      end
      -- Handle copy items
      for _, item in ipairs(State.copy_list) do
        local destination = u.path_join(destination_dir, item.basename)
        if item.path ~= destination then
          M.duplicate_file_or_dir(item, destination)
        end
      end
      M.bulk_delete(delete_list, true)
      view.jump_cursor_to(State, destination_dir)
    end)
    if not success then
      vim.print('Failed to paste "' .. result .. '"')
    end
    State:list_remove_all 'cut'
    State:list_remove_all 'copy'
    refresh_view()
  end

  ---@param path string
  ---@return nil
  M.edit_file = function(path)
    vim.g.tryptic_close()
    vim.cmd.edit(path)
  end

  ---@return nil
  M.toggle_hidden = function()
    if State.show_hidden then
      State.show_hidden = false
    else
      State.show_hidden = true
    end
    refresh_view()
  end

  ---@return nil
  M.jump_to_cwd = function()
    local cwd = vim.fn.getcwd()
    local win = State.windows.current
    -- If we're already in the route directory, nav back to the previous directory (if we have that in memory)
    if win.path == cwd and u.is_defined(win.previous_path) then
      view.nav_to(State, win.previous_path, Diagnostics, Git)
    elseif cwd then
      view.nav_to(State, cwd, Diagnostics, Git)
    end
  end

  M.nav_left = function()
    local focused_path = State.windows.current.path
    local parent_path = State.windows.parent.path
    if parent_path ~= '/' then
      view.nav_to(State, parent_path, Diagnostics, Git, focused_path)
    end
  end

  M.nav_right = function()
    local target = view.get_target_under_cursor(State)
    if vim.fn.isdirectory(target.path) == 1 then
      view.nav_to(State, target.path, Diagnostics, Git)
    else
      M.edit_file(target.path)
    end
  end

  return M
end

return {
  new = Actions.new,
}
