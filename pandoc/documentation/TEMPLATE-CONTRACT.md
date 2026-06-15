# Template contract

This document defines what a base LaTeX template must deliver to be compatible
with the pandoc-wrapper pipeline. Any template that meets the contract -
Eisvogel, the bundled `mvp.latex`, or a future custom design - can be selected
by a brand (`template:`) or a document (`template:` / `pandoc-template:`) and
will render every pipeline feature.

## The three layers

The pipeline is layered so that templates, the feature set, and brand identity
vary independently:

base template
: Page geometry, title page, headers/footers, table of contents, sectioning.
  Owns *look*, not *features*. Examples: `eisvogel-wrapper.latex` (pristine
  Eisvogel 3.4.0 from `vendor/` plus an `\input{pipeline-preamble}` and the
  shared Eisvogel-look overrides) and the standalone `mvp.latex`. Swappable via
  the brand's or document's `template:` field. A beamer/slides template can be
  added the same way.

pipeline preamble (`pipeline-preamble.tex`)
: The portable "shim". Loads every LaTeX package the Lua filter's output relies
  on (tables, boxes, charts) plus a few generic typographic settings. Contains
  no template-specific or KOMA-specific commands. Shared by all templates and
  all brands; loaded once.

brand (`brand-*.yaml`)
: Identity only - colours, fonts, logo, institute, and any heading-colour or
  layout overrides. Selects a base template by name. Should carry no feature
  packages (those belong to the preamble) and ideally no template-specific
  LaTeX (that couples the brand to one template).

## What a base template MUST do

Honour the header-includes injection point
: The template must emit `header-includes` content in its preamble. This is how
  brand colours (auto-generated `\definecolor` lines from the filter) and any
  per-document preamble reach LaTeX. A pandoc template that drops
  `$for(header-includes)$ $header-includes$ $endfor$` is non-conformant.

Pull in the pipeline preamble
: Either `\input{pipeline-preamble}` in the template preamble (the wrapper puts
  the templates directory on `TEXINPUTS`, so the bare name resolves), or arrange
  for it to be injected via header-includes. `mvp.latex` uses `\input`.

Consume the core pandoc variables
: At minimum: `title`, `subtitle`, `author`, `date`, `documentclass`,
  `toc`/`toc-depth`, `body`. Templates that target the full brand set should also
  honour: `titlepage` and its colours, `header-left/center/right`,
  `footer-left/center/right`, `classoption`, `margin-*`, `mainfont`, `fontsize`,
  and the endnotes variables (`endnotes-heading`, `footnotes-as-endnotes`).

Use a KOMA class for full brand compatibility
: Brands apply heading colours with `\addtokomafont{...}{\color{...}}`, which
  requires a KOMA-Script class (`scrartcl`, `scrbook`). A template that honours
  `documentclass` (brands set `scrbook`/`scrartcl`) satisfies this automatically.
  A non-KOMA template still renders boxes, tables and charts, but brand heading
  colours are silently skipped.

## What the template must NOT need to provide

These are supplied by `pipeline-preamble.tex`; a conformant template does not
load them itself, and the filter's raw LaTeX may assume they are present:

- Tables: `longtable`, `booktabs`, `array`, `multirow`, `tabularx`, `colortbl`, `xcolor` with the `table` option.
- Boxes: `tcolorbox` (the `most` library), `needspace`, `wrapfig`, `fontawesome5`.
- Charts: `pgfplots`, `pgf-pie` (and `\pgfplotsset{compat=1.18}`).

If you move any of these into a template, you re-create the class of failure
that the `\multirow` bug was (a feature works under one template, breaks under
another). Keep them in the preamble.

## Conformance test

A template passes if it compiles `conformance-test.md` (bundled in
`pandoc/templates/`) to PDF and the output contains every element. That fixture
exercises: headings, prose, a definition list, a datatable with a row span,
**every** box type the filter emits (widebox, recommendation, examplebox,
textbox, budgetbox, marginbox), a pie chart, a bar chart, and a footnote
citation - using an inline colour-only brand so the test is template-independent.

Exercising every box matters: each box maps to specific LaTeX the preamble must
support (e.g. `marginbox` -> `\marginnote` + `\checkoddpage`, from the
`marginnote` and `changepage` packages). A box that the fixture omits is a box
whose package dependency is unverified - exactly how a missing package reaches a
user as an "Undefined control sequence" (exit 43) instead of failing here.

The quickest way to run it is the bundled runner, which renders the fixture
through each document template (eisvogel-wrapper, mvp, letter) and exits
non-zero if any fail:

```bash
scripts/conformance.sh
```

To drive a single template by hand:

```bash
cd pandoc/templates
TEXINPUTS="$(pwd):" pandoc \
  --lua-filter=document-filters.lua \
  --template=YOUR-TEMPLATE.latex \
  --pdf-engine=xelatex \
  -f markdown+inline_notes \
  conformance-test.md -o /tmp/conformance.pdf
```

A non-zero exit, or a missing element in the PDF, means the template does not yet
meet the contract. `mvp.latex` is the minimal reference that passes;
`eisvogel-wrapper.latex` is the full-featured reference. Build new templates from
either rather than from scratch.

## Upgrading the vendored Eisvogel

`eisvogel-wrapper.latex` is pristine upstream Eisvogel plus exactly two inserts,
each fenced with `%% >>> pandoc-wrapper` / `%% <<< pandoc-wrapper`: an
`\input{pipeline-preamble}` at the header-includes point, and the shared
Eisvogel-look overrides just before `\begin{document}`. To upgrade: drop the new
release into `vendor/`, copy it to `eisvogel-wrapper.latex`, and re-apply those
two inserts. Keeping the local delta to two clearly-marked blocks is the whole
point of not forking.
