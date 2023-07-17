local u = require 'tryptic.utils'
local fs = require 'tryptic.fs'

local function buf_set_lines(buf, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'tryptic')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function win_set_lines(win, lines)
  local buf = vim.api.nvim_win_get_buf(win)
  buf_set_lines(buf, lines)
end

local function win_set_title(win, title, icon)
  vim.api.nvim_win_call(win, function()
    local maybe_icon = ''
    if icon then
      maybe_icon = icon .. ' '
    end
    vim.wo.winbar = '%=' .. maybe_icon .. title .. '%='
  end)
end

local function buf_set_lines_from_path(buf, path)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'readonly', false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  local ft = fs.get_filetype_from_path(path)
  vim.api.nvim_buf_set_option(buf, 'filetype', ft)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd.read(path)
    -- TODO: This is kind of hacky
    vim.api.nvim_exec2('normal! 1G0dd', {})
  end)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
end

local function create_new_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, false)
  buf_set_lines(buf, lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'tryptic')
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  return buf
end

-- TODO: This is borked
local function configure_border_with_missing_side(omit_left, omit_right)
  local left_border = u.cond(omit_left, {
    when_true = "",
    when_false = "║"
  })
  local right_border = u.cond(omit_right, {
    when_true = "",
    when_false = "║"
  })
  return { "╔", "═", "╗", right_border, "╝", "═", "╚", left_border }
end

local function create_floating_window(config)
  local buf = create_new_buffer(config.lines)
  local win = vim.api.nvim_open_win(buf, true, {
    width = config.width,
    height = config.height,
    relative = 'editor',
    col = config.x_pos,
    row = config.y_pos,
    border = 'single',
    -- border = configure_border_with_missing_side(
    --   config.omit_left_border,
    --   config.omit_right_border
    -- ),
    style = 'minimal',
    noautocmd = true,
    focusable = config.is_primary,
  })
  if config.is_primary then
    vim.api.nvim_win_set_option(win, 'cursorline', true)
    vim.api.nvim_win_set_option(win, 'number', true)
  end
  win_set_title(win, config.title)
  return win
end

-- TODO: Split this out into separate create and update functions
local function create_three_floating_windows(config_list)
  local screen_height = vim.o.lines
  local screen_width = vim.o.columns
  local padding = 4
  local float_width = math.floor((screen_width / 3)) - padding
  local float_height = screen_height - (padding * 3)

  local wins = {}

  for i, config in ipairs(config_list) do
    local x_pos
    if i == 1 then
      x_pos = padding
    elseif i == 2 then
      x_pos = padding + (float_width * (i - 1)) + 2
    else
      x_pos = padding + (float_width * (i - 1)) + 4
    end
    local win = create_floating_window({
      title = config.title,
      lines = config.lines,
      width = float_width,
      height = float_height,
      y_pos = padding,
      x_pos = x_pos,
      omit_left_border = u.cond(i == 2 or i == 3),
      omit_right_border = u.cond(1 == 1 or i == 2),
      is_primary = u.cond(i == 2)
    })

    table.insert(wins, win)
  end

  -- Focus the middle window
  vim.api.nvim_set_current_win(wins[2])

  return wins
end

local function close_floats(wins)
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

return {
  create_floating_window = create_floating_window,
  create_three_floating_windows = create_three_floating_windows,
  close_floats = close_floats,
  buf_set_lines = buf_set_lines,
  buf_set_lines_from_path = buf_set_lines_from_path,
  win_set_lines = win_set_lines,
  win_set_title = win_set_title
}
