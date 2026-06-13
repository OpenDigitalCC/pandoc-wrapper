---
title: "pandoc-wrapper Review and Recommendations"
subtitle: "Repository, driver script, LaTeX pipeline, and authoring skills"
brand: plain
date: 13 June 2026
---

# Summary

This document reviews the pandoc-wrapper Markdown-to-PDF pipeline and records the
changes made during this session. It covers four questions the review set out to
answer: whether `md-to-pdf.sh` should be rewritten in Perl yet, what can be
improved on the LaTeX side, how to package the house Markdown format as a reusable
skill, and how to stop the recurring `\multirow` build failure.

The pipeline is in good shape. It is well structured, the documentation is
unusually thorough, and the output is genuinely professional. The recommendations
below are about hardening and consolidation, not rescue.

Work completed this session
: Initialised the git repository; fixed the `\multirow` build failure at source;
  updated the authoring documentation; created and installed a Claude Code skill
  and a claude.ai skill for the house Markdown format.

Headline recommendations
: Keep `md-to-pdf.sh` in Bash for now, but replace its hand-rolled YAML parsing
  and add an install step. Make the Lua filter own its LaTeX package dependencies.
  Consolidate three near-duplicate templates down to one.

# The `\multirow` build failure (fixed)

## What was happening

The reported error was:

```text
PDF generation failed with exit code 43.

Error producing PDF.
! Undefined control sequence.
l.992 ...ration, compliance, accounts) & \multirow
```

A datatable with a row span (a blank leading cell) makes the Lua filter emit the
LaTeX `\multirow` command (`pandoc/templates/document-filters.lua:1167`). That
command is only defined when the `multirow` package is loaded - and nothing
guaranteed it was. The Eisvogel templates load it only inside
`$if(tables)$ ... $if(multirow)$ ... $endif$ $endif$`, and Pandoc sets neither of
those variables for our datatables, because a datatable reaches the writer as a
raw-LaTeX block, not as a native Pandoc table. So the package was simply never
loaded, and the first row span in any document failed the build.

The filter even documented the dependency as a bare comment -
`% Requires: \usepackage{longtable,multirow,array,xcolor}`
(`document-filters.lua:1198`) - but a comment loads nothing.

## The fix

The filter now injects the requirement directly into `header-includes`, which
every template honours regardless of the `$if(tables)$`/`$if(multirow)$` guards
(`document-filters.lua`, in `read_meta`):

```lua
local pkg_block = pandoc.RawBlock("latex", "\\usepackage{multirow}\n\\usepackage{array}")
-- appended to meta["header-includes"]
```

This is the same mechanism the filter already uses to inject brand-colour
definitions, so it fits the existing design. It was verified by rendering a
row-span datatable to LaTeX and confirming `\usepackage{multirow}` now appears in
the preamble.

Documentation was updated in two places so authors can self-diagnose if they ever
meet the error on an older pipeline: a troubleshooting section in
`Markdown-authoring-guide.md` and a note beside the datatable section in
`claude-markdown-formatting-instructions.md`.

::: recommendation
Apply the same "filter owns its dependencies" principle to the other raw-LaTeX
constructs (see LaTeX recommendations below). The `\multirow` failure is one
instance of a general fragility, not a one-off.
:::

# Should `md-to-pdf.sh` be Perl yet?

## Verdict

Not yet. Keep it in Bash for now, but make two targeted changes that remove its
most brittle parts. Plan a Perl port for when - not if - the metadata logic grows.

The script is ~580 lines, cleanly decomposed into single-purpose functions with a
readable `main`. For what it does today - collect inputs, read a handful of
front-matter scalars, merge a brand, and shell out to Pandoc - Bash is a
reasonable fit and a rewrite would be churn for its own sake. The host is
Perl-heavy, so Perl is the natural destination when a rewrite is justified; the
trigger should be need, not language preference.

## The one part that genuinely strains Bash

YAML metadata is parsed by hand with repeated `awk`/`sed`/`tr`/`xargs` pipelines,
one pass per field (`md-to-pdf.sh:309-339`). This is the script's weak point:

- It cannot handle nested keys, lists, multi-line scalars, or quoted colons reliably.
- It runs `awk` over the whole document roughly ten times, once per field.
- The brand merge has to save each document value, re-run the whole extraction
  against the brand, then restore the saved values (`md-to-pdf.sh:539-561`) -
  convoluted, and a sign the data wants a real structure.

A single call to a real YAML parser would replace all of it and be far more
robust. This does not require leaving Bash:

```bash
# one helper, one parse, real YAML semantics
eval "$(perl -MYAML::XS -e '...' < "$frontmatter")"   # or python3 -c '...'
```

## Other Bash issues worth fixing in place

`eval` in the Pandoc invocation
: `run_pandoc` builds the Lua-filter arguments and runs them through
  `$(eval echo "$lua_filters")` (`md-to-pdf.sh:471`). `eval` on a constructed
  string is a quoting hazard and is unnecessary - build the arguments as a Bash
  array and expand `"${args[@]}"`. The displayed `pandoc_cmd` string
  (`md-to-pdf.sh:467`) also duplicates the real invocation and can drift from it.

No strict mode
: The script does not set `set -euo pipefail`. With hand-built pipelines and
  array handling, an unset variable or a failed sub-step can pass silently.

Array-as-scalar test
: `[[ -z "$MDSRC" ]]` (`md-to-pdf.sh:237`) tests only the first array element.
  It works by accident; `[[ ${#MDSRC[@]} -eq 0 ]]` says what is meant.

Temp directories never cleaned
: `cleanup` is a deliberate no-op (`md-to-pdf.sh:517-521`), so every run leaves a
  `mktemp -d` directory in `/tmp`. Keep-on-failure for debugging is sensible;
  clean-on-success is not happening at all.

## When to actually port to Perl

Port when two or more of these become true:

- The metadata model outgrows a handful of scalars (nested config, lists, per-section overrides).
- You need to both read and emit YAML reliably.
- You add a second output format or a real plugin/filter selection mechanism.
- You want unit tests around filename generation and brand merging.

At that point Perl buys real data structures, robust YAML (`YAML::XS` /
`YAML::PP`), `Getopt::Long` argument parsing, `File::Temp` cleanup, and
list-form `system()` that sidesteps the `eval`/quoting problems entirely. Until
then, the two targeted fixes above capture most of the benefit at a fraction of
the cost.

# LaTeX and pipeline improvements

## Make the filter own its package dependencies

The `\multirow` failure is the visible symptom of a wider pattern: the Lua filter
emits raw LaTeX that needs packages, but leaves loading them to the brand's
`header-includes` or to template `$if$` guards. Charts are the next instance -
they emit `% Requires: \usepackage{pgf-pie}` / `pgfplots` as comments only
(`document-filters.lua:589-591`) and rely on every brand remembering to load
`pgf-pie`, `pgfplots`, and `tikz`. `brand-plain.yaml` does; a brand that forgets
will fail exactly as `\multirow` did.

::: recommendation
Have the filter inject every package each construct needs, the way it now does
for `multirow`: table packages when a datatable is present, `pgf-pie` /
`pgfplots` / `tikz` when a chart is present. Treat the `% Requires:` comments as
a to-do list, not documentation.
:::

## Consolidate the templates

There are three near-duplicate full templates - `eisvogel.latex` (1031 lines),
`report.latex` (1099), and `eisvogel-reorganized.latex` (1527, the default) -
plus a `template-multi-file/` split copy. That is a lot of overlapping LaTeX to
keep in sync, and the "reorganized" and "multi-file" variants suggest an existing
effort to tame Eisvogel's monolith.

Pick one canonical template (the reorganized one, since the active brand already
uses it), archive the others under a clearly named directory, and document which
brands use which. Fewer than half the brands likely need anything the others
provide.

## Decouple table-package loading from `$if(tables)$`

Because the native-table guard `$if(tables)$` is false for documents that use
only datatables, the template's `longtable`/`booktabs`/`array` block is skipped
entirely; today this is masked only because `brand-plain.yaml` loads those
packages itself in `header-includes`. That coupling is invisible and brittle.
Loading table packages from the filter (per the recommendation above) removes the
dependency on a template guard that does not apply to our table model.

## Smaller items

Escape chart labels
: Datatable cells are sanitised for LaTeX specials, but confirm chart labels and
  values are too - an `&`, `%`, or `_` in a label would otherwise break the build.

Table rule weight
: `\arrayrulewidth` is set to `1mm` (`brand-plain.yaml:160`), which is a heavy
  rule. Consider lighter, booktabs-style rules for a more typographic result.
  Aesthetic, not a bug.

Font availability
: `mainfont: "Open Sans"` assumes the font is installed; a missing font fails the
  build with an opaque error. A pre-flight check, or a documented font dependency
  list, would help.

# Toolchain and deployment

## Missing install step

`md-to-pdf.sh` reads templates and brands from `~/.pandoc/templates` and
`~/.pandoc/brands` (`md-to-pdf.sh:15-16`), but the repository is the source of
truth and `~/.pandoc` is not populated by anything in the repo. There is no
deploy step, so a fresh checkout cannot build until the user copies files into
place by hand.

::: recommendation
Add a small `scripts/deploy.sh` (or `make install`) that syncs
`pandoc/templates` and `pandoc/brands` into `~/.pandoc`, and document it as the
first step after checkout. This also makes the filter and template edits in this
review actually take effect for the installed pipeline.
:::

## LaTeX package dependencies

The `plain` brand needs these TeX Live packages beyond Pandoc and xelatex. They
were missing on this machine and have been requested:

`texlive-fonts-extra`
: Provides `fontawesome5`, `sourcesanspro`, and `sourcecodepro` - the brand's
  icon set and fonts. This was the only outstanding package at the time of
  writing.

Already present
: KOMA-Script (`scrbook`), `pgfplots`, `pgf-pie`, `markdown.sty`, `multirow`,
  `tabularx`, `longtable`, and the rest of the table stack.

Document the full LaTeX dependency list in the project README so a new machine
can be provisioned in one step.

# Authoring skills (created and installed)

The house Markdown format is documented thoroughly in
`pandoc/documentation/`, but documentation only helps if it is in front of the
author at the moment of writing. The format is now packaged as a Skill so Claude
applies it automatically.

Claude Code skill
: Installed to `~/.claude/skills/pandoc-markdown/`. It loads automatically when a
  task involves writing Markdown for this pipeline, and can also drive
  `md-to-pdf.sh`. Source lives in `pandoc/skills/claude-code/pandoc-markdown/`.

claude.ai skill
: A self-contained variant in `pandoc/skills/claude-ai/pandoc-markdown/`, packaged
  as `pandoc-markdown.zip` for upload through the claude.ai Skills settings. It
  assumes the user compiles the result themselves.

Both share one rule set (front matter, definition lists over bold labels,
en-dashes, British English, the `:::` boxes, datatables, charts, footnote
citations) with a concise `SKILL.md` and a deeper `REFERENCE.md`. See
`pandoc/skills/README.md` for install and upload instructions.

# Non-functional review

Test coverage
: There are example documents and ad-hoc experiments, but no automated tests. The
  pure-logic parts - filename generation, brand merge, datatable parsing - are
  testable and would be the first candidates, especially ahead of any Perl port.

Code quality
: The Bash is well organised and readable. The main blemishes are the hand-rolled
  YAML parsing and the `eval` in the Pandoc call, both noted above. The Lua filter
  is clear and well commented.

Performance
: Not a concern at document scale. The repeated per-field `awk` passes are
  wasteful but negligible against the LaTeX run.

Security
: `download_url` fetches an arbitrary URL and feeds it to LaTeX; for untrusted
  input this is a mild trust boundary. xelatex runs without shell-escape by
  default, which is correct. The `eval` in `run_pandoc` is a quoting risk more
  than a security one. No secrets handled.

Documentation
: A strength. The authoring guide and formatting reference are excellent. The
  gaps are operational: no install/deploy doc and no consolidated LaTeX
  dependency list - both recommended above.

# Priorities

1. Add the install/deploy step so repository edits reach the running pipeline (and the `\multirow` fix takes effect for the user).
2. Make the Lua filter inject the packages charts need, closing the same class of bug the `\multirow` fix addressed.
3. Replace the hand-rolled YAML parsing in `md-to-pdf.sh`, and drop the `eval` in the Pandoc invocation.
4. Consolidate the three templates to one; archive the rest.
5. Add automated tests for the pure-logic functions, then revisit the Perl port question against the triggers listed above.
