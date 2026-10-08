#!/bin/sh
set -eu

case "${1:-}" in
  ""|--core) ;;
  *) printf 'Usage: %s [--core]\n' "$0" >&2; exit 2 ;;
esac

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
installed_plugins="${NVIM_TEST_PLUGIN_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-$(basename "$root")}/lazy}"
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
export NVIM_TEST_PLUGIN_ROOT="$installed_plugins"

config="$XDG_CONFIG_HOME/$NVIM_APPNAME"
mkdir -p "$config" "$test_tmp/work"
cp -R "$root/init.lua" "$root/lua" "$root/tests" "$root/lazy-lock.json" "$config/"
cd "$test_tmp/work"

run_test() {
  script="$1"
  log="$test_tmp/$script.log"
  if ! nvim --headless -i NONE \
    --cmd "lua dofile(vim.fn.stdpath('config') .. '/tests/setup.lua')" \
    -c "lua dofile(vim.fn.stdpath('config') .. '/tests/$script.lua')" > "$log" 2>&1; then
    cat "$log"
    exit 1
  fi
  summary=$(sed -n '/^[A-Za-z]* checks:/p; /^PASS: undo history/p' "$log")
  if [ -z "$summary" ]; then
    cat "$log"
    exit 1
  fi
  printf '%s\n' "$summary"
}

export NVIM_CONFIG_PROFILE=core
run_test core
run_test persistence
run_test settings
if [ "${1:-}" = "--core" ]; then
  exit 0
fi

export NVIM_CONFIG_PROFILE=default
export NVIM_TEST_MODE=missing
run_test isolation
export NVIM_CONFIG_PROFILE=core
run_test lock

mkdir -p "$XDG_DATA_HOME/$NVIM_APPNAME/lazy"
cp -R "$installed_plugins/lazy.nvim" "$installed_plugins/blink.cmp" "$installed_plugins/LuaSnip" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"

printf 'return { features = { input = false } }\n' > "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=default
export NVIM_TEST_MODE=disabled
run_test isolation
rm "$config/lua/config/local.lua"

mv "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip" "$test_tmp/LuaSnip"
export NVIM_TEST_MODE=partial
run_test isolation
mv "$test_tmp/LuaSnip" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip"

run_test input
export NVIM_DEV_PLUGIN_ROOT="$test_tmp/no-local-plugins"
run_test input
