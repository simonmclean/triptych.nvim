<h1 align="center">Triptych.nvim</h1>

<p align="center">Directory viewer for Neovim, inspired by <a href="https://github.com/ranger/ranger">Ranger</a></p>

![Triptych screenshot](screenshot.jpg?raw=true "Triptych screenshot")

[![Validate](https://github.com/simonmclean/triptych.nvim/actions/workflows/validate.yml/badge.svg)](https://github.com/simonmclean/triptych.nvim/actions/workflows/validate.yml)

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
    - Copy 'n' paste (including bulk)
    - Cut 'n' paste (including bulk)
- Extensible

## ⚡️ Requirements

- Neovim >= 0.9.0
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) plugin
- Optional, if you want fancy icons
    - [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) plugin
    -  A [Nerd Font](https://www.nerdfonts.com/)

## 📦 Installation

Example using [Lazy](https://github.com/folke/lazy.nvim).

```lua
{
  'simonmclean/triptych.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'nvim-tree/nvim-web-devicons', -- optional
  }
}
```

Then call the `setup` function somewhere in your Neovim config to initialise it with the default options.

```lua
require 'triptych'.setup()
```

Launch using the `:Triptych` command. You may want to create a binding for this.

```lua
vim.keymap.set('n', '<leader>-', ':Triptych<CR>', { silent = true })
```

## ⚙️ Configuration

Below is the default configuration. Feel free to override any of these.

Key mappings can either be a string, or a table of strings if you want multiple bindings.

```lua
require 'triptych'.setup {
  mappings = {
    -- Everything below is buffer-local, meaning it will only apply to Triptych windows
    show_help = 'g?',
    jump_to_cwd = '.',  -- Pressing again will toggle back
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
    file_icons = {
      enabled = true,
      directory_icon = '',
      fallback_file_icon = ''
    }
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
  }
}
```

### Extending functionality

The `extension_mappings` property allows you add any arbitrary functionality based on the current cursor target.
You simply provide a key mapping, a vim mode, and a function. When the mapped keys are pressed the function is invoked, and will receive a table containing the following:

```lua
{
  basename, -- e.g. bar.js
  children, -- table containing directory contents (if applicable)
  dirname, -- e.g. /User/Name/foo
  display_name -- same as basename (redundant field)
  filetype, -- e.g. 'javascript'
  is_dir, -- boolean indicating whether this is a directory
  path, -- e.g. /User/Name/foo/bar.js
}
```

For example, if you want to make `<c-f>` search the file or directory under the cursor using [Telescope](https://github.com/nvim-telescope/telescope.nvim).

```lua
{
  extension_mappings = {
    ['<c-f>'] = {
      mode = 'n',
      fn = function(target)
        require 'telescope.builtin'.live_grep {
          search_dirs = { target.path }
        }
      end
    }
  }
}
```
