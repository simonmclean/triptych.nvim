local u = require 'tryptic.utils'
local fs = require 'tryptic.fs'

local function buf_set_options(buf, options)
  for option, value in pairs(options) do
    vim.api.nvim_buf_set_option(buf, option, value)
  end
end

local function buf_set_lines(buf, lines)
  buf_set_options(buf, {
    readonly = false,
    modifiable = true,
    filetype = 'tryptic',
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  buf_set_options(buf, {
    readonly = true,
    modifiable = false
  })
end

local function win_set_lines(win, lines)
  local buf = vim.api.nvim_win_get_buf(win)
  buf_set_lines(buf, lines)
end

local function buf_set_lines_from_path(buf, path)
  buf_set_options(buf, {
    readonly = false,
    modifiable = true,
    filetype = fs.get_filetype_from_path(path)
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_call(buf, function()
    vim.cmd.read(path)
    -- TODO: This is kind of hacky
    vim.api.nvim_exec2('normal! 1G0dd', {})
  end)
  buf_set_options(buf, {
    readonly = true,
    modifiable = false
  })
end

local function create_new_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, false)
  buf_set_options(buf, {
    filetype = 'tryptic',
  })
  buf_set_lines(buf, lines)
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
    row = 2,
    border = 'single',
    -- border = configure_border_with_missing_side(
    --   config.omit_left_border,
    --   config.omit_right_border
    -- ),
    title = ' ' .. config.title .. ' ',
    title_pos = 'center',
    style = 'minimal',
    noautocmd = true,
    focusable = config.is_primary,
  })
  if config.is_primary then
    vim.api.nvim_win_set_option(win, 'cursorline', true)
    vim.api.nvim_win_set_option(win, 'number', true)
  end
  return win
end

-- TODO: Split this out into separate create and update functions
local function create_three_floating_windows(config_list)
  local screen_height = vim.o.lines
  -- TODO: This width doesn't account for gutters
  local screen_width = vim.o.columns
  local padding = 4
  local float_width = math.floor((screen_width / 3) - (padding * 2))
  local float_height = screen_height - (padding * 2)

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
  win_set_lines = win_set_lines
}
