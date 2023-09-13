local float = require 'tryptic.float'
local u = require 'tryptic.utils'
local create_autocmds = require('tryptic.autocmds').new
local create_state = require('tryptic.state').new
local create_mappings = require 'tryptic.mappings'.new
local create_actions = require 'tryptic.actions'.new
local view = require 'tryptic.view'
local git = require 'tryptic.git'

-- require 'plenary.reload'.reload_module('tryptic')

---@return nil
local function open_tryptic()
  local state = create_state(vim.g.tryptic_config, vim.api.nvim_get_current_win())
  vim.g.tryptic_get_state = function()
    return state
  end -- TODO: Can I get away without such globals?

  local buf = vim.api.nvim_buf_get_name(0)
  local buf_dir = vim.fs.dirname(buf)

  local windows = float.create_three_floating_windows()

  state.windows = {
    parent = {
      path = '',
      win = windows[1],
    },
    current = {
      path = '',
      previous_path = '',
      win = windows[2],
    },
    child = {
      win = windows[3],
    },
  }

  -- Autocmds need to be created after the above state is set
  local autocmds = create_autocmds(state)
  local actions = create_actions(state)
  create_mappings(state, actions)

  vim.g.tryptic_close = function()
    -- Need to destroy autocmds before the floating windows
    autocmds:destroy_autocommands()
    local wins = state.windows
    float.close_floats {
      wins.parent.win,
      wins.current.win,
      wins.child.win,
    }
    vim.api.nvim_set_current_win(state.opening_win)
    git.git_status.reset()
    git.git_ignore().reset()
    state:reset() -- TODO: Maybe we don't need this anymore because a new instance is created each time
  end

  view.nav_to(state, buf_dir, buf)
end

---@return nil
local function toggle_tryptic()
  open_tryptic()
end

---@param user_config TrypticConfig
local function setup(user_config)
  ---@type TrypticConfig
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
      toggle_hidden = '<leader>,',
    },
    extension_mappings = {},
    options = {
      dirs_first = true,
      show_hidden = false,
    },
    line_numbers = {
      enabled = true, -- TODO: Document this, and implement
      relative = false, -- TODO: Document and implement
    },
    git_signs = {
      enabled = true,
      signs = {
        add = 'GitSignsAdd',
        add_modify = 'GitSignsAdd',
        modify = 'GitSignsChange',
        delete = 'GitSignsDelete',
        rename = 'GitSignsRename',
        untracked = 'GitSignsUntracked',
      },
    },
    diagnostic_signs = {
      enabled = true, -- TODO: Document this, and implement
    },
    debug = false,
  }

  ---@type TrypticConfig
  local final_config = u.merge_tables(default_config, user_config or {})

  vim.g.tryptic_config = final_config
  vim.keymap.set('n', vim.g.tryptic_config.mappings.open_tryptic, ':lua require"tryptic".toggle_tryptic()<CR>')
end

return {
  toggle_tryptic = toggle_tryptic,
  setup = setup,
}
