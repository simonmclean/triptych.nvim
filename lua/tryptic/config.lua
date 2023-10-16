local u = require 'tryptic.utils'

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

---@param user_config? TrypticConfig
---@return TrypticConfig
local create_merged_config = function(user_config)
  return u.merge_tables(default_config, user_config or {})
end

return {
  create_merged_config = create_merged_config,
}
