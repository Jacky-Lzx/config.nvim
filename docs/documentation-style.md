# Documentation style

Use the same English terminology and reading order across the configuration and
plugin collection. Preserve public API names and existing help tags when editing.

## Readers and sources

- `README.md` explains the purpose, requirements, installation and first action.
- `doc/<plugin>.txt` is the complete in-editor option, command and API reference.
- Markdown guides explain workflows, integration, migration and architecture.
- `tests/README.md` explains development prerequisites and validation.

A workflow guide may show a particular configuration. Complete defaults and API
contracts belong in the help reference; do not maintain a second parameter manual.
The configuration uses `docs/` for its guides. Plugins keep existing `doc/` guides
and assets so installed help and established links remain easy to find.

## README

Use this order: Features, Requirements, Installation, Usage, Documentation,
Development. Small plugins can keep each section short. Include only existing
captures of the actual UI; describe the demonstrated behavior in image alt text.
Put additional captures in a gallery with links to reproduction instructions.

Use public `Jacky-Lzx/<plugin>.nvim` repository identifiers. Explicitly name the
actual Lua `main` module in package-manager examples. Required dependencies must
be available before the standalone `require(...).setup(...)` example runs.
Document external executables separately from optional UI and integration plugins.
Keep local `dir` overrides in development configuration.

Show a minimal useful setup rather than the complete defaults. Distinguish example
keymaps and opt-in presets from mappings installed by the plugin. Use fenced `lua`,
`vim` and `sh` blocks and double quotes in new Lua examples.

## Vim help

The first line has a filename tag, a tab and a short description. Provide an
explicit root tag using the repository name without `.nvim`; retain older aliases
such as `pairs.nvim` and `toolchain`.

Start with a contents index linking quickstart, commands, options, API, lifecycle
and troubleshooting. Existing detailed tags remain stable and can follow their
feature-specific sections. Use namespaced tags and `|tag|` references. Prefer
78-column prose; keep literal commands and code intact. End with:

```text
vim:tw=78:ts=8:noet:ft=help:norl:
```

Document option types, defaults, scope and merge/replacement rules. Describe API
parameters, return values, callback timing, cancellation and ownership where
applicable. A setup example is not a declaration of defaults. State exceptions to
common lifecycle behavior next to the affected API.

Use "required", "optional" and "required for <feature>" precisely. Distinguish
mounting a runtime, configuring a plugin and starting a service. Use `setup`,
`disable`, `dispose`, `Info` and `checkhealth` only for their actual implemented
contracts. Do not rename public interfaces for cosmetic consistency.

## Validation

Plugin checks run in the existing registered unit suites:

```sh
python3 tests/run.py unit --filter docs
```

The configuration runs the same checker locally:

```sh
python3 scripts/check-docs.py
```

The checker validates local Markdown targets and fragments, root/section help
tags, real help lookup, Lua example syntax and isolated native plugin setup.
Help tags are generated in a temporary copy; checks do not install packages or
write generated tags into the source tree. Plugin fixtures follow their registered
test manifest. No CI workflow is added to the configuration repository.

The canonical checker is `plugin-tools.nvim/tests/docs_checks.py`. Its existing
`scripts/sync-test-runner.py` distributes identical copies to plugin checkouts.
