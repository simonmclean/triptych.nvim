local u = require 'tryptic.utils'
--
---@type TrypticConfig
local default_config = {
  mappings = {
    -- Everything below is buffer-local, meaning it will only apply to Tryptic windows
    open_tryptic = '<leader>-',
    show_help = 'g?',
    jump_to_cwd = '.', -- Pressing again will toggle back
    nav_left = 'h',
    nav_right = { 'l', '<CR>' },
    delete = 'd',
    add = 'a',
    copy = 'c',
    rename = 'r',
    cut = 'x',
    paste = 'p',
    quit = 'q',
    toggle_hidden = '<leader>.',
  },
  extension_mappings = {},
  options = {
    dirs_first = true,
    show_hidden = false,
    line_numbers = {
      enabled = true,
      relative = false,
    },
  },
  git_signs = {
    enabled = true,
    signs = {
      add = '+',
      modify = '~',
      rename = 'r',
      untracked = '?',
    },
  },
  diagnostic_signs = {
    enabled = true,
  },
}

---@param user_config table
---@return TrypticConfig
local create_merged_config = function(user_config)
  return u.merge_tables(default_config, user_config)
end

return {
  create_merged_config = create_merged_config,
}
