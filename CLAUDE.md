# pandoc-wrapper

**Applies:** rules/bash.md, rules/tests.md, rules/git.md, rules/nonfunctional-close.md

A Markdown-to-PDF publishing pipeline. Authors write Markdown with YAML
front matter; `md-to-pdf.sh` merges in a brand configuration and runs
Pandoc with a Lua filter and a LaTeX (Eisvogel-derived) template to
produce a styled PDF.

## Layout

```
md-to-pdf.sh                     driver script (Bash)
pandoc/
├── templates/
│   ├── document-filters.lua     boxes, datatables, charts -> raw LaTeX
│   ├── eisvogel-reorganized.latex   default template (brand: plain)
│   ├── report.latex / eisvogel.latex  alternative templates
│   └── examples/                upstream Eisvogel example docs (reference)
├── brands/brand-*.yaml          per-brand colour/typography/layout config
├── documentation/              authoring guides + REF-* reference docs
└── experiments/                ad-hoc test documents (PDF outputs gitignored)
```

## Deployment model

`scripts/install.sh` installs the pipeline FHS-style under a prefix
(`~/.local` per-user by default, `/usr/local` with `--system`):
`bin/md-to-pdf`, `lib/md-to-pdf/extract-frontmatter.pl`,
`share/pandoc-wrapper/{templates,brands}`. The driver locates its assets
relative to itself (`../share/pandoc-wrapper`), then falls back to the
legacy `~/.pandoc`, and honours `MD_TO_PDF_TEMPLATES`/`MD_TO_PDF_BRANDS`
overrides. The repo is the source of truth.

## Template layering (see TEMPLATE-CONTRACT.md, MATURATION.md)

Three layers: a swappable **base template** (look only); the portable
**`pipeline-preamble.tex`** shim (every package the Lua filter's output
needs - tables, boxes, charts); and **brand** YAML (now slimmed to
colours, fonts, and heading colours only - the ~20 boilerplate
header-includes lines moved into the preamble/wrapper).

Active templates (`template:` selects by name):

- `eisvogel-wrapper.latex` - the default for all brands. Pristine Eisvogel
  3.4.0 (`vendor/eisvogel-3.4.0.latex`) plus two marked inserts: an
  `\input{pipeline-preamble}` and the shared Eisvogel-look overrides.
  Upgrade Eisvogel by re-vendoring and re-applying the two inserts.
- `mvp.latex` - standalone minimal template (pandoc default + the preamble).
- `eisvogel.beamer` - slides (not yet wired into the pipeline preamble).

`conformance-test.md` is the fixture a template must render to be
compatible. The driver puts the templates dir on `TEXINPUTS` so templates
can `\input{pipeline-preamble}`. Superseded forks live under
`templates/Archive/superseded-2026-06/`.

## How a build flows

1. `collect_source_files` gathers `.md`/`.yaml` inputs (or downloads a URL).
2. `extract_metadata` reads front matter (title, brand, template, engine).
3. If `brand:` is set, the brand YAML is prepended so document fields override brand defaults.
4. `document-filters.lua` turns `:::` boxes, ```` ```datatable ````, and chart blocks into raw LaTeX, and injects brand colours + required packages into `header-includes`.
5. Pandoc renders to PDF via `xelatex` (default engine) and the template.

## Toolchain dependencies (LaTeX)

Beyond pandoc + xelatex, the `plain` brand needs these TeX Live packages:
`texlive-fonts-extra` (fontawesome5, sourcesanspro, sourcecodepro),
KOMA-Script (scrbook), pgfplots, pgf-pie, markdown.sty. Flag missing
ones to the user - no sudo here.

## Gotchas

- Datatable rowspans emit `\multirow`; the filter now injects
  `\usepackage{multirow}` into `header-includes` so this no longer
  fails with "Undefined control sequence \multirow" (exit code 43).
- `LC_ALL=C` is set globally in the script; mind locale-sensitive sorts.
- Generated PDFs under `experiments/` are gitignored.
