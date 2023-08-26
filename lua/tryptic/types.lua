---@class TrypticConfig
---@field mappings TrypticConfigMappings
---@field extension_mappings { [string]: fun(contents: DirContents): nil }
---@field options TrypticConfigOptions
---@field line_numbers TrypticConfigLineNumbers
---@field git_signs TrypticConfigGitSigns
---@field diagnostic_signs TrypticConfigDiagnostic
---@field debug boolean

---@class TrypticConfigMappings
---@field open_tryptic KeyMapping
---@field show_help KeyMapping
---@field jump_to_cwd KeyMapping
---@field nav_left KeyMapping
---@field nav_right KeyMapping
---@field delete KeyMapping
---@field add KeyMapping
---@field copy KeyMapping
---@field rename KeyMapping
---@field cut KeyMapping
---@field paste KeyMapping
---@field quit KeyMapping
---@field toggle_hidden KeyMapping

---@class TrypticConfigOptions
---@field dirs_first boolean

---@class TrypticConfigLineNumbers
---@field enabled boolean
---@field relative boolean

---@class TrypticConfigGitSigns
---@field enabled boolean
---@field signs TrypticConfigGitSignsSigns

---@class TrypticConfigGitSignsSigns
---@field add string
---@field add_modify string
---@field modify string
---@field delete string
---@field rename string
---@field untracked string

---@class TrypticConfigDiagnostic
---@field enabled boolean

---@alias KeyMapping (string | string[])

---@alias GitFileStatus ('A' | 'AM' | 'D' | 'M' | 'R' | '??')

---@alias GitStatus { [string]: GitFileStatus }

---@class DirContents
---@field path string
---@field display_name string
---@field dirname string # Parent directory path
---@field basename string
---@field is_dir boolean
---@field filetype? string
---@field cutting boolean
---@field git_status? string
---@field diagnostic_status? integer
---@field children? DirContents

---@class ViewState
---@field parent ViewStateWindow
---@field current ViewStateCurrentWindow
---@field child ViewStateChildWindow

---@class ViewStateWindow
---@field path string
---@field contents? DirContents
---@field win number

--- TODO: This inheritance isn't working properly
---@class ViewStateCurrentWindow: ViewStateWindow
---@field previous_path string

---@class ViewStateChildWindow: ViewStateWindow
---@field lines? string[]

---@class FloatingWindowConfig
---@field width number
---@field height number
---@field x_pos number
---@field y_pos number
---@field is_focusable boolean
---@field enable_cursorline boolean
---@field show_numbers boolean

---@alias Diagnostics { [string]: integer }
