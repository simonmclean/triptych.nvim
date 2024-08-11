local u = require 'triptych.utils'

local function config_warn(config_prop_name)
  return function(msg)
    vim.notify('Triptych config option "' .. config_prop_name .. '" ' .. msg, vim.log.levels.WARN)
  end
end

---@return TriptychConfig
local function default_config()
  return {
    mappings = {
      -- Everything below is buffer-local, meaning it will only apply to Triptych windows
      show_help = 'g?',
      jump_to_cwd = '.',
      nav_left = 'h',
      nav_right = { 'l', '<CR>' },
      open_hsplit = { '-' },
      open_vsplit = { '|' },
      open_tab = { '<C-t>' },
      cd = '<leader>cd',
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
      file_icons = {
        enabled = true,
        directory_icon = '',
        fallback_file_icon = '',
      },
      responsive_column_widths = {
        ['0'] = { 0, 0.5, 0.5 },
        ['120'] = { 0.2, 0.3, 0.5 },
        ['200'] = { 0.25, 0.25, 0.5 },
      },
      highlights = {
        file_names = 'NONE',
        directory_names = 'NONE',
      },
      syntax_highlighting = {
        enabled = true,
        debounce_ms = 100,
      },
      backdrop = 60,
      border = 'single',
      max_height = 45,
      max_width = 220,
      margin_x = 4,
      margin_y = 4,
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
end

local function validate_responsive_column_widths(user_config)
  local responsive_column_widths = u.eval(function()
    if user_config and user_config.options and user_config.options.responsive_column_widths then
      return user_config.options.responsive_column_widths
    end
  end)

  if responsive_column_widths then
    local warn = config_warn 'options.responsive_column_widths'

    local function set_to_default()
      user_config.options.responsive_column_widths = default_config().options.responsive_column_widths
    end

    if not responsive_column_widths['0'] then
      warn 'must have a default ["0"] breakpoint'
      return set_to_default()
    end

    for breakpoint, widths in pairs(responsive_column_widths) do
      if not tonumber(breakpoint) then
        warn 'breakpoint keys must be a stringified number'
      end

      local rounded_total = u.round(widths[1] + widths[2] + widths[3], 2)
      if rounded_total ~= 1 and rounded_total ~= 0.99 then
        warn 'column widths must add up to 1 after rounding to 2 decimal places. e.g. { 0.25, 0.25, 0.5 }'
        return set_to_default()
      end
    end
  end
end

---@param user_config table
local function handle_column_widths_deprecation(user_config)
  if user_config and user_config.options and user_config.options.column_widths then
    config_warn 'options.column_widths' 'is deprecated. Please use "options.responsive_column_widths" instead.'
  end
end

---@param user_config table
---@return TriptychConfig
local create_merged_config = function(user_config)
  handle_column_widths_deprecation(user_config)
  validate_responsive_column_widths(user_config)
  return u.merge_tables(default_config(), user_config)
end

return {
  create_merged_config = create_merged_config,
}
