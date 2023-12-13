local u = require 'triptych.utils'
local fs = require 'triptych.fs'

---Modify a buffer which is readonly and not modifiable
---@param buf number
---@param fn fun(): nil
---@return nil
local function modify_locked_buffer(buf, fn)
  local vim = _G.triptych_mock_vim or vim
  vim.api.nvim_buf_set_option(buf, 'readonly', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  fn()
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

---@param buf number
---@param lines string[]
---@return nil
local function buf_set_lines(buf, lines)
  local vim = _G.triptych_mock_vim or vim
  modify_locked_buffer(buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

---@param buf number
---@param highlights { highlight_name: string, char_count: number }[]
---@return nil
local function buf_apply_highlights(buf, highlights)
  local vim = _G.triptych_mock_vim or vim
  for i, highlight in ipairs(highlights) do
    -- Col end is hard-coded to to 3 because this is only used to for the filetype icons
    vim.api.nvim_buf_add_highlight(buf, 0, highlight.highlight_name, i - 1, 0, highlight.char_count)
  end
end

--- Read the contents of a file into the window buffer
---@param win number
---@param lines string[]
---@param attempt_scroll_top? boolean
local function win_set_lines(win, lines, attempt_scroll_top)
  local vim = _G.triptych_mock_vim or vim
  local buf = vim.api.nvim_win_get_buf(win)
  buf_set_lines(buf, lines)
  if attempt_scroll_top then
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_exec2('normal! zb', {})
    end)
  end
end

--- Attempt to read file. If it fails, try again with autocommands disabled
---@param path string
---@return boolean - true if success
---@return string|nil - nil on success, error message on fail
local function read_file(path)
  local vim = _G.triptych_mock_vim or vim
  local attempt_1_success, attempt_1_err = pcall(vim.cmd.read, path)
  if attempt_1_success then
    return attempt_1_success, attempt_1_err
  end
  local attempt_2_success, attempt_2_err = pcall(function()
    vim.cmd('noautocmd read ' .. path)
  end)
  return attempt_2_success, attempt_2_err
end

---@param win number
---@param title string
---@param icon? string
---@param highlight? string
---@param postfix? string
---@return nil
local function win_set_title(win, title, icon, highlight, postfix)
  local vim = _G.triptych_mock_vim or vim
  vim.api.nvim_win_call(win, function()
    local maybe_icon = ''
    if vim.g.triptych_config.options.file_icons.enabled and icon then
      if highlight then
        maybe_icon = u.with_highlight_group(highlight, icon) .. ' '
      else
        maybe_icon = icon .. ' '
      end
    end
    local safe_title = string.gsub(title, '%%', '')
    if postfix and postfix ~= '' then
      safe_title = safe_title .. ' ' .. u.with_highlight_group('Comment', postfix)
    end
    local title_with_hi = u.with_highlight_group('WinBar', safe_title)
    vim.wo.winbar = u.with_highlight_group('WinBar', '%=' .. maybe_icon .. title_with_hi .. '%=')
  end)
end

--- Read the contents of a file into the buffer
---@param buf number
---@param path string
---@return nil
local function buf_set_lines_from_path(buf, path)
  local vim = _G.triptych_mock_vim or vim
  modify_locked_buffer(buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    local ft = fs.get_filetype_from_path(path)
    if ft == '' or ft == nil then
      ft = 'triptych'
    end
    -- Setting the filetype can trigger autocommands which can blow up
    local ft_success, ft_err = pcall(vim.api.nvim_buf_set_option, buf, 'filetype', ft)
    if not ft_success then
      error(ft_err, vim.log.levels.WARN)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'triptych')
    end
    vim.api.nvim_buf_call(buf, function()
      local file_size = fs.get_file_size_in_kb(path)
      if file_size < 300 then
        local read_success, read_err = read_file(path)
        if read_success then
          --TODO: This is kind of hacky
          vim.api.nvim_exec2('normal! 1G0dd', {})
        else
          error(read_err, vim.log.levels.WARN)
          local msg = '[Unable to preview file contents]'
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '', msg })
        end
      else
        local msg = '[File size too large to preview]'
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '', msg })
      end
    end)
  end)
end

---@return number
local function create_new_buffer()
  local vim = _G.triptych_mock_vim or vim
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'triptych')
  return buf
end

---@param config FloatingWindowConfig
---@return number
local function create_floating_window(config)
  local vim = _G.triptych_mock_vim or vim
  local buf = create_new_buffer()
  local win = vim.api.nvim_open_win(buf, true, {
    width = config.width,
    height = config.height,
    relative = 'editor',
    col = config.x_pos,
    row = config.y_pos,
    border = 'single',
    style = 'minimal',
    noautocmd = true,
    focusable = config.is_focusable,
  })
  vim.api.nvim_win_set_option(win, 'cursorline', config.enable_cursorline)
  vim.api.nvim_win_set_option(win, 'number', config.show_numbers)
  vim.api.nvim_win_set_option(win, 'relativenumber', config.relative_numbers)
  if config.show_numbers then
    -- 2 to accomodate both diagnostics and git signs
    vim.api.nvim_win_set_option(win, 'signcolumn', 'auto:2')
  end
  return win
end

---@param show_numbers boolean
---@param relative_numbers boolean
---@return { [1]: number, [2]: number, [3]: number }
local function create_three_floating_windows(show_numbers, relative_numbers)
  local vim = _G.triptych_mock_vim or vim
  local max_width = 220
  local max_height = 45
  local screen_height = vim.o.lines
  local screen_width = vim.o.columns
  local padding = 4
  local max_float_width = math.floor(max_width / 3)
  local float_width = math.min(math.floor((screen_width / 3)) - padding, max_float_width)
  local float_height = math.min(screen_height - (padding * 3), max_height)

  local wins = {}

  local x_pos = u.cond(screen_width > (max_width + (padding * 2)), {
    when_true = math.floor((screen_width - max_width) / 2),
    when_false = padding,
  })
  local y_pos = u.cond(screen_height > (max_height + (padding * 2)), {
    when_true = math.floor((screen_height - max_height) / 2),
    when_false = padding,
  })
  for i = 1, 3, 1 do
    local is_parent = i == 1
    local is_primary = i == 2
    local is_child = i == 3
    if is_primary then
      x_pos = x_pos + float_width + 2
    elseif is_child then
      x_pos = x_pos + float_width + 2
    end
    local win = create_floating_window {
      width = float_width,
      height = float_height,
      y_pos = y_pos,
      x_pos = x_pos,
      omit_left_border = is_primary or is_child,
      omit_right_border = is_parent or is_primary,
      enable_cursorline = is_parent or is_primary,
      is_focusable = is_primary,
      show_numbers = show_numbers and is_primary,
      relative_numbers = show_numbers and relative_numbers and is_primary,
    }

    table.insert(wins, win)
  end

  -- Focus the middle window
  vim.api.nvim_set_current_win(wins[2])

  return wins
end

---@param wins number[]
---@return nil
local function close_floats(wins)
  local vim = _G.triptych_mock_vim or vim
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

return {
  create_three_floating_windows = create_three_floating_windows,
  close_floats = close_floats,
  buf_set_lines = buf_set_lines,
  buf_set_lines_from_path = buf_set_lines_from_path,
  win_set_lines = win_set_lines,
  win_set_title = win_set_title,
  buf_apply_highlights = buf_apply_highlights,
}
