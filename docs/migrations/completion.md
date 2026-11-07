# Blink to completion-tools migration

These notes summarize the November 2026 migration from Blink and LuaSnip. They
describe the migration period rather than a current feature matrix. See
[completion](../completion.md), [native snippets](../snippets.md) and
[installation](../installation.md) for the active configuration.

## Installation and ownership

Early integration required a local development checkout. That requirement is
obsolete: completion-tools and snippet-tools now declare published GitHub sources
and use exact lockfile revisions when a development checkout is absent. Startup
does not install missing packages; the explicit installer prepares them.

completion-tools replaced Blink's menu, documentation and command-line candidate
UI. snippet-tools replaced LuaSnip's expansion, fields, choices and selected-text
capture. pairs retained pairing and newline behavior; input-tools retained the
command line and text prompts. Completion adapters compose those public APIs.

All 154 personal snippets were migrated into `lua/snippet_collections/`, including
automatic, regular-expression and postfix triggers, dynamic nodes and mirrors.
The historical export remains in `tests/fixtures/snippets-legacy.json`; the
explicit migration suite checks that baseline independently of current templates.

## Provider changes

LSP, paths, same-filetype buffers, snippets, dictionary and native spelling became
independent completion-tools providers. Copilot moved from copilot.lua to a direct
connection with the official language server. Command-line completion used native
command/argument completion and buffer words for searches.

LazyDev's Blink adapter was removed. LuaLS library discovery now belongs to the independent lua-tools.nvim
plugin; it also indexes selected plugin types when editing Neovim configuration. input-tools retained explicit native completion in its Vim-mode input
windows instead of its old Blink source. BibTeX documentation compression remained
an adapter owned by this configuration.

## Historical parity notes

The migration did not attempt to preserve every Blink-specific presentation or
ranking rule. The recorded differences included language-specific colorful-menu
signature rewriting, ghost text, completion-accept automatic brackets, forced
menu direction, four-way documentation placement, persistent frecency and the
old kind/label/sort-text ranking chain. Ordinary pairing remained with pairs.

Providers were requested together and scored instead of retaining the old
LSP-to-buffer fallback gate. Snippets followed keyword filtering rather than the
old trigger-character-specific visibility rule. Signature help had already been
disabled in the old configuration and was not a migration loss.

Those points record historical scope. Consult the owning plugin's current help
before treating a recorded gap as a present limitation. Later prose/math source
policy and module reorganization are documented in the current guides and
[workflow measurement record](../performance/2026-11-07-workflows.md).
