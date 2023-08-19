local tryptic = require 'tryptic'
local state = require 'tryptic.state'
local view = require 'tryptic.view'
local actions = require 'tryptic.actions'

local mappings = vim.g.tryptic_config.mappings
local extension_mappings = vim.g.tryptic_config.extension_mappings

-- TODO: The contents of this file get called a bunch of times
-- Use autocmd to ensure this doesn't happen

local function map(key_or_keys, fn)
  if type(key_or_keys) == 'string' then
    vim.keymap.set('n', key_or_keys, fn, { buffer = 0 })
  else
    for _, key in pairs(key_or_keys) do
      vim.keymap.set('n', key, fn, { buffer = 0 })
    end
  end
end

-----------------------------------------
-- Mappings for built-in functionality --
-----------------------------------------

map(mappings.nav_left, function()
  local view_state = state.view_state.get()
  local focused_path = view_state.current.path
  local parent_path = view_state.parent.path
  if parent_path ~= '/' then
    view.nav_to(parent_path, focused_path)
  end
end)

map(mappings.nav_right, function()
  local target = view.get_target_under_cursor()
  -- TODO: edit_file should be called from nav_to
  if vim.fn.isdirectory(target.path) == 1 then
    view.nav_to(target.path)
  else
    actions.edit_file(target.path)
  end
end)

map(mappings.jump_to_cwd, view.jump_to_cwd)
map(mappings.delete, actions.delete)
map(mappings.add, actions.add_file_or_dir)
map(mappings.copy, actions.copy)
map(mappings.rename, actions.rename)
map(mappings.cut, actions.toggle_cut)
map(mappings.paste, actions.paste)
map(mappings.show_help, actions.help)
map(mappings.quit, tryptic.close_tryptic)

-----------------------------------------
----------- Extension mappings ----------
-----------------------------------------
for key, fn in pairs(extension_mappings) do
  map(key, function()
    fn(tryptic.get_target_under_cursor())
  end)
end
