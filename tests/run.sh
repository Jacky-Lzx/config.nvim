#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/nvim-tests.XXXXXX")
test_tmp=$(CDPATH='' cd -- "$test_tmp" && pwd -P)
trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM

export XDG_CONFIG_HOME="$test_tmp/config"
export XDG_DATA_HOME="$test_tmp/data"
export XDG_STATE_HOME="$test_tmp/state"
export XDG_CACHE_HOME="$test_tmp/cache"
export XDG_CONFIG_DIRS="$test_tmp/config-dirs"
export XDG_DATA_DIRS="$test_tmp/data-dirs"
export NVIM_APPNAME=nvim
export NVIM_LOG_FILE="$test_tmp/nvim.log"
export NVIM_TEST_TMP="$test_tmp"

mkdir -p "$XDG_CONFIG_HOME" "$test_tmp/work"
ln -s "$root" "$XDG_CONFIG_HOME/$NVIM_APPNAME"
cd "$test_tmp/work"

if ! nvim --headless -i NONE -c "lua dofile(vim.fn.stdpath('config') .. '/tests/core.lua')" > "$test_tmp/core.log" 2>&1; then
  cat "$test_tmp/core.log"
  exit 1
fi
sed -n '/^Core checks:/p' "$test_tmp/core.log"

if ! nvim --headless -i NONE -c "lua dofile(vim.fn.stdpath('config') .. '/tests/persistence.lua')" > "$test_tmp/persistence.log" 2>&1; then
  cat "$test_tmp/persistence.log"
  exit 1
fi
cat "$test_tmp/persistence.log"
