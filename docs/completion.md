# Completion

[Quick start](../README.md) · [Native snippets](snippets.md) · [Workflows](workflows.md)

`completion-tools.nvim` owns the completion menu and documentation. Personal
options live in `lua/integrations/completion/init.lua`; buffer-local source
selection lives in `sources.lua` beside it. The package is declared directly in
`lua/plugins/coding/completion.lua`. Development checkouts take priority, with
locked GitHub packages as the managed fallback; see [installation](installation.md).

LSP capability negotiation uses the plugin's pure capability API. Interactive
completion initializes on Insert mode, command-line use or an explicit command.
Command-line completion does not start unrelated snippet or AI services.

## Sources

Code uses LSP, paths, buffers and snippets, plus Copilot when the `ai` workflow is
enabled. Markdown, plain text, Typst and TeX prose also request dictionary and
spelling sources. Parsed TeX math excludes dictionary, spell and Copilot from its
automatic defaults. Explicit source choices override automatic context selection.

Paths resolve from the current working directory. Buffer candidates come from
the current buffer and other loaded buffers of the same filetype, bounded to
1 MiB per buffer. The dictionary reads `configs/dictionary.txt`, requires three
characters and returns at most ten fuzzy matches. Spelling follows native window
spell settings. Obsidian contributes candidates only inside a configured vault.

`Alt-n` / `Alt-p` cycle the current buffer through automatic defaults, words
(`buffer`, `dictionary`, `spell`), snippets, and code (`lsp`, `path`). The selected
group persists during subsequent typing. With `ai` enabled, `Alt-i` toggles
Copilot for the current buffer. Copilot's score offset is below LSP; matching
still determines the final order.

## Menu and input

- `Alt-j` / `Alt-k` or `Ctrl-n` / `Ctrl-p`: next/previous candidate.
- `Alt-d` / `Alt-u`: move five candidates, stopping at the boundaries.
- `Tab`: accept a candidate, otherwise jump forward in a snippet when possible.
- `Enter`: accept a candidate, otherwise use the configured paired newline.
- `Shift-Enter`: insert a newline without accepting a candidate.
- `Ctrl-u` / `Ctrl-d`: scroll documentation.
- `Ctrl-Space`: show completion or its documentation.
- `Alt-/`: toggle the completion menu.

Snippet field and choice keys are described in [native snippets](snippets.md).
The menu shows kind icons, labels, kinds and source names. Documentation opens
automatically; provider rendering and lifecycle belong to completion-tools.

## Command line and Copilot

For `:`, completion uses native commands and arguments; `/` and `?` use buffer
words. Navigation and five-item jumps use the same keys as the Insert-mode menu.
`Tab` accepts, `Shift-Tab` moves backward, and Enter executes the command or
search. input-tools owns the prompt; completion uses its public layout to avoid
covering it. input-tools' Vim-mode input windows retain native explicit
`Ctrl-x Ctrl-u` completion.

Copilot requires `copilot-language-server` and authentication through
`:CompletionToolsCopilot auth`. `:CompletionToolsCopilot status` reports its state.
The server starts when an AI request or explicit authentication needs it.
`:CompletionToolsInfo` and `:checkhealth completion_tools` inspect the integration.
The plugin's help reference owns complete command and API documentation.
