<!-- panvimdoc-ignore-start -->
<h1 align="center">Triptych.nvim</h1>

<p align="center">Directory browser for Neovim, inspired by <a href="https://github.com/ranger/ranger">Ranger</a></p>

![Triptych screenshot](screenshot.jpg "Triptych screenshot")

[![CI](https://github.com/simonmclean/triptych.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/simonmclean/triptych.nvim/actions/workflows/ci.yml)

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment ## How it works -->

The UI consists of 3 floating windows. In the center is the currently focused directory. On the left is the parent directory.
The right window contains either a child directory, or a file preview.

With default bindings use `j` and `k` (or any other motions like `G`,  `gg`, `/` etc) to navigate within the current directory.
Use `h` and `l` to switch to the parent or child directories respectively.
If the buffer on the right is a file, then pressing `l` will close Triptych and open that file in the buffer you were just in.
You only ever control or focus the middle window.

## ✨ Features

- Rapid, intuitive directory browsing
- File preview
- Devicons support
- Git signs
- Diagnostic signs
- Perform common actions on the filesystem
    - Rename
    - Delete (including bulk)
    - Copy 'n' paste (including bulk) [^1]
    - Cut 'n' paste (including bulk) [^1]
    - LSP integration (via [antosha417/nvim-lsp-file-operations](https://github.com/antosha417/nvim-lsp-file-operations))
- Extensible

[^1]: These are not currently working on the Windows operating system

## ⚡️ Requirements

- Neovim >= 0.9.0
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Optional, if you want fancy icons
    - [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
    -  A [Nerd Font](https://www.nerdfonts.com/)
- Optional, if you want LSP integration for filesystem operations
   - [antosha417/nvim-lsp-file-operations](https://github.com/antosha417/nvim-lsp-file-operations)

## 📦 Installation

Example using [Lazy](https://github.com/folke/lazy.nvim).

```lua
{
  'simonmclean/triptych.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'nvim-tree/nvim-web-devicons', -- optional for icons
    'antosha417/nvim-lsp-file-operations' -- optional LSP integration
  },
  opts = {}, -- config options here
  keys = {
    { '<leader>-', ':Triptych<CR>' },
  },
}
```

If not using Lazy, you may need to call the `setup` function and specify a keymap manually.

```lua
-- Manual setup
require('triptych').setup()
vim.keymap.set('n', '<leader>-', ':Triptych<CR>', { silent = true, desc = 'Toggle Triptych' })
```

## ⚙️ Configuration

Below is the default configuration. Feel free to override any of these.

Key mappings can either be a string, or a table of strings if you want multiple bindings.

```lua
{
  mappings = {
    -- Everything below is buffer-local, meaning it will only apply to Triptych windows
    show_help = 'g?',
    jump_to_cwd = '.',  -- Pressing again will toggle back
    nav_left = 'h',
    nav_right = { 'l', '<CR>' }, -- If target is a file, opens the file in-place
    open_hsplit = { '-' },
    open_vsplit = { '|' },
    open_tab = { '<C-t>' },
    cd = '<leader>cd',
    delete = 'd',
    add = 'a',
    copy = 'c',
    rename = 'r',
    rename_from_scratch = 'R',
    cut = 'x',
    paste = 'p',
    quit = 'q',
    toggle_hidden = '<leader>.',
    toggle_collapse_dirs = 'z',
  },
  extension_mappings = {},
  options = {
    dirs_first = true,
    show_hidden = false,
    collapse_dirs = true,
    line_numbers = {
      enabled = true,
      relative = false,
    },
    file_icons = {
      enabled = true,
      directory_icon = '',
      fallback_file_icon = ''
    },
    responsive_column_widths = {
      -- Keys are breakpoints, values are column widths
      -- A breakpoint means "when vim.o.columns >= x, use these column widths"
      -- Columns widths must add up to 1 after rounding to 2 decimal places
      -- Parent or child windows can be hidden by setting a width of 0
      ['0'] = { 0, 0.5, 0.5 },
      ['120'] = { 0.2, 0.3, 0.5 },
      ['200'] = { 0.25, 0.25, 0.5 },
    },
    highlights = { -- Highlight groups to use. See `:highlight` or `:h highlight`
      file_names = 'NONE',
      directory_names = 'NONE',
    },
    syntax_highlighting = { -- Applies to file previews
      enabled = true,
      debounce_ms = 100,
    },
    backdrop = 60 -- Backdrop opacity. 0 is fully opaque, 100 is fully transparent (disables the feature)
    transparency = 0, -- 0 is fully opaque, 100 is fully transparent
    border = 'single' -- See :h nvim_open_win for border options
    max_height = 45,
    max_width = 220,
    margin_x = 4 -- Space left and right
    margin_y = 4 -- Space above and below
  },
  git_signs = {
    enabled = true,
    signs = {
      -- The value can be either a string or a table.
      -- If a string, will be basic text. If a table, will be passed as the {dict} argument to vim.fn.sign_define
      -- If you want to add color, you can specify a highlight group in the table.
      add = '+',
      modify = '~',
      rename = 'r',
      untracked = '?',
    },
  },
  diagnostic_signs = {
    enabled = true,
  }
}
```

## Commands
```viml
" Toggle Triptych
:Triptych

" Open Triptych at specific directory
:Triptych ~/Documents
```

## LSP Integration

If you have [antosha417/nvim-lsp-file-operations](https://github.com/antosha417/nvim-lsp-file-operations) installed, performing
certain filesystem operations in Triptych (creating, deleting and moving/renaming files and folders) will send a message to the language server via LSP.

> [!IMPORTANT]
> Triptych itself doesn't have any LSP related code. It merely publishes events about what's changed. `nvim-lsp-file-operations` then subscribes to these events, and informs the language server via LSP. What effect this has depends entirely on the capabilities of the language server, as well as how the user has configured it.

## Extending functionality

The `extension_mappings` property allows you add any arbitrary functionality based on the current cursor target.
You simply provide a key mapping, a vim mode, and a function. When the mapped keys are pressed, the function is invoked and is passed two arguments:
A table describing the current cursor "target", and a function which refreshes the view. The target table looks as follows:

```lua
{
  dirname, -- e.g. /User/Name/foo
  display_name -- e.g. 'bar.js'
  filetype, -- e.g. 'javascript'
  is_dir, -- boolean indicating whether this is a directory
  path, -- e.g. /User/Name/foo/bar.js
}
```

### Examples

#### Telescope integration

If you want to make `<c-f>` search the file or directory under the cursor using [Telescope](https://github.com/nvim-telescope/telescope.nvim) try something like:

```lua
{
  opts = {
    extension_mappings = {
      ['<c-f>'] = {
        mode = 'n',
        fn = function(target, _)
          require 'telescope.builtin'.live_grep {
            search_dirs = { target.path }
          }
        end
      }
    }
  }
}
```
