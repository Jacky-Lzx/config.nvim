#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

NVIM_CONFIG_ROOT="$root" nvim --headless -u NONE -l "$root/tests/smoke.lua"
NVIM_SMOKE_TEST=1 nvim --headless -u "$root/init.lua" -c "lua vim.defer_fn(function() vim.cmd('quitall!') end, 300)"
