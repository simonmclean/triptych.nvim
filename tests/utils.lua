local api = vim.api

local M = {}

---@param ... string
---@return string
function M.join_path(...)
  return table.concat({ ... }, '/')
end

---@param n integer
---@param callback function
function M.wait_ticks(n, callback)
  local function tick()
    if n == 0 then
      callback()
    else
      n = n - 1
      vim.schedule(tick)
    end
  end
  tick()
end

function M.get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

function M.get_winbar(win)
  local winbar
  api.nvim_win_call(win, function ()
    winbar = vim.wo.winbar
  end)
  return winbar
end

function M.on_event(event, callback)
  vim.api.nvim_create_autocmd('User', {
    group = 'TriptychEvents',
    pattern = event,
    callback = callback,
  })
end

function M.on_all_wins_updated(callback)
  local wins_updated = {
    child = false,
    primary = false,
    parent = false,
  }
  M.on_event('TriptychDidUpdateWindow', function(data)
    wins_updated[data.data.win_type] = true
    if wins_updated.child and wins_updated.primary and wins_updated.parent then
      callback()
    end
  end)
end

function M.open_triptych(opening_dir)
  local triptych = require 'triptych.init'
  triptych.setup {
    options = {
      file_icons = {
        enabled = false, -- Makes for easier testing
      },
    },
  }
  triptych.toggle_triptych(opening_dir)
end

function M.get_state()
  local all_windows = api.nvim_list_wins()
  local wins = {
    child = -1,
    primary = -1,
    parent = -1,
  }
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
    child = M.get_lines(bufs.child),
    primary = M.get_lines(bufs.primary),
    parent = M.get_lines(bufs.parent),
  }

  local winbars = {
    child = M.get_winbar(wins.child),
    primary = M.get_winbar(wins.primary),
    parent = M.get_winbar(wins.parent),
  }

  return {
    wins = wins,
    bufs = bufs,
    lines = lines,
    winbars = winbars
  }
end

function M.await(fn)
  local co = coroutine.running()
  fn(function()
    coroutine.resume(co)
  end)
  return coroutine.yield
end

return M
