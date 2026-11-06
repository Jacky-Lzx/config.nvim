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
export NVIM_PLUGIN_TOOLS_PATH="${NVIM_PLUGIN_TOOLS_PATH:-$HOME/Documents/Github/nvim_plugins/plugin-tools.nvim}"
export NVIM_LOG_FILE="$test_tmp/nvim.log"
export SSH_CONNECTION=
unset PROF NVIM_PLUGIN_LOCKFILE NVIM_TEST_SCENARIO NVIM_COLUMN_GUIDE_STARTUP BARS_TEST NVIM_TEST_LINK_FIRST
# Plugin startup may refresh locks; smoke runs must not rewrite the checkout.
cp "$root/plugin-tools-lock.json" "$test_tmp/plugin-tools-lock.json"
export NVIM_PLUGIN_LOCKFILE="$test_tmp/plugin-tools-lock.json"

# Test-only fixtures exercise the restorable optional integrations. Production
# startup reads only each declaration's enabled field.
export NVIM_TEST_ENABLE_THIRD_PARTY=1

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
    nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/checked.lua" "$root/tests/$test.lua"
  done
}

native_checks() (
  cd -- "$root"
  # Prove that this suite cannot silently depend on installed or local plugins.
  export XDG_DATA_HOME="$test_tmp/native-data"
  export NVIM_DEV_PLUGIN_ROOT="$test_tmp/native-dev-plugins"
  printf '\nRunning native checks with isolated plugin data\n'
  nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/smoke.lua"
  run_tests plugin_bootstrap lockfile schema selection info config platform core bindings clipboard diagnostics \
    completion math_conditions latex_forward_search latex_highlighting_fallback commands python tasks integrations image_activation tooling toolchain lsp_config files
)

integration_checks() (
  cd -- "$root"
  printf '\nRunning integration checks with installed plugins\n'
  run_tests open_at_cursor toggles obsidian_local comments folding rust treesitter_runtime tools_runtime lsp_tools notifications image_preview bars semantic_icons git_tools column_guide toolchain_backend tasks_session workspaces
  python3 "$root/tests/open_at_cursor_tui.py"
  NVIM_TEST_LINK_FIRST=1 nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/lsp_tools.lua"
  NVIM_TEST_REFERENCE_FIRST=1 nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/lsp_tools.lua"
  BARS_TEST=before nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/bars.lua"
  run_tests plugin_manifest plugin_sources
  installed_plugins=$(nvim --headless -u NONE -i NONE --noplugin \
    --cmd "lua io.stdout:write(vim.fn.stdpath('data') .. '/plugin-tools')" +qa)
  fallback_ready=true
  for plugin in notification-tools.nvim input-tools.nvim ui-tools.nvim selection-tools.nvim; do
    if [ ! -d "$installed_plugins/$plugin" ]; then fallback_ready=false; fi
  done
  if [ "$fallback_ready" = true ]; then
    NVIM_DEV_PLUGIN_ROOT="$test_tmp/missing-dev-plugins" nvim --headless -u NONE -i NONE --noplugin \
      -l "$root/tests/notifications.lua"
  else
    printf '\nSkipping remote notification fallback: required installed checkouts are absent\n'
  fi

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
    -c 'lua local ok, err = pcall(dofile, vim.env.NVIM_CONFIG_ROOT .. "/tests/latex_queries.lua"); if not ok then io.stderr:write(tostring(err)); vim.cmd("cquit 1") end' +qa!
  NVIM_TEST_SCENARIO=writing nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_highlighting.lua')"

  NVIM_WORKSPACE_ENABLED=0 run_tests workspaces
  python3 "$root/tests/workspace_tui.py"

  python3 "$root/tests/tui.py" notifications
  python3 "$root/tests/tui.py" notification_picker
  python3 "$root/tests/tui.py" completion_input
  python3 "$root/tests/tui.py" native_utilities
  python3 "$root/tests/tui.py" python_environment
  run_tests latex_snippet_collections snippet_collections
  NVIM_TEST_SCENARIO=writing run_tests snippets latex_snippets
  python3 "$root/tests/latex_snippets_tui.py"
  python3 "$root/tests/snippets_tui.py"
  python3 "$root/tests/tui.py" toolchain
  python3 "$root/tests/tui.py" motion
  NVIM_TEST_SCENARIO=default python3 "$root/tests/tui.py" motion
  python3 "$root/tests/treesitter_tui.py"
  python3 "$root/tests/lsp_native_tui.py"

  NVIM_TEST_SCENARIO=writing nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_tools.lua')"

  # A PTY validates native startup, ConfigReady, and actual terminal input.
  for scenario in boundaries boundaries_files tasks editing editing_input completion ui_tools annotations bars folding keymaps \
    image_plain image_edit image_existing image_tex_reference image_typst_reference image_markdown_formula \
    image_disabled image_formula image_file; do
    python3 "$root/tests/tui.py" "$scenario"
  done
)

if [ "$suite" != native ]; then
  NVIM_TEST_ENABLE_THIRD_PARTY=0 nvim --headless -u NONE -i NONE --noplugin \
    -l "$root/tests/per_plugin_flags.lua"
  printf '\nRunning personal defaults with enabled and disabled third-party plugins\n'
  NVIM_TEST_ENABLE_THIRD_PARTY=0 nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/third_party_policy.lua')"
fi

case "$suite" in
native) native_checks ;;
integration) integration_checks ;;
all)
  native_checks
  integration_checks
  ;;
esac

printf '\nSmoke checks passed (%s)\n' "$suite"
