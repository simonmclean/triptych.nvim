# 📚 Tryptic

Directory viewer inspired by [Ranger](https://github.com/ranger/ranger).

The UI consists of 3 floating windows. In the center is the currently focused directory. On the left is the parent directory.
The right window contains either a child directory, or a file preview.

With default bindings use `j` and `k` (or any other motions like `G`,  `gg`, `/` etc) to navigate within the current directory.
Use `h` and `l` to switch to the parent or child directories respectively.
If the buffer on the right is a file, then pressing `l` will close Tryptic and open that file in the buffer you were just in.
You only ever control or focus the middle window.

## ✨ Features

- Rapid, intuitive directory browsing
- File preview
- Pretty icons
- Git signs (TODO)
- Diagnostic signs (TODO)
- Create files and folders
- Rename
- Delete
- Copy
- Cut 'n' paste

## ⚡️ Requirements

- Neovim >= 0.8.0
- A [Nerd Font](https://www.nerdfonts.com/) (optional)
- [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) (optional)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/tree/master) - Used to perform certain filesystem operations

## 📦 Installation

Example using [Lazy](https://github.com/folke/lazy.nvim).

```lua
{
  'simonmclean/tryptic',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'nvim-tree/nvim-web-devicons' -- optional
  }
}
```

## ⚙️ Configuration

Below is the default config. Feel free to overwrite any of these.

```lua
require 'tryptic'.setup {
  mappings = {
    open_tryptic = '<leader>-',
    -- Everything below is buffer-local, meaning it will only apply to Tryptic windows
    show_help = 'g?',
    jump_to_cwd = '.', -- Pressing again will toggle back
    nav_left = 'h',
    nav_right = { 'l', '<CR>' },
    delete = 'd',
    add = 'a',
    copy = 'c',
    rename = 'r',
    cut = 'x', -- Pressing again will remove the item from the cut list
    paste = 'p',
    quit = 'q',
    toggle_hidden = '<leader>.'
  }
}
```

Key mappings can either be a string, or a table of strings if you want multiple bindings.

## 🛠️ TODO
- Bug
    - When doing cut-n-paste, cursor pos can change in unintuitive way
- Code quality
    - Organise the contents of init.lua into a separate module
    - Maximise loading efficiency
- Features
    - When creating a file or dir, the cursor should move to it
    - Docs
    - Toggle hidden
    - Git signs
    - Diagnostics
    - Cut, copy and delete should work with visual selection
- tests
