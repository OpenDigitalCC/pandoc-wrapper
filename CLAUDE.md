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

The script reads templates and brands from `~/.pandoc/templates` and
`~/.pandoc/brands`, **not** from this repo directly. The repo is the
source of truth; a deploy step (currently manual) copies into
`~/.pandoc`. There is no install script yet - see RECOMMENDATIONS.md.

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
