local u = require 'tests.utils'
local api = vim.api

local function go()
  local cwd = vim.fn.getcwd()
  local opening_dir = u.join_path(cwd, 'tests/test_playground/level_1/level_2/level_3')
  local triptych = require 'triptych'
  triptych.setup {
    options = {
      file_icons = {
        enabled = false -- Makes for easier testing
      }
    }
  }
  triptych.toggle_triptych(opening_dir)
  local all_windows = api.nvim_list_wins()
  local wins = {
    child = -1,
    primary = -1,
    parent = -1,
  }
  -- TODO: Rather than waiting ticks, maybe use public events?... e.g. 'TriptychOpened'
  u.wait_ticks(10, function()
    for _, win in ipairs(all_windows) do
      local has_role, role = pcall(api.nvim_win_get_var, win, 'triptych_role')
      if has_role then
        wins[role] = win
      end
    end

    local bufs = {
      child = api.nvim_win_get_buf(wins.child),
      primary = api.nvim_win_get_buf(wins.primary),
      parent = api.nvim_win_get_buf(wins.parent),
    }

    local lines = {
      child = u.get_lines(bufs.child),
      primary = u.get_lines(bufs.primary),
      parent = u.get_lines(bufs.parent),
    }

    vim.print {
      wins = wins,
      bufs = bufs,
      lines = lines
    }
  end)
end

go()

-- describe('UI', function()
--   it('populates windows with files and folders', function()
--     go()
--   end)
-- end)
