local float = require 'tryptic.float'
local autocmds = require 'tryptic.autocmds'
local state = require 'tryptic.state'
local mappings = require 'tryptic.mappings'
local actions = require 'tryptic.actions'
local view = require 'tryptic.view'
local git = require 'tryptic.git'
local diagnostics = require 'tryptic.diagnostics'
local event_handlers = require 'tryptic.event_handlers'

---@return nil
local function open_tryptic()
  local vim = _G.tryptic_mock_vim or vim
  local config = vim.g.tryptic_config
  local State = state.new(config, vim.api.nvim_get_current_win())
  local Git = git.Git.new()
  local Diagnostics = diagnostics.new()
  local buf = vim.api.nvim_buf_get_name(0)
  local buf_dir = vim.fs.dirname(buf)
  local windows = float.create_three_floating_windows(config.line_numbers.enabled, config.line_numbers.relative)

  State.windows = {
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
  local AutoCmds = autocmds.new(event_handlers, State, Diagnostics, Git)
  local Actions = actions.new(State, Diagnostics, Git, function()
    view.refresh_view(State, Diagnostics, Git)
  end)
  mappings.new(State, Actions, Diagnostics, Git)

  vim.g.tryptic_close = function()
    -- Need to destroy autocmds before the floating windows
    AutoCmds:destroy_autocommands()
    local wins = State.windows
    float.close_floats {
      wins.parent.win,
      wins.current.win,
      wins.child.win,
    }
    vim.api.nvim_set_current_win(State.opening_win)
  end

  view.nav_to(State, buf_dir, Diagnostics, Git, buf)
end

---@param user_config? TrypticConfig
local function setup(user_config)
  local vim = _G.tryptic_mock_vim or vim
  vim.g.tryptic_config = require('tryptic.config').create_merged_config(user_config or {})
  vim.keymap.set('n', vim.g.tryptic_config.mappings.open_tryptic, ':lua require"tryptic".open_tryptic()<CR>')
end

return {
  open_tryptic = open_tryptic,
  setup = setup,
}
