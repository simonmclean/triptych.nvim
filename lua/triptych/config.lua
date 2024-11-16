local u = require 'triptych.utils'

local function config_warn(config_prop_name)
  return function(msg)
    vim.notify('Triptych config option "' .. config_prop_name .. '" ' .. msg, vim.log.levels.WARN)
  end
end

---@class TriptychConfig
---@field debug boolean
---@field mappings TriptychConfigMappings
---@field extension_mappings { [string]: ExtensionMapping }
---@field options TriptychConfigOptions
---@field git_signs TriptychConfigGitSigns
---@field diagnostic_signs TriptychConfigDiagnostic

---@class TriptychConfigMappings
---@field show_help KeyMapping
---@field jump_to_cwd KeyMapping
---@field nav_left KeyMapping
---@field nav_right KeyMapping
---@field open_vsplit KeyMapping
---@field open_hsplit KeyMapping
---@field open_tab KeyMapping
---@field cd KeyMapping
---@field delete KeyMapping
---@field add KeyMapping
---@field copy KeyMapping
---@field rename KeyMapping
---@field cut KeyMapping
---@field paste KeyMapping
---@field quit KeyMapping
---@field toggle_hidden KeyMapping
---@field toggle_collapse_dirs KeyMapping

---@class ExtensionMapping
---@field mode string
---@field fn fun(contents?: PathDetails, refresh_fn: fun(): nil): nil

---@class TriptychConfigOptions
---@field dirs_first boolean
---@field collapse_dirs boolean
---@field show_hidden boolean
---@field line_numbers TriptychConfigLineNumbers
---@field file_icons TriptychConfigFileIcons
---@field responsive_column_widths { [string]: number[] }
---@field highlights TriptychConfigHighlights
---@field syntax_highlighting TriptychConfigSyntaxHighlighting
---@field backdrop number
---@field transparency number
---@field border string | table
---@field max_height number
---@field max_width number
---@field margin_x number
---@field margin_y number

---@class TriptychConfigHighlights
---@field file_names string
---@field directory_names string

---@class TriptychConfigSyntaxHighlighting
---@field enabled boolean
---@field debounce_ms number

---@class TriptychConfigLineNumbers
---@field enabled boolean
---@field relative boolean

---@class TriptychConfigFileIcons
---@field enabled boolean
---@field directory_icon string
---@field fallback_file_icon  string

---@class TriptychConfigGitSigns
---@field enabled boolean
---@field signs TriptychConfigGitSignsSigns

---@class TriptychConfigGitSignsSigns
---@field add string | TriptychConfigGitSignDefineOptions
---@field modify string | TriptychConfigGitSignDefineOptions
---@field rename string | TriptychConfigGitSignDefineOptions
---@field untracked string | TriptychConfigGitSignDefineOptions

---@class TriptychConfigGitSignDefineOptions
---@field icon? string
---@field linehl? string
---@field numhl? string
---@field text? string
---@field texthl? string
---@field culhl? string

---@class TriptychConfigDiagnostic
---@field enabled boolean

---@alias KeyMapping (string | string[])

---@return TriptychConfig
local function default_config()
  return {
    debug = false,
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
      toggle_collapse_dirs = 'z',
    },
    extension_mappings = {},
    options = {
      dirs_first = true,
      collapse_dirs = true,
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
      transparency = 0,
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
