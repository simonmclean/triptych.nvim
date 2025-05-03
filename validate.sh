#!/bin/bash

# Use this script to test changes locally

echo "Checking formatting..."
npx @johnnymorganz/stylua-bin --check .
formatting_exit_code=$?

if [ $formatting_exit_code -ne 0 ]; then
  echo "1 or more files are not formatted correctly. Formatting...";
  stylua --config-path stylua.toml --respect-ignores ./
  echo "✅ Formatting complete"
else
  echo "✅ All files are formatted correctly";
fi

echo "Check diagnostics..."
~/.local/share/nvim/mason/bin/lua-language-server --check .
diagnostics_exit_code=$?

if [ $diagnostics_exit_code -ne 0 ]; then
  echo "❌ 1 or more diagnostic problems found";
else
  echo "✅ Diagnostics passed";
fi

echo "Running tests..."
HEADLESS=true nvim --headless +"so%" tests/run_specs.lua
tests_exit_code=$?

if [ $tests_exit_code -ne 0 ]; then
  echo "❌ 1 or more tests failed";
else
  echo "✅ Tests passed";
fi
