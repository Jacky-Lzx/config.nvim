#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")
trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM
export XDG_CACHE_HOME="$test_tmp/cache"
export XDG_STATE_HOME="$test_tmp/state"
export NVIM_CONFIG_ROOT="$root"
export NVIM_TEST_TMP="$test_tmp"
export NVIM_SMOKE_TEST=1
export NVIM_LOG_FILE="$test_tmp/nvim.log"

cat > "$test_tmp/sample.tex" <<'EOF'
\documentclass{article}
\begin{document}
\( x + y \)
\end{document}
EOF
printf 'print("hello")\n' > "$test_tmp/sample.py"
printf '<script setup lang="ts">const count = 1</script>\n' > "$test_tmp/sample.vue"

nvim --headless -u NONE -i NONE -l "$root/tests/smoke.lua"
(
  cd -- "$root"
  for test in config platform obsidian_local core diagnostics completion math_conditions commands python rust integrations open_at_cursor tooling lsp_config lualine_lazy mini_diff_lazy; do
    printf '\nRunning tests/%s.lua\n' "$test"
    nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/$test.lua"
  done
  LUALINE_TEST=before nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/lualine_lazy.lua"
  MINI_DIFF_TEST=direct nvim --headless -u NONE -i NONE --noplugin -l "$root/tests/mini_diff_lazy.lua"
)

for scenario in default minimal python writing; do
  NVIM_TEST_SCENARIO="$scenario" nvim --headless -i NONE \
    --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
    -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/startup.lua')"
done

NVIM_TEST_SCENARIO=minimal nvim --headless -i NONE \
  --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
  -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/input.lua')"
NVIM_DEV_PLUGIN_ROOT="$test_tmp/missing-dev-plugins" NVIM_TEST_SCENARIO=minimal nvim --headless -i NONE \
  --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
  -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/input.lua')"
NVIM_TEST_SCENARIO=writing nvim --headless -i NONE \
  --cmd "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" -u "$root/init.lua" \
  -c "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_highlighting.lua')"
