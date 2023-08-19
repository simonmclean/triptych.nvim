local float = require 'tryptic.float'
local u = require 'tryptic.utils'
local autocommands = require 'tryptic.autocmds'
local state = require 'tryptic.state'
local view = require 'tryptic.view'

local function close_tryptic()
  -- Need to set tryptic_open to false before closing the floats
  -- Otherwise things blow up. Not sure why
  state.tryptic_open.set(false)
  local view_state = state.view_state.get()
  float.close_floats {
    view_state.parent.win,
    view_state.current.win,
    view_state.child.win,
  }
  autocommands.destroy_autocommands() -- should this be in initialise_state?
  vim.api.nvim_set_current_win(state.opening_win.get())
  state.initialise_state()
end

local function open_tryptic()
  if state.tryptic_open.is_open() then
    return
  end

  state.initialise_state()

  state.opening_win.set(vim.api.nvim_get_current_win())
  local buf = vim.api.nvim_buf_get_name(0)
  local buf_dir = vim.fs.dirname(buf)

  state.tryptic_open.set(true)

  local windows = float.create_three_floating_windows()

  state.view_state.set {
    parent = {
      win = windows[1],
    },
    current = {
      win = windows[2],
    },
    child = {
      win = windows[3],
    },
  }

  autocommands.create_autocommands()

  view.nav_to(buf_dir, buf)
end

local function toggle_tryptic()
  if state.tryptic_open.is_open() then
    close_tryptic()
  else
    open_tryptic()
  end
end

local function setup(user_config)
  local default_config = {
    mappings = {
      open_tryptic = '<leader>-',
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
      delete = 'd',
      add = 'a',
      copy = 'c',
      rename = 'r',
      cut = 'x',
      paste = 'p',
      quit = 'q',
      toggle_hidden = '<leader>.', -- TODO implement this
    },
    extension_mappings = {},
    debug = false,
  }

  local final_config = u.merge_tables(default_config, user_config or {})

  vim.g.tryptic_config = final_config
  vim.keymap.set('n', vim.g.tryptic_config.mappings.open_tryptic, ':lua require"tryptic".toggle_tryptic()<CR>')
end

return {
  toggle_tryptic = toggle_tryptic,
  close_tryptic = close_tryptic,
  setup = setup,
}
