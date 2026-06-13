# Outstanding work

Forward-looking items only. Completed work (the `\multirow` fix, the YAML
parser, the three-layer templates, the installer, the `.deb`, externalised
brands) is in the git history.

## 1. Filter should own its package dependencies

The Lua filter emits raw LaTeX for charts (`tikz`/`pgfplots`/`pgf-pie`) but only
records the requirement as a `% Requires:` comment - the same latent failure the
`\multirow` fix removed for tables. Make `document-filters.lua` inject the chart
packages (and any future feature packages) the way `pipeline-preamble.tex`
already does, so a chart can never fail under a template that forgot a package.

## 2. Harden the driver (still Bash)

- Replace the `eval` in `run_pandoc`'s filter assembly with a Bash array and `"${arr[@]}"` expansion.
- Add `set -euo pipefail` (with deliberate exceptions) so a failed sub-step does not pass silently.
- Clean the `mktemp -d` working directory on success (keep it only on failure, for debugging).
- Fix `[[ -z "$MDSRC" ]]` (tests only the first array element) to `[[ ${#MDSRC[@]} -eq 0 ]]`.

## 3. Document versioning

Port the bump-on-content-change idea from the original `compile.sh`, without
writing to the source Markdown (which may be non-local):

- Keep a registry at `${XDG_STATE_HOME:-~/.local/state}/pandoc-wrapper/versions.json`, keyed by document identity (explicit `docid:` → title slug → source path/URL).
- Hash the document sources (before brand merge / date injection); on change, bump the last version component and stamp today's date; otherwise reuse.
- Inject the resolved version as `--metadata revision=...`, consumed by the template - never back into the source.
- Implement as `scripts/version.pl` called by the driver. Offer an opt-in sidecar mode for git-tracked local docs.

## 4. Slides / presentation template

Add a beamer template that meets `TEMPLATE-CONTRACT.md`, selectable with
`template: <name>`. Charts and boxes render differently in beamer, so build it
fresh against the conformance fixture rather than reusing the old Eisvogel beamer.

## 5. Automated tests

No automated tests yet. The pure-logic functions are the first candidates:
filename generation, the front-matter registry parsing, and (once built) version
bumping. Add these before any larger refactor.

## 6. Perl port - only when triggered

`md-to-pdf.sh` is fine in Bash today. Port to Perl when two or more of these
become true: the metadata model outgrows a handful of scalars; you need to both
read and emit YAML; a second output format is added; you want unit tests around
the merge/filename logic. Perl then buys real data structures, robust YAML, and
list-form `system()` that removes the quoting hazards above.
