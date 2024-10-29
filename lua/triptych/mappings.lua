local utils = require 'triptych.utils'
local view = require 'triptych.view'

local Mappings = {}

---@param State TriptychState
---@param actions unknown
---@param refresh_fn fun(): nil
function Mappings.new(State, actions, refresh_fn)
  local mappings = vim.g.triptych_config.mappings
  local extension_mappings = vim.g.triptych_config.extension_mappings

  ---@param mode string
  ---@param key_or_keys string | string[]
  ---@param fn fun(): nil
  ---@param opts table
  local function map(mode, key_or_keys, fn, opts)
    opts = utils.merge_tables({ buffer = 0, nowait = true }, opts)
    if type(key_or_keys) == 'string' then
      vim.keymap.set(mode, key_or_keys, fn, opts)
    else
      for _, key in pairs(key_or_keys) do
        vim.keymap.set(mode, key, fn, opts)
      end
    end
  end

  -----------------------------------------
  -- Mappings for built-in functionality --
  -----------------------------------------

  map('n', mappings.nav_left, actions.nav_left, { desc = 'navigate left' })
  map('n', mappings.nav_right, actions.nav_right, { desc = 'navigate right' })
  map('n', mappings.open_tab, actions.open_tab, { desc = 'open in new tab' })
  map('n', mappings.open_hsplit, actions.open_hsplit, { desc = 'open in horizontal split' })
  map('n', mappings.open_vsplit, actions.open_vsplit, { desc = 'open in vertical split' })
  map('n', mappings.cd, actions.cd, { desc = 'change directory' })
  map('n', mappings.jump_to_cwd, actions.jump_to_cwd, { desc = 'jump to current directory' })
  map('n', mappings.delete, actions.delete, { desc = 'delete' })
  map('v', mappings.delete, actions.bulk_delete, { desc = 'delete selection' })
  map('n', mappings.add, actions.add_file_or_dir, { desc = 'add file or directory' })
  map('n', mappings.copy, actions.toggle_copy, { desc = 'copy' })
  map('v', mappings.copy, actions.bulk_toggle_copy, { desc = 'copy selection' })
  map('n', mappings.rename, actions.rename, { desc = 'rename' })
  map('n', mappings.cut, actions.toggle_cut, { desc = 'cut' })
  map('v', mappings.cut, actions.bulk_toggle_cut, { desc = 'cut selection' })
  map('n', mappings.paste, actions.paste, { desc = 'paste' })
  map('n', mappings.show_help, actions.help, { desc = 'show help' })
  map('n', mappings.toggle_hidden, actions.toggle_hidden, { desc = 'toggle hidden' })
  map('n', mappings.toggle_collapse_dirs, actions.toggle_collapse_dirs, { desc = 'toggle collapse directories' })
  map('n', mappings.quit, function()
    vim.g.triptych_close() -- TODO: Move to actions
  end, { desc = 'quit' })
  map('v', mappings.quit, function()
    vim.g.triptych_close()
  end, { desc = 'quit' })

  -----------------------------------------
  ----------- Extension mappings ----------
  -----------------------------------------
  for key, ext_mapping in pairs(extension_mappings) do
    map(ext_mapping.mode, key, function()
      ext_mapping.fn(view.get_target_under_cursor(State), refresh_fn)
    end, {})
  end
end

return {
  new = Mappings.new,
}
