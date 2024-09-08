# Testing

This project has a bespoke test framework, created to more easily handle the async requirements of testing this plugin.

It works somewhat like [Cypress](https://www.cypress.io) in that tests performs user actions, and then assert what's displayed on screen
(or anything really, like what's in the filesystem)

The Cypress inspired UI tests are in `tests/specs/ui_tests.lua`. All other specs are typical unit tests.

## Running tests

Individual spec files can be run by sourcing them. e.g. `:source %` or `:so%`.

There's also `run_specs.lua` which does this for all files in the `specs` directory. Just do `so%` from `run_specs.lua`.

Tests can also be run headlessly from outside Neovim, by doing

```
cd <project-root>
nvim --headless +"so%" tests/run_specs.lua
```
