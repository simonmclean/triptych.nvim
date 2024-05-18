local view = require 'triptych.view'

local Mappings = {}

---@param State TriptychState
---@param actions unknown
---@param refresh fun(): nil
function Mappings.new(State, actions, refresh_fn)
  local vim = _G.triptych_mock_vim or vim
  local mappings = vim.g.triptych_config.mappings
  local extension_mappings = vim.g.triptych_config.extension_mappings

  ---@param mode string
  ---@param key_or_keys string | string[]
  ---@param fn fun(): nil
  local function map(mode, key_or_keys, fn)
    if type(key_or_keys) == 'string' then
      vim.keymap.set(mode, key_or_keys, fn, { buffer = 0, nowait = true })
    else
      for _, key in pairs(key_or_keys) do
        vim.keymap.set(mode, key, fn, { buffer = 0, nowait = true })
      end
    end
  end

  -----------------------------------------
  -- Mappings for built-in functionality --
  -----------------------------------------

  map('n', mappings.nav_left, actions.nav_left)
  map('n', mappings.nav_right, actions.nav_right)
  map('n', mappings.open_tab, actions.open_tab)
  map('n', mappings.open_hsplit, actions.open_hsplit)
  map('n', mappings.open_vsplit, actions.open_vsplit)
  map('n', mappings.cd, actions.cd)
  map('n', mappings.jump_to_cwd, actions.jump_to_cwd)
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
    vim.g.triptych_close() -- TODO: Move to actions
  end)
  map('v', mappings.quit, function()
    vim.g.triptych_close()
  end)

  -----------------------------------------
  ----------- Extension mappings ----------
  -----------------------------------------
  for key, ext_mapping in pairs(extension_mappings) do
    map(ext_mapping.mode, key, function()
      ext_mapping.fn(view.get_target_under_cursor(State), refresh_fn)
    end)
  end
end

return {
  new = Mappings.new,
}
