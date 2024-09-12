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

---@param events { name: string, wait_for_n: integer }[]
---@param callback fun(result: table<string, any[]>)
function M.on_events(events, callback)
  ---@type table<string, any[]>
  local result = {}

  local autocmd_ids = {}

  local function is_ready()
    for _, event in ipairs(events) do
      local entry = result[event.name] or {}
      if #entry < event.wait_for_n then
        return false
      end
    end
    return true
  end

  for _, event in ipairs(events) do
    result[event.name] = {}

    local timer = vim.loop.new_timer()

    local id = M.on_event(event.name, function(data)
      timer:stop()

      table.insert(result[event.name], data.data)

      if is_ready() then
        timer:start(
          1000,
          0,
          vim.schedule_wrap(function()
            for _, id in ipairs(autocmd_ids) do
              api.nvim_del_autocmd(id)
            end
            callback(result)
          end)
        )
      end
    end, false)

    table.insert(autocmd_ids, id)
  end
end

function M.on_child_window_updated(callback)
  M.on_wins_updated({ 'child' }, callback)
end

function M.on_primary_window_updated(callback)
  M.on_wins_updated({ 'primary' }, callback)
end

function M.on_all_wins_updated(callback)
  M.on_wins_updated({ 'child', 'primary', 'parent' }, callback)
end

---@param wins ('child' | 'primary'| 'parent')[]
---@param callback function
function M.on_wins_updated(wins, callback)
  local wait_for_child = M.list_contains(wins, 'child')
  local wait_for_primary = M.list_contains(wins, 'primary')
  local wait_for_parent = M.list_contains(wins, 'parent')

  -- We're essentially saying, if the wins list does't contain X, then we consider it already updated
  local wins_updated = {
    child = not wait_for_child,
    primary = not wait_for_primary,
    parent = not wait_for_parent,
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

function M.setup_triptych()
  require('triptych.init').setup {
    debug = false,
    -- Set options for easier testing
    options = {
      file_icons = {
        enabled = false,
      },
      syntax_highlighting = {
        enabled = false,
      },
    },
  }
end

function M.open_triptych(opening_dir)
  M.setup_triptych()
  require('triptych.init').toggle_triptych(opening_dir)
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

---@param key string
function M.press_keys(key)
  local input_parsed = api.nvim_replace_termcodes(key, true, true, true)
  api.nvim_feedkeys(input_parsed, 'normal', false)
end

function M.reverse_list(list)
  local reversed = {}
  for i = #list, 1, -1 do
    table.insert(reversed, list[i])
  end
  return reversed
end

---@param list string[]
---@param str string
---@return boolean
function M.list_contains(list, str)
  for _, value in ipairs(list) do
    if value == str then
      return true
    end
  end
  return false
end

---@param fn function
function M.eval(fn)
  return fn()
end

return M
