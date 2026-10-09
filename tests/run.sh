#!/bin/sh
set -eu

case "${1:-}" in
  ""|--core|--live) ;;
  *) printf 'Usage: %s [--core|--live]\n' "$0" >&2; exit 2 ;;
esac

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
installed_plugins="${NVIM_TEST_PLUGIN_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-$(basename "$root")}/lazy}"
installed_parsers="${NVIM_TEST_PARSER_ROOT:-$(dirname "$installed_plugins")/site}"
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
export NVIM_TEST_PARSER_ROOT="$installed_parsers"

config="$XDG_CONFIG_HOME/$NVIM_APPNAME"
mkdir -p "$config" "$test_tmp/work"
cp -R "$root/init.lua" "$root/lua" "$root/lsp" "$root/queries" "$root/tests" "$root/lazy-lock.json" "$config/"
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
  summary=$(sed -n '/^[A-Za-z ]* checks:/p; /^PASS: undo history/p' "$log")
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
run_test lsp_roots
if [ "${1:-}" = "--core" ]; then
  exit 0
fi

export NVIM_CONFIG_PROFILE=default
export NVIM_TEST_MODE=missing
run_test isolation
export NVIM_CONFIG_PROFILE=core
run_test lock

mkdir -p "$XDG_DATA_HOME/$NVIM_APPNAME/lazy"
cp -RL "$installed_plugins/lazy.nvim" "$installed_plugins/blink.cmp" "$installed_plugins/LuaSnip" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"

printf 'return { features = { theme = false, input = false, picker = false, treesitter = false, textobjects = false, git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=default
export NVIM_TEST_MODE=disabled
run_test isolation
export NVIM_TEST_LSP_MODE=missing
run_test lsp_isolation
unset NVIM_TEST_LSP_MODE
if [ "${1:-}" = "--live" ]; then
  run_test lsp_isolation
fi
rm "$config/lua/config/local.lua"

mv "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip" "$test_tmp/LuaSnip"
export NVIM_TEST_MODE=partial
run_test isolation
mv "$test_tmp/LuaSnip" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip"

run_test input
export NVIM_TEST_MODE=missing-picker
run_test picker_isolation
cp -RL "$installed_plugins/snacks.nvim" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"
mv "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip" "$test_tmp/LuaSnip"
export NVIM_TEST_MODE=missing-input
run_test picker_isolation
mv "$test_tmp/LuaSnip" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/LuaSnip"
printf 'return { features = { input = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_MODE=picker-only
run_test picker_isolation
rm "$config/lua/config/local.lua"
run_test picker
run_test search
export NVIM_TEST_PICKER_TOOLS=rg-only
run_test search
export NVIM_TEST_PICKER_TOOLS=missing
run_test search_missing
unset NVIM_TEST_PICKER_TOOLS
export NVIM_TEST_TREESITTER_MODE=missing-plugin
run_test treesitter
cp -RL "$installed_plugins/nvim-treesitter" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"
export NVIM_TEST_TREESITTER_MODE=missing-parser
run_test treesitter
export NVIM_TEST_TS_TOOLS=missing
run_test treesitter
unset NVIM_TEST_TS_TOOLS
mkdir -p "$XDG_DATA_HOME/$NVIM_APPNAME/site/parser" "$XDG_DATA_HOME/$NVIM_APPNAME/site/parser-info" "$XDG_DATA_HOME/$NVIM_APPNAME/site/queries"
cp "$installed_parsers/parser/lua.so" "$XDG_DATA_HOME/$NVIM_APPNAME/site/parser/"
cp "$installed_parsers/parser-info/lua.revision" "$XDG_DATA_HOME/$NVIM_APPNAME/site/parser-info/"
cp -RL "$installed_parsers/queries/lua" "$XDG_DATA_HOME/$NVIM_APPNAME/site/queries/"
export NVIM_TEST_TREESITTER_MODE=available
run_test treesitter
unset NVIM_TEST_TREESITTER_MODE
export NVIM_TEST_THEME_MODE=missing
run_test theme
cp -RL "$installed_plugins/catppuccin" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"
export NVIM_TEST_THEME_MODE=available
run_test theme
export NVIM_TEST_TREESITTER_MODE=available
export NVIM_TEST_TS_TOOLS=missing
run_test treesitter
unset NVIM_TEST_TS_TOOLS
unset NVIM_TEST_TREESITTER_MODE
export NVIM_TEST_TEXTOBJECTS_MODE=missing
run_test textobjects
cp -RL "$installed_plugins/mini.ai" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"
mv "$config/queries/lua/textobjects.scm" "$test_tmp/textobjects.scm"
export NVIM_TEST_TEXTOBJECTS_MODE=missing-query
run_test textobjects
mv "$test_tmp/textobjects.scm" "$config/queries/lua/textobjects.scm"
export NVIM_TEST_TEXTOBJECTS_MODE=available
run_test textobjects
unset NVIM_TEST_TEXTOBJECTS_MODE
export NVIM_TEST_GIT_MODE=missing
run_test git
cp -RL "$installed_plugins/gitsigns.nvim" "$XDG_DATA_HOME/$NVIM_APPNAME/lazy/"
export NVIM_TEST_GIT_MODE=missing-executable
run_test git
export NVIM_TEST_GIT_MODE=available
run_test git
unset NVIM_TEST_GIT_MODE
run_test input
run_test picker
run_test search
if [ "${1:-}" = "--live" ]; then
  run_test lsp_live
  run_test picker_live
fi
printf 'return { features = { input = false, picker = false, lsp = false, treesitter = false, textobjects = false, git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_THEME_MODE=only
run_test theme
printf 'return { features = { theme = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_THEME_MODE=disabled
run_test theme
rm "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=core
export NVIM_TEST_THEME_MODE=core
run_test theme
export NVIM_CONFIG_PROFILE=default
printf 'return { features = { theme = false, input = false, picker = false, lsp = false, textobjects = false, git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_TREESITTER_MODE=only
run_test treesitter
printf 'return { languages = { lua = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_TREESITTER_MODE=no-languages
run_test treesitter
printf 'return { features = { treesitter = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_TREESITTER_MODE=disabled
run_test treesitter
rm "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=core
export NVIM_TEST_TREESITTER_MODE=core
run_test treesitter
export NVIM_CONFIG_PROFILE=default
unset NVIM_TEST_TREESITTER_MODE
unset NVIM_TEST_THEME_MODE
printf 'return { features = { theme = false, input = false, picker = false, lsp = false, treesitter = false, git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_TEXTOBJECTS_MODE=only
run_test textobjects
printf 'return { features = { textobjects = false, git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_TEXTOBJECTS_MODE=disabled
run_test textobjects
rm "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=core
export NVIM_TEST_TEXTOBJECTS_MODE=core
run_test textobjects
export NVIM_CONFIG_PROFILE=default
unset NVIM_TEST_TEXTOBJECTS_MODE
printf 'return { features = { theme = false, input = false, picker = false, lsp = false, treesitter = false, textobjects = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_GIT_MODE=only
run_test git
printf 'return { features = { git = false } }\n' > "$config/lua/config/local.lua"
export NVIM_TEST_GIT_MODE=disabled
run_test git
rm "$config/lua/config/local.lua"
export NVIM_CONFIG_PROFILE=core
export NVIM_TEST_GIT_MODE=core
run_test git
export NVIM_CONFIG_PROFILE=default
unset NVIM_TEST_GIT_MODE
export NVIM_DEV_PLUGIN_ROOT="$test_tmp/no-local-plugins"
run_test input
