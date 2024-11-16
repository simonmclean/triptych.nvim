---@alias AutoCommandMessage ('DirRead' | 'FileRead')

---@class AutoCommands
---@field new fun(state: TriptychState): AutoCommands
---@field destroy_autocommands fun(): nil
---@field autocmds integer[]
---@field send fun()

---@alias GitFileStatus ('A' | 'D' | 'M' | 'R' | '??')

---@class Git
---@field new fun(): Git
---@field status_of fun(self: Git, path: string): GitFileStatus | nil
---@field should_ignore fun(self: Git, name: string, is_dir: boolean): boolean

---@class PathDetails
---@field path string
---@field collapse_path? string
---@field display_name string
---@field collapse_display_name string
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
---@field border number
---@field x_pos number
---@field y_pos number
---@field is_focusable boolean
---@field enable_cursorline boolean
---@field show_numbers boolean
---@field relative_numbers boolean
---@field role WinType
---@field hidden boolean
---@field transparency number

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
