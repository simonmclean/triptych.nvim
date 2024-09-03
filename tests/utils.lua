local api = vim.api

local M = {}

---@param ... string
---@return string
function M.join_path(...)
  return table.concat({ ... }, '/')
end

function M.get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

function M.get_winbar(win)
  return api.nvim_get_option_value('winbar', { win = win })
end

---@param event string
---@param callback function
---@param once? boolean if false, remember to cleanup with nvim_del_autocmd
function M.on_event(event, callback, once)
  if once == nil then
    once = true
  end
  vim.api.nvim_create_autocmd('User', {
    group = 'TriptychEvents',
    pattern = event,
    once = once,
    callback = vim.schedule_wrap(function(data)
      callback(data)
      return true
    end),
  })
end

function M.on_all_wins_updated(callback)
  local wins_updated = {
    child = false,
    primary = false,
    parent = false,
  }
  -- Timer is used to wait 1 second before executing the callback
  -- Just to make sure there are no more events coming through
  local timer = vim.loop.new_timer()
  M.on_event('TriptychDidUpdateWindow', function(data)
    timer:stop()
    wins_updated[data.data.win_type] = true
    if wins_updated.child and wins_updated.primary and wins_updated.parent then
      timer:start(
        1000,
        0,
        vim.schedule_wrap(function()
          api.nvim_del_autocmd(data.id)
          callback()
        end)
      )
    end
  end, false)
end

function M.open_triptych(opening_dir)
  local triptych = require 'triptych.init'
  triptych.setup {
    debug = false,
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
    winbars = winbars,
  }
end

function M.press_key(k)
  local input_parsed = api.nvim_replace_termcodes(k, true, true, true)
  api.nvim_feedkeys(input_parsed, 'normal', false)
  api.nvim_exec2('norm! ' .. k, {})
end

function M.reverse_list(list)
  local reversed = {}
  for i = #list, 1, -1 do
    table.insert(reversed, list[i])
  end
  return reversed
end

return M
