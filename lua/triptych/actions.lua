local u = require 'triptych.utils'
local float = require 'triptych.float'
local view = require 'triptych.view'
local plenary_path = require 'plenary.path'
local triptych_help = require 'triptych.help'

local Actions = {}

--- TODO: Return type
---@param State TriptychState
---@param refresh_view fun(): nil
function Actions.new(State, refresh_view)
  local vim = _G.triptych_mock_vim or vim

  local M = {}

  ---@return nil
  M.help = function()
    local win = State.windows.child.win
    float.win_set_title(win, 'Help', '󰋗', 'Directory')
    float.win_set_lines(win, triptych_help.help_lines())
  end

  ---@return nil
  M.delete = function()
    local target = view.get_target_under_cursor(State)
    if target then
      local prompt = 'Are you sure you want to delete "' .. target.display_name .. '"?'
      vim.ui.select({ 'Yes', 'No' }, { prompt = prompt }, function(response)
        if u.is_defined(response) and response == 'Yes' then
          vim.fn.delete(target.path, 'rf')
          refresh_view()
        end
      end)
    end
  end

  ---@param _targets PathDetails[]
  ---@param skip_confirm boolean
  ---@return nil
  M.bulk_delete = function(_targets, skip_confirm)
    local targets = _targets or view.get_targets_in_selection(State)

    if u.is_empty(targets) then
      return
    end

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
    vim = _G.triptych_mock_vim or vim
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
    if target then
      State:list_remove('copy', target)
      State:list_toggle('cut', target)
      refresh_view()
    end
  end

  ---@return nil
  M.toggle_copy = function()
    local target = view.get_target_under_cursor(State)
    if target then
      State:list_remove('cut', target)
      State:list_toggle('copy', target)
      refresh_view()
    end
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
  ---@param callback? fun(boolean) - Callback indicting whether an item an copied
  ---@return nil
  M.duplicate_file_or_dir = function(target, destination, callback)
    local p = plenary_path:new(target.path)
    local results = p:copy {
      destination = destination,
      recursive = true,
      override = false,
      interactive = true,
    }
    if callback then
      for _, v in pairs(results) do
        callback(v)
      end
    end
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
    if target then
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
  end

  --- Checks if the path we're trying to copy-paste into already exists. If it doesn't then it returns the path unchanged.
  --- Otherwise it recursively finds a unique path by appending  "_copy<index>.<extension>" to the filename,
  ---@param target_path string
  ---@param copy_increment? integer
  ---@return string
  local function get_copy_path(target_path, copy_increment)
    -- If target path does not exist then return it
    if vim.fn.filereadable(target_path) == 0 then
      return target_path
    end
    -- Otherwise find a unique target path by appending "_copy<i>"
    local i = copy_increment or 1
    local dir = vim.fn.fnamemodify(target_path, ':p:h')
    local extension = vim.fn.fnamemodify(target_path, ':e')
    local filename_without_extension = vim.fn.fnamemodify(target_path, ':t:r')
    local copy_path = u.string_join('', {
      dir,
      '/',
      filename_without_extension,
      '_copy',
      tostring(i),
      '.',
      extension,
    })
    if vim.fn.filereadable(copy_path) == 0 then
      return copy_path
    end
    return get_copy_path(target_path, i + 1)
  end

  ---@return nil
  M.paste = function()
    local cursor_target = view.get_target_under_cursor(State)
    local destination_dir = u.eval(function()
      if not cursor_target then
        return State.windows.current.path
      end
      if cursor_target.is_dir then
        return cursor_target.path
      end
      return cursor_target.dirname
    end)
    ---@type PathDetails[]
    local delete_list = {}

    local success, result = pcall(function()
      -- Handle cut items
      for _, item in ipairs(State.cut_list) do
        local destination = u.path_join(destination_dir, item.display_name)
        if item.path ~= destination then
          M.duplicate_file_or_dir(item, destination, function(was_copied)
            -- Note that we don't want to error when was_copied is false
            -- This is because it could mean that the user declined to override an existing file, which obviously isn't an error.
            if was_copied then
              table.insert(delete_list, item)
            end
          end)
        end
      end
      M.bulk_delete(delete_list, true)
      -- Handle copy items
      for _, item in ipairs(State.copy_list) do
        local destination = get_copy_path(u.path_join(destination_dir, item.display_name))
        M.duplicate_file_or_dir(item, destination)
      end
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
  ---@param kind 'in-place' | 'vsplit' | 'hsplit' | 'tab'
  ---@return nil
  local function edit_file(path, kind)
    vim.g.triptych_close()
    if kind == 'in-place' then
      vim.cmd.edit(path)
    elseif kind == 'hsplit' then
      vim.cmd.split(path)
    elseif kind == 'vsplit' then
      vim.cmd.vsplit(path)
    elseif kind == 'tab' then
      vim.cmd.tabedit(path)
    end
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
    -- If we're already in the root directory, nav back to the previous directory (if we have that in memory)
    if win.path == cwd and u.is_defined(win.previous_path) then
      view.set_primary_and_parent_window_targets(State, win.previous_path)
    elseif cwd then
      view.set_primary_and_parent_window_targets(State, cwd)
    end
  end

  M.nav_left = function()
    local parent_path = State.windows.parent.path
    if parent_path ~= '/' then
      view.set_primary_and_parent_window_targets(State, parent_path)
    end
  end

  M.nav_right = function()
    local target = view.get_target_under_cursor(State)
    if target then
      if target.is_dir then
        view.set_primary_and_parent_window_targets(State, target.path)
      else
        edit_file(target.path, 'in-place')
      end
    end
  end

  M.open_hsplit = function()
    local target = view.get_target_under_cursor(State)
    if target then
      if not target.is_dir then
        edit_file(target.path, 'hsplit')
      end
    end
  end

  M.open_vsplit = function()
    local target = view.get_target_under_cursor(State)
    if target then
      if not target.is_dir then
        edit_file(target.path, 'vsplit')
      end
    end
  end

  M.open_tab = function()
    local target = view.get_target_under_cursor(State)
    if target then
      if not target.is_dir then
        edit_file(target.path, 'tab')
      end
    end
  end

  M.cd = function()
    local target = view.get_target_under_cursor(State)
    if target then
      if target.is_dir then
        vim.api.nvim_set_current_dir(target.path)
        M.nav_right()
      else
        vim.api.nvim_set_current_dir(target.dirname)
      end
      refresh_view()
    end
  end

  return M
end

return {
  new = Actions.new,
}
