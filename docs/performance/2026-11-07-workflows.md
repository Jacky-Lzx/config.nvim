# TeX workflow measurements, 2026-11-07

The new workflow benchmark measures completion with a real texquill process,
200-character terminal input, configured save-time formatting, and the arrival of
fresh native diagnostics. It complements the startup/first-input benchmark.

The generated workload has 500 sections in the main file and five included
chapters. A second workload copies the existing SC Series Decomposition manuscript
before inserting benchmark probes. Original manuscript files are never edited.
Both use Neovim 0.12.6, texquill 1.0.0, a real 120x40 PTY, isolated state/cache and
ten rounds per process. Grammar checking, AI and compile-on-save are disabled;
formatting, snippets, pairing, highlighting and the configured UI remain active.

The generated comparison uses the completion policy from config `a7da446` as its
baseline, with the same currently published plugin revisions as the new policy.
Only `integrations.completion` and `features.completion` are replaced. Variants
run sequentially and their OS caches are warm. These samples support functional
regression checks; small timing differences do not establish a speedup. Ten rounds
also provide only a coarse estimate of tail latency.

Raw measurements and exact tool/plugin revisions are retained in
[generated.json](2026-11-07-generated.json) and [paper.json](2026-11-07-paper.json).
The paper workload exposes a substantial difference between the first diagnostic
refresh and subsequent refreshes. The benchmark records both rather than hiding
initial indexing work in an average. This task makes no server performance change.

## Reproduce

Run these commands in an otherwise idle environment, with the locked plugin
revisions and texquill installed. Output directories must not already exist.

```sh
TMPDIR=/private/tmp python3 tests/benchmarks/benchmark_workflows.py \
  --directory /private/tmp/nvim-workflows --sections 500 --rounds 10

TMPDIR=/private/tmp python3 tests/benchmarks/benchmark_workflows.py \
  --directory /private/tmp/nvim-paper --rounds 10 \
  --project /path/to/SC_Series_Decomposition/latex --document main.tex
```

`--baseline` accepts the same module-to-source JSON mapping as the existing
interaction benchmark. For the recorded comparison, extract
`lua/integrations/completion.lua` and `lua/features/completion/init.lua` from
`a7da446`, then map `integrations.completion` and `features.completion` to those
files. Those names describe the recorded checkout. The source policy now lives
at `integrations.completion.sources`; to run the old integration snapshot against
the grouped layout, also map `integrations.completion.sources` to the historical
`features.completion` source. Keep the historical `features.completion` mapping
because the old integration still imports that name. The harness copies the
provided snapshots into each retained trial.

Each run retains `report.json`, the config diff and lock, benchmark source
snapshots, project copies, per-process terminal logs and final Neovim state.
Successful measured runs for this change are retained locally under
`/private/tmp/nvim-workflows-final` and `/private/tmp/nvim-paper-final`.

Completion ends after a real LSP candidate exists and a redraw completes; the
test separately verifies that the label was rendered. Burst input ends when all
200 characters are present. Save ends after `BufWritePost` and redraw. Input
measurements include the parent's short observation interval. Diagnostic timing
starts at insertion of a unique unmatched environment and ends after its native
diagnostic arrives and redraw completes. The previous probe must disappear
before the next is inserted, preventing a cached report from satisfying a later
round. These timings do not measure physical display latency.
