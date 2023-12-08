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

---@class AutoCommands
---@field new fun(state: TriptychState): AutoCommands
---@field destroy_autocommands fun(): nil
---@field autocmds integer[]

---@class TriptychConfigMappings
---@field open_triptych KeyMapping
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
---@field fn fun(contents: PathDetails): nil

---@class TriptychConfigOptions
---@field dirs_first boolean
---@field show_hidden boolean
---@field line_numbers TriptychConfigLineNumbers

---@class TriptychConfigLineNumbers
---@field enabled boolean
---@field relative boolean

---@class TriptychConfigGitSigns
---@field enabled boolean
---@field signs TriptychConfigGitSignsSigns

---@class TriptychConfigGitSignsSigns
---@field add string
---@field modify string
---@field rename string
---@field untracked string

---@class TriptychConfigDiagnostic
---@field enabled boolean

---@alias KeyMapping (string | string[])

---@alias GitFileStatus ('A' | 'D' | 'M' | 'R' | '??')

---@class Git
---@field new fun(): Git
---@field status_of fun(self: Git, path: string): GitFileStatus | nil
---@field filter_ignored fun(self: Git, path_details: PathDetails): PathDetails

---@class PathDetails
---@field path string
---@field display_name string
---@field dirname string # Parent directory path
---@field basename string
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
---@field lines? string[]

---@class FloatingWindowConfig
---@field width number
---@field height number
---@field x_pos number
---@field y_pos number
---@field is_focusable boolean
---@field enable_cursorline boolean
---@field show_numbers boolean
---@field relative_numbers boolean

---@class Diagnostics
---@field new fun(): Diagnostics
---@field get fun(self: Diagnostics, path: string): integer | nil
