local float = require 'tryptic.float'
local autocmds = require 'tryptic.autocmds'
local state = require 'tryptic.state'
local mappings = require 'tryptic.mappings'
local actions = require 'tryptic.actions'
local view = require 'tryptic.view'
local git = require 'tryptic.git'
local diagnostics = require 'tryptic.diagnostics'

---@return nil
local function open_tryptic()
  local vim = _G.tryptic_mock_vim or vim
  local State = state.new(vim.g.tryptic_config, vim.api.nvim_get_current_win())
  local GitIgnore = git.GitIgnore.new()
  local GitStatus = git.GitStatus.new()
  local Diagnostics = diagnostics.new()
  local buf = vim.api.nvim_buf_get_name(0)
  local buf_dir = vim.fs.dirname(buf)
  local windows = float.create_three_floating_windows()

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
  local AutoCmds = autocmds.new(State, Diagnostics, GitStatus, GitIgnore)
  local Actions = actions.new(State, Diagnostics, GitStatus, GitIgnore)
  mappings.new(State, Actions, Diagnostics, GitStatus, GitIgnore)

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
    State:reset() -- TODO: Maybe we don't need this anymore because a new instance is created each time
  end

  view.nav_to(State, buf_dir, Diagnostics, GitIgnore, GitStatus, buf)
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
