#!/bin/sh
set -eu

usage() {
  printf 'Usage: %s [native|integration|all]\n' "$0"
}
if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi
suite=${1:-all}
case "$suite" in
native | integration | all) ;;
-h | --help)
  usage
  exit 0
  ;;
*)
  usage >&2
  exit 2
  ;;
esac

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")
trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM
export XDG_CACHE_HOME="$test_tmp/cache"
export XDG_STATE_HOME="$test_tmp/state"
export NVIM_CONFIG_ROOT="$root"
export NVIM_TEST_TMP="$test_tmp"
export NVIM_SMOKE_TEST=1
export NVIM_LOG_FILE="$test_tmp/nvim.log"
export SSH_CONNECTION=
unset PROF NVIM_LAZY_LOCKFILE NVIM_TEST_SCENARIO NVIM_COLUMN_GUIDE_STARTUP LUALINE_TEST MINI_DIFF_TEST

cat >"$test_tmp/sample.tex" <<'EOF'
\documentclass{article}
\begin{document}
\( x + y \)
\end{document}
EOF
printf 'print("hello")\n' >"$test_tmp/sample.py"
printf '<script setup lang="ts">const count = 1</script>\n' >"$test_tmp/sample.vue"

run_tests() {
  for test in "$@"; do
    printf '\nRunning tests/%s.lua\n' "$test"
    nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/$test.lua"
  done
}

native_checks() (
  cd -- "$root"
  # Prove that this suite cannot silently depend on installed or local plugins.
  export XDG_DATA_HOME="$test_tmp/native-data"
  export NVIM_DEV_PLUGIN_ROOT="$test_tmp/native-dev-plugins"
  printf '\nRunning native checks with isolated plugin data\n'
  nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/smoke.lua"
  run_tests lockfile schema selection info config platform core clipboard diagnostics column_guide \
    completion math_conditions commands python integrations open_at_cursor tooling lsp_config
)

integration_checks() (
  cd -- "$root"
  printf '\nRunning integration checks with installed plugins\n'
  run_tests obsidian_local comments folding rust lsp_tools image_preview lualine_lazy mini_diff_lazy
  LUALINE_TEST=before nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/lualine_lazy.lua"
  MINI_DIFF_TEST=direct nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/mini_diff_lazy.lua"
  NVIM_DEV_PLUGIN_ROOT="$test_tmp/missing-dev-plugins" nvim --headless -u NONE -i NONE --noplugin \
    -l "$root/tests/image_preview.lua"

  for scenario in default minimal python writing; do
    NVIM_COLUMN_GUIDE_STARTUP=1 NVIM_TEST_SCENARIO="$scenario" nvim --headless -u NONE -i NONE --noplugin \
      -l "$root/tests/column_guide.lua"
    NVIM_TEST_SCENARIO="$scenario" nvim --headless -i NONE \
      --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
      -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/folding_startup.lua')"
    NVIM_TEST_SCENARIO="$scenario" nvim --headless -i NONE \
      --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
      -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/startup.lua')"
  done

  NVIM_TEST_SCENARIO=minimal nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/input.lua')"
  NVIM_TEST_SCENARIO=writing nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_highlighting.lua')"

  NVIM_TEST_SCENARIO=writing nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_tools.lua')"

  # A PTY supplies UIEnter, which Lazy needs to fire its actual VeryLazy event.
  for scenario in boundaries boundaries_lfo editing completion; do
    python3 "$root/tests/tui.py" "$scenario"
  done
)

case "$suite" in
native) native_checks ;;
integration) integration_checks ;;
all)
  native_checks
  integration_checks
  ;;
esac
printf '\nSmoke checks passed (%s)\n' "$suite"
