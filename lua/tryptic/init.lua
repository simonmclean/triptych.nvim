local fs = require 'tryptic.fs'
local float = require 'tryptic.float'
local u = require 'tryptic.utils'
local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

require 'plenary.reload'.reload_module('tryptic')

-- Globals
vim.g.tryptic_state = {
  parent = {
    win = nil
  },
  current = {
    win = nil
  },
  child = {
    win = nil
  },
}
vim.g.tryptic_is_open = false
vim.g.tryptic_autocmds = {}

vim.keymap.set('n', '<leader>0', ':lua require"tryptic".toggle_tryptic()<CR>')

local au_group = vim.api.nvim_create_augroup("TrypticAutoCmd", { clear = true })

local function tree_to_lines(tree)
  local lines = {}
  local highlights = {}

  for _, child in ipairs(tree.children) do
    local line, highlight_name = u.cond(child.is_dir, {
      when_true = function()
        local line = " " .. child.display_name
        return line, 'Directory'
      end,
      when_false = function()
        local maybe_icon, highlight_name = devicons.get_icon_by_filetype(child.filetype)
        local fallback = ""
        local icon = u.cond(maybe_icon ~= nil, {
          when_true = function()
            return maybe_icon
          end,
          when_false = fallback
        })
        local line = icon .. ' ' .. child.display_name
        return line, highlight_name or 'Comment'
      end
    })
    table.insert(lines, line)
    table.insert(highlights, highlight_name)
  end

  return lines, highlights
end

local function update_child_window(target)
  local buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.child.win)

  vim.g.tryptic_state.child.path = u.cond(target == nil, {
    when_true = nil,
    when_false = function()
      return target.path
    end
  })

  if (target == nil) then
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      '[empty directory]'
    )
    float.buf_set_lines(buf, {})
  elseif target.is_dir then
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      vim.fs.basename(target.path),
      ""
    )
    local lines, highlights = tree_to_lines(target)
    float.buf_set_lines(buf, lines)
    float.buf_apply_highlights(buf, highlights)
  else
    local filetype = fs.get_filetype_from_path(target.path) -- TODO: De-dupe this
    float.win_set_title(
      vim.g.tryptic_state.child.win,
      vim.fs.basename(target.path),
      devicons.get_icon_by_filetype(filetype)
    )
    float.buf_set_lines_from_path(buf, target.path)
  end
end

local function get_target_under_cursor()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return vim.g.tryptic_state.current.contents.children[line_number]
end

local function handle_cursor_moved()
  local target = get_target_under_cursor()
  if vim.g.tryptic_is_open then
    update_child_window(target)
  end
end

local function handle_buf_leave()
  if vim.g.tryptic_is_open then
    vim.g.tryptic_close()
  end
end

local function create_autocommands()
  local a = vim.api.nvim_create_autocmd('CursorMoved', {
    group = au_group,
    callback = handle_cursor_moved
  })

  local b = vim.api.nvim_create_autocmd('BufLeave', {
    group = au_group,
    callback = handle_buf_leave
  })

  vim.g.tryptic_autocmds = { a, b }
end

local function destroy_autocommands()
  for _, autocmd in pairs(vim.g.tryptic_autocmds) do
    vim.api.nvim_del_autocmd(autocmd)
  end
end

local function nav_to(target_path)
  local focused_buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.current.win)
  local focused_contents = fs.list_dir_contents(target_path)
  local focused_title = vim.fs.basename(target_path)
  local focused_lines, focused_highlights = tree_to_lines(focused_contents)

  local parent_buf = vim.api.nvim_win_get_buf(vim.g.tryptic_state.parent.win)
  local parent_path = fs.get_parent(target_path)
  local parent_title = vim.fs.basename(parent_path)
  local parent_contents = fs.list_dir_contents(parent_path)
  local parent_lines, parent_highlights = tree_to_lines(parent_contents)

  float.win_set_lines(vim.g.tryptic_state.parent.win, parent_lines)
  float.win_set_lines(vim.g.tryptic_state.current.win, focused_lines)

  float.win_set_title(vim.g.tryptic_state.parent.win, parent_title, "")
  float.win_set_title(vim.g.tryptic_state.current.win, focused_title, "")

  float.buf_apply_highlights(focused_buf, focused_highlights)
  float.buf_apply_highlights(parent_buf, parent_highlights)

  vim.g.tryptic_state = {
    parent = {
      path = parent_path,
      contents = parent_contents, -- TODO: Do I need this in the state?
      win = vim.g.tryptic_state.parent.win
    },
    current = {
      path = target_path,
      contents = focused_contents,
      win = vim.g.tryptic_state.current.win
    },
    child = {
      path = nil,
      contents = nil,
      lines = nil,
      win = vim.g.tryptic_state.child.win
    }
  }
end

local function open_tryptic()
  if vim.g.tryptic_is_open then
    return
  end

  local path = fs.get_dirname_of_current_buffer()

  vim.g.tryptic_is_open = true

  local windows = float.create_three_floating_windows()

  vim.g.tryptic_state = {
    parent = {
      win = windows[1]
    },
    current = {
      win = windows[2]
    },
    child = {
      win = windows[3]
    },
  }

  create_autocommands()

  vim.g.tryptic_close = function()
    vim.print("CLOSE")
    vim.g.tryptic_is_open = false

    float.close_floats({
      vim.g.tryptic_state.parent.win,
      vim.g.tryptic_state.current.win,
      vim.g.tryptic_state.child.win,
    })

    destroy_autocommands()

    vim.g.tryptic_target_buffer = nil
    vim.g.tryptic_state = nil
  end

  nav_to(path)
end

local function toggle_tryptic()
  if vim.g.tryptic_is_open then
    vim.g.tryptic_close()
  else
    open_tryptic()
  end
end

local function edit_file(path)
  vim.g.tryptic_close()
  vim.cmd.edit(path)
end

local function setup()
  vim.print('SETUP')
end

return {
  toggle_tryptic = toggle_tryptic,
  nav_to = nav_to,
  get_target_under_cursor = get_target_under_cursor,
  edit_file = edit_file,
  setup = setup,
}
