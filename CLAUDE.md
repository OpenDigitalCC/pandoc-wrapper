# pandoc-wrapper

**Applies:** rules/bash.md, rules/tests.md, rules/git.md, rules/nonfunctional-close.md

A Markdown-to-PDF publishing pipeline. Authors write Markdown with YAML
front matter; `md-to-pdf.sh` merges in a brand configuration and runs
Pandoc with a Lua filter and a LaTeX (Eisvogel-derived) template to
produce a styled PDF.

## Layout

```
md-to-pdf.sh                     driver script (Bash)
scripts/
├── extract-frontmatter.pl       YAML::XS front-matter reader
└── install.sh                   user/system installer
pandoc/
├── templates/
│   ├── document-filters.lua     boxes, datatables, charts -> raw LaTeX
│   ├── eisvogel-wrapper.latex   default template (pristine Eisvogel + inserts)
│   ├── mvp.latex                standalone minimal template
│   ├── pipeline-preamble.tex    portable shim (filter's package deps)
│   ├── vendor/                  pristine upstream Eisvogel (provenance)
│   └── Archive/                 superseded forks
├── brands/plain/               the only bundled brand (default + copy-me ref)
│                               (org brands live in a separate repo - see below)
├── documentation/              authoring guides + REF-* + contract/maturation
└── experiments/                ad-hoc test documents (PDF outputs gitignored)
```

## Deployment model

`scripts/install.sh` installs the TOOL FHS-style under a prefix
(`~/.local` per-user by default, `/usr/local` with `--system`):
`bin/md-to-pdf`, `lib/md-to-pdf/extract-frontmatter.pl`,
`share/pandoc-wrapper/templates`. The driver locates templates relative to
itself (`../share/pandoc-wrapper`), falling back to legacy `~/.pandoc`.

**Brands.** Each brand is a folder `<base>/<name>/template.yaml` plus its
assets (logos, cover PDFs). Only `plain` ships in this repo - the default
brand, also the reference to copy for new ones. Organisation brands live
OUTSIDE the repo, managed separately - on this host at
`/srv/projects/pandoc-brands/` (its own git repo).

Resolution (`load_brand_config`): external base first, then bundled
defaults, then legacy flat `brand-<name>.yaml`. The external base is
`MD_TO_PDF_BRANDS` env → `brands_dir` in `~/.config/pandoc-wrapper/config`
→ a co-located/XDG default. Because bundled defaults are the fallback,
`plain` always resolves no matter where `brands_dir` points. The selected
brand's folder is added to `--resource-path` and `TEXINPUTS`, so assets
resolve by bare filename. The installer ships the bundled defaults and
writes the config pointing `brands_dir` at the external base.

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
