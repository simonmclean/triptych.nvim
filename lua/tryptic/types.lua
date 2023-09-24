---@class TrypticConfig
---@field mappings? TrypticConfigMappings
---@field extension_mappings? { [string]: ExtensionMapping }
---@field options? TrypticConfigOptions
---@field line_numbers? TrypticConfigLineNumbers
---@field git_signs? TrypticConfigGitSigns
---@field diagnostic_signs? TrypticConfigDiagnostic
---@field debug? boolean

---@class TrypticState
---@field new fun(config: TrypticConfig, opening_win: integer): TrypticState
---@field list_add fun(self: TrypticState, list_type: 'cut' | 'copy', item: DirContents): nil
---@field list_remove fun(self: TrypticState, list_type: 'cut' | 'copy', item: DirContents): nil
---@field list_remove_all fun(self: TrypticState, list_type: 'cut' | 'copy'): nil
---@field list_toggle fun(self: TrypticState, list_type: 'cut' | 'copy', item: DirContents): nil
---@field list_contains fun(self: TrypticState, list_type: 'cut' | 'copy', item: DirContents): nil
---@field windows ViewState
---@field cut_list DirContents[]
---@field copy_list DirContents[]
---@field path_to_line_map { [string]: integer }
---@field opening_win integer
---@field show_hidden boolean

---@class AutoCommands
---@field new fun(state: TrypticState): AutoCommands
---@field destroy_autocommands fun(): nil
---@field autocmds integer[]

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

---@class ExtensionMapping
---@field mode string
---@field fn fun(contents: DirContents): nil

---@class TrypticConfigOptions
---@field dirs_first boolean
---@field show_hidden boolean

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

---@class GitStatus
---@field new fun(): GitStatus
---@field get fun(self: GitStatus, path: string): GitFileStatus | nil

---@class GitIgnore
---@field new fun(): GitIgnore
---@field is_ignored fun(self: GitIgnore, path: string): boolean

---@class DirContents
---@field path string
---@field display_name string
---@field dirname string # Parent directory path
---@field basename string
---@field is_dir boolean
---@field is_git_ignored boolean
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

---@class Diagnostics
---@field new fun(): Diagnostics
---@field get fun(self: Diagnostics, path: string): integer | nil
