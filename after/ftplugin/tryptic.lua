local tryptic = require 'tryptic'

local mappings = vim.g.tryptic_config.mappings

local function map(key_or_keys, fn, include_visual)
  if type(key_or_keys) == "string" then
    vim.keymap.set('n', key_or_keys, fn, { buffer = 0 })
    if include_visual then
      vim.keymap.set('v', key_or_keys, function()
        local buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.current.win)
        local a, b, c, d = vim.api.nvim_buf_get_mark(buf, "<")
        local e, f, g = vim.api.nvim_buf_get_mark(buf, ">")
        vim.print({ a, b, c, d, e, f, g })
        -- local vis_start = vim.api.nvim_buf_get_mark(buf, '<')[2]
        -- local vis_end = vim.api.nvim_buf_get_mark(buf, '>')[2]
        -- vim.print(vis_start, vis_end)
      end, { buffer = 0 })
    end
  else
    for _, key in pairs(key_or_keys) do
      vim.keymap.set('n', key, fn, { buffer = 0 })
      if include_visual then
        vim.keymap.set('v', key, function()
        end, { buffer = 0 })
      end
    end
  end
end

map(mappings.nav_left, function()
  local focused_path = vim.g.tryptic_state.current.path
  local parent_path = vim.g.tryptic_state.parent.path
  tryptic.nav_to(parent_path, focused_path)
end)

map(mappings.nav_right, function()
  local target = tryptic.get_target_under_cursor()
  -- TODO: edit_file should be called from nav_to
  if vim.fn.isdirectory(target.path) == 1 then
    tryptic.nav_to(target.path)
  else
    tryptic.edit_file(target.path)
  end
end)

map(mappings.jump_to_cwd, tryptic.jump_to_cwd)
map(mappings.delete, tryptic.delete)
map(mappings.add, tryptic.add_file_or_dir)
map(mappings.copy, tryptic.copy)
map(mappings.rename, tryptic.rename)
map(mappings.quit, tryptic.close_tryptic)
map(mappings.cut, tryptic.toggle_cut, true)
map(mappings.paste, tryptic.paste)
map(mappings.show_help, tryptic.help)
