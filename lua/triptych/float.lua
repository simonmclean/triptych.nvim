local u = require 'triptych.utils'
local fs = require 'triptych.fs'
local syntax_highlighting = require 'triptych.syntax_highlighting'
local hl_utils = require 'triptych.highlight_groups'

local M = {}

local winbar_highlight_group = 'WinBar'

---Modify a buffer which is readonly and not modifiable
---@param buf number
---@param fn fun(): nil
---@return nil
local function modify_locked_buffer(buf, fn)
  vim.api.nvim_buf_set_option(buf, 'readonly', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  fn()
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

---@param buf number
---@param lines string[]
---@return nil
function M.buf_set_lines(buf, lines)
  modify_locked_buffer(buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

--- Add highlights for icons and file/directory names. Not to be confused with the syntax highlighting for preview buffers
---@param buf number
---@param highlights HighlightDetails[]
---@return nil
function M.buf_apply_highlights(buf, highlights)
  -- Apply icon highlight
  for i, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, 0, highlight.icon.highlight_name, i - 1, 0, highlight.icon.length)
    -- Apply file or directory highlight
    vim.api.nvim_buf_add_highlight(buf, 0, highlight.text.highlight_name, i - 1, highlight.text.starts, -1)
  end
end

--- Read the contents of a file into the window buffer
---@param win number
---@param lines string[]
---@param attempt_scroll_top? boolean
function M.win_set_lines(win, lines, attempt_scroll_top)
  local buf = vim.api.nvim_win_get_buf(win)
  M.buf_set_lines(buf, lines)
  if attempt_scroll_top then
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_exec2('normal! zb', {})
    end)
  end
end

---@param win number
---@param title string
---@param icon? string
---@param icon_highlight? string
---@param postfix? string
---@return nil
function M.win_set_title(win, title, icon, icon_highlight, postfix)
  vim.api.nvim_win_call(win, function()
    local maybe_icon = ''
    if vim.g.triptych_config.options.file_icons.enabled and icon then
      if icon_highlight then
        -- Apply icon highlight as foreground, combined with Winbar background
        maybe_icon = hl_utils.with_highlight_groups(icon_highlight, winbar_highlight_group, icon) .. ' '
      else
        maybe_icon = icon .. ' '
      end
    end
    local safe_title = string.gsub(title, '%%', '')
    if postfix and postfix ~= '' then
      safe_title = safe_title .. ' ' .. hl_utils.with_highlight_groups('Comment', winbar_highlight_group, postfix)
    end
    vim.wo.winbar = hl_utils.with_highlight_group(winbar_highlight_group, '%=' .. maybe_icon .. safe_title .. '%=')
  end)
end

---@param buf number
---@param path string
---@param lines string[]
function M.set_child_window_file_preview(buf, path, lines)
  local ft = fs.get_filetype_from_path(path)
  syntax_highlighting.stop(buf)
  M.buf_set_lines(buf, lines)
  if vim.g.triptych_config.options.syntax_highlighting.enabled then
    syntax_highlighting.start(buf, ft)
  end
end

---@return number
local function create_new_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  return buf
end

---@param config FloatingWindowConfig
---@return number
local function create_floating_window(config)
  local buf = create_new_buffer()
  local win = vim.api.nvim_open_win(buf, true, {
    width = config.width,
    height = config.height,
    relative = 'editor',
    col = config.x_pos,
    row = config.y_pos,
    border = config.border,
    style = 'minimal',
    noautocmd = true,
    focusable = config.is_focusable,
    zindex = config.hidden and 100 or 101,
  })
  vim.api.nvim_win_set_var(win, 'triptych_role', config.role)
  vim.api.nvim_win_set_option(win, 'cursorline', config.enable_cursorline)
  vim.api.nvim_win_set_option(win, 'number', config.show_numbers)
  vim.api.nvim_win_set_option(win, 'relativenumber', config.relative_numbers)
  if config.show_numbers then
    -- 2 to accomodate both diagnostics and git signs
    vim.api.nvim_win_set_option(win, 'signcolumn', 'auto:2')
  end
  vim.api.nvim_win_set_option(win, 'winblend', config.transparency)
  return win
end

---@param winblend number
---@return number
local function create_backdrop(winblend)
  local buf = create_new_buffer()
  local win = vim.api.nvim_open_win(buf, false, {
    width = vim.o.columns,
    height = vim.o.lines,
    relative = 'editor',
    col = 0,
    row = 0,
    style = 'minimal',
    noautocmd = true,
    focusable = false,
    zindex = 100,
    border = 'none'
  })
  vim.api.nvim_set_hl(0, 'TriptychBackdrop', { bg = '#000000', default = true })
  vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:TriptychBackdrop')
  vim.api.nvim_win_set_option(win, 'winblend', winblend)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'triptych_backdrop')
  return win
end

---@param show_numbers boolean
---@param relative_numbers boolean
---@param column_widths number[]
---@param backdrop number
---@param transparency number
---@param border string | table
---@param max_height number
---@param max_width number
---@param margin_x number
---@param margin_y number
---@return number[] 4 window ids (parent, primary, child, backdrop)
function M.create_three_floating_windows(
  show_numbers,
  relative_numbers,
  column_widths,
  backdrop,
  transparency,
  border,
  max_height,
  max_width,
  margin_x,
  margin_y
)
  local screen_height = vim.o.lines

  local screen_width = vim.o.columns

  local available_width = screen_width - (margin_x * 2)

  local float_height = math.min(screen_height - (margin_y * 3), max_height)

  -- Widths must be calculated up-front, because when we're looping through later, we need to
  -- reference the width of the previous window
  local float_widths = u.map(column_widths, function(percentage)
    local max = math.floor(max_width * percentage)
    local result = math.min(math.floor(available_width * percentage), max)
    if result < 1 then
      -- The user can set a column width to 0 to hide that column. However the vim.api.nvim_open_win function requires positive integers.
      -- Setting this to 1 allows for a valid window config, while effectively hiding the window
      return 1
    end
    return result
  end)

  local parent_width = float_widths[1]
  local primary_width = float_widths[2]
  local child_width = float_widths[3]
  local is_parent_window_hidden = parent_width == 1

  -- Figure out how much we need to shift the x_pos in order to center align Triptych
  local shift_right = u.eval(function()
    local width_excluding_margin = parent_width + primary_width + child_width
    if width_excluding_margin < screen_width then
      return math.floor((screen_width - width_excluding_margin) / 2)
    end
    return 0
  end)

  local y_pos = u.cond(screen_height > (max_height + (margin_y * 2)), {
    when_true = math.floor((screen_height - max_height) / 2),
    when_false = margin_y,
  })

  local floating_windows_configs = {
    parent = {},
    primary = {},
    child = {},
  }

  -- Build up the configs that will be passed to create_floating_window
  for i, percentage in ipairs(column_widths) do
    local is_parent = i == 1
    local is_primary = i == 2
    local is_child = i == 3

    local x_pos = u.eval(function()
      if is_parent then
        return 0
      elseif is_primary then
        if is_parent_window_hidden then
          return 0
        end
        return parent_width
      else
        if is_parent_window_hidden then
          return primary_width
        end
        return primary_width + parent_width
      end
    end) + shift_right

    local role = u.eval(function()
      if is_parent then
        return 'parent'
      elseif is_primary then
        return 'primary'
      end
      return 'child'
    end)

    local width = math.max(float_widths[i] - 2, 1)

    floating_windows_configs[role] = {
      -- The magic number 2 is to account for the natural spacing that exists around floating windows
      width = width,
      height = float_height,
      y_pos = y_pos,
      x_pos = x_pos,
      omit_left_border = is_primary or is_child,
      omit_right_border = is_parent or is_primary,
      enable_cursorline = is_parent or is_primary,
      is_focusable = is_primary,
      show_numbers = show_numbers and is_primary,
      relative_numbers = show_numbers and relative_numbers and is_primary,
      role = role,
      hidden = width == 1,
      border = border,
      transparency = transparency,
    }
  end

  -- If the parent width is 1, we consider it "hidden"
  -- This will be achieved by positioning it behind the primary window
  if floating_windows_configs.parent.width == 1 then
    floating_windows_configs.parent.x_pos = floating_windows_configs.primary.x_pos
  end

  -- Same for the child window
  if floating_windows_configs.child.width == 1 then
    floating_windows_configs.child.x_pos = floating_windows_configs.primary.x_pos
  end

  local wins = {
    create_floating_window(floating_windows_configs.parent),
    create_floating_window(floating_windows_configs.primary),
    create_floating_window(floating_windows_configs.child),
  }

  -- Focus the middle window
  vim.api.nvim_set_current_win(wins[2])

  if backdrop < 100 and vim.o.termguicolors then
    local backdrop_win = create_backdrop(backdrop)
    table.insert(wins, backdrop_win)
  end

  return wins
end

---@param wins number[]
---@return nil
function M.close_floats(wins)
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_buf_delete(buf, { force = true })
    -- In some circumstances the window can remain after the buffer is deleted
    -- But we need to wrap this in pcall to suppress errors when this isn't the case
    pcall(vim.api.nvim_win_close, win, { force = true })
  end
end

return M
