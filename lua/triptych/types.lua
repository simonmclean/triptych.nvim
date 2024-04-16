---@class TriptychConfig
---@field mappings TriptychConfigMappings
---@field extension_mappings { [string]: ExtensionMapping }
---@field options TriptychConfigOptions
---@field git_signs TriptychConfigGitSigns
---@field diagnostic_signs TriptychConfigDiagnostic

---@class TriptychState
---@field new fun(config: TriptychConfig, opening_win: integer): TriptychState
---@field list_add fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_remove fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_remove_all fun(self: TriptychState, list_type: 'cut' | 'copy'): nil
---@field list_toggle fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field list_contains fun(self: TriptychState, list_type: 'cut' | 'copy', item: PathDetails): nil
---@field windows ViewState
---@field cut_list PathDetails[]
---@field copy_list PathDetails[]
---@field path_to_line_map { [string]: integer }
---@field opening_win integer
---@field show_hidden boolean

---@alias AutoCommandMessage ('DirRead' | 'FileRead')

---@class AutoCommands
---@field new fun(state: TriptychState): AutoCommands
---@field destroy_autocommands fun(): nil
---@field autocmds integer[]
---@field send fun()

---@class TriptychConfigMappings
---@field show_help KeyMapping
---@field jump_to_cwd KeyMapping
---@field nav_left KeyMapping
---@field nav_right KeyMapping
---@field open_vsplit KeyMapping
---@field open_hsplit KeyMapping
---@field open_tab KeyMapping
---@field delete KeyMapping
---@field add KeyMapping
---@field copy KeyMapping
---@field rename KeyMapping
---@field cut KeyMapping
---@field paste KeyMapping
---@field quit KeyMapping
---@field toggle_hidden KeyMapping

---@class ExtensionMapping
---@field mode string
---@field fn fun(contents: PathDetails): nil

---@class TriptychConfigOptions
---@field dirs_first boolean
---@field show_hidden boolean
---@field line_numbers TriptychConfigLineNumbers
---@field file_icons TriptychConfigFileIcons
---@field column_widths number[]
---@field highlights TriptychConfigHighlights
---@field syntax_highlighting TriptychConfigSyntaxHighlighting
---@field backdrop number

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

---@alias GitFileStatus ('A' | 'D' | 'M' | 'R' | '??')

---@class Git
---@field new fun(): Git
---@field status_of fun(self: Git, path: string): GitFileStatus | nil
---@field should_ignore fun(self: Git, name: string, is_dir: boolean): boolean

---@class PathDetails
---@field path string
---@field display_name string
---@field dirname string # Parent directory path
---@field is_dir boolean
---@field is_git_ignored boolean
---@field filetype? string
---@field git_status? string
---@field diagnostic_status? integer
---@field children? PathDetails

---@class ViewState
---@field parent ViewStateWindow
---@field current ViewStateCurrentWindow
---@field child ViewStateChildWindow

---@class ViewStateWindow
---@field path string
---@field contents? PathDetails
---@field win number

--- TODO: This inheritance isn't working properly
---@class ViewStateCurrentWindow: ViewStateWindow
---@field previous_path string

---@class ViewStateChildWindow: ViewStateWindow
---@field is_dir boolean

---@alias WinType 'parent' | 'primary' | 'child'

---@class FloatingWindowConfig
---@field width number
---@field height number
---@field x_pos number
---@field y_pos number
---@field is_focusable boolean
---@field enable_cursorline boolean
---@field show_numbers boolean
---@field relative_numbers boolean
---@field role WinType

---@class HighlightDetails
---@field icon HighlightDetailsIcon
---@field text HighlightDetailsText

---@class HighlightDetailsIcon
---@field highlight_name string
---@field length number

---@class HighlightDetailsText
---@field highlight_name string
---@field starts number

---@class Diagnostics
---@field new fun(): Diagnostics
---@field get fun(self: Diagnostics, path: string): integer | nil
