local view = require 'tryptic.view'

local Mappings = {}

---@param state TrypticState
function Mappings.new(state, actions)
  local mappings = vim.g.tryptic_config.mappings
  local extension_mappings = vim.g.tryptic_config.extension_mappings

  ---@param mode string
  ---@param key_or_keys string | string[]
  ---@param fn fun(): nil
  local function map(mode, key_or_keys, fn)
    if type(key_or_keys) == 'string' then
      vim.keymap.set(mode, key_or_keys, fn, { buffer = 0 })
    else
      for _, key in pairs(key_or_keys) do
        vim.keymap.set(mode, key, fn, { buffer = 0 })
      end
    end
  end

  -----------------------------------------
  -- Mappings for built-in functionality --
  -----------------------------------------

  map('n', mappings.nav_left, function()
    local focused_path = state.windows.current.path
    local parent_path = state.windows.parent.path
    if parent_path ~= '/' then
      view.nav_to(state, parent_path, focused_path)
    end
  end)

  map('n', mappings.nav_right, function()
    local target = view.get_target_under_cursor(state)
    -- TODO: edit_file should be called from nav_to
    if vim.fn.isdirectory(target.path) == 1 then
      view.nav_to(state, target.path)
    else
      actions.edit_file(target.path)
    end
  end)

  map('n', mappings.jump_to_cwd, function()
    view.jump_to_cwd(vim.g.tryptic_get_state())
  end)
  map('n', mappings.delete, actions.delete)
  map('v', mappings.delete, actions.bulk_delete)
  map('n', mappings.add, actions.add_file_or_dir)
  map('n', mappings.copy, actions.toggle_copy)
  map('v', mappings.copy, actions.bulk_toggle_copy)
  map('n', mappings.rename, actions.rename)
  map('n', mappings.cut, actions.toggle_cut)
  map('v', mappings.cut, actions.bulk_toggle_cut)
  map('n', mappings.paste, actions.paste)
  map('n', mappings.show_help, actions.help)
  map('n', mappings.toggle_hidden, actions.toggle_hidden)
  map('n', mappings.quit, function()
    vim.g.tryptic_close()
  end)
  map('v', mappings.quit, function()
    vim.g.tryptic_close()
  end)

  -----------------------------------------
  ----------- Extension mappings ----------
  -----------------------------------------
  for key, ext_mapping in pairs(extension_mappings) do
    map(ext_mapping.mode, key, function()
      ext_mapping.fn(view.get_target_under_cursor(state))
    end)
  end
end

return {
  new = Mappings.new,
}
