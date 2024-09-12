# Testing

This project has a bespoke test framework, created to more easily handle the async requirements of testing Triptych.

It works somewhat like [Cypress](https://www.cypress.io) in that tests performs user actions, and then assert what's displayed on screen
(or anything really, like filesystem changes)

### Test playground

Since the UI tests perform real user actions, this means real filesystem changes. As such the `test_playground` directory
exists as a safe place to run such actions and to simulate a real project environment.

## Running tests

Individual spec files can be run by sourcing them. e.g. `:source %` or `:so%`.

There's also `run_specs.lua` which does this for all files in the `specs` directory. Just do `so%` from `run_specs.lua`.

Tests can also be run headlessly from outside Neovim, by doing.

```
cd <project-root>
HEADLESS=true nvim --headless +"so%" tests/run_specs.lua
```
