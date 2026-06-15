# pandoc-wrapper

**Applies:** rules/bash.md, rules/tests.md, rules/git.md, rules/nonfunctional-close.md

A Markdown-to-PDF publishing pipeline. Authors write Markdown with YAML
front matter; `md-to-pdf.sh` merges in a brand configuration and runs
Pandoc with a Lua filter and a LaTeX (Eisvogel-derived) template to
produce a styled PDF.

## Layout

```
README.md                        repo front door (genesis, use cases, map)
RECOMMENDATIONS.md               outstanding/forward-looking work
md-to-pdf.sh                     driver script (Bash)
man/md-to-pdf.1                  man page
scripts/
├── extract-frontmatter.pl       YAML::XS front-matter reader
├── install.sh                   user/system installer
├── conformance.sh               render the fixture through each document template
├── build-bg-guides.sh           background safe-area mask PDFs (dist/bg-guides/)
└── build-deb.sh                 builds the .deb (dpkg-deb, no root)
tools/make-sbom.pl               regenerates sbom.json from tools/sbom-config.json
tools/bg-guides/                 TikZ sources for the background safe-area guides
sbom.json                        CycloneDX 1.6 SBOM (regenerate after changing what ships)
VERSION                          single source of truth for the version
scripts/bump-version.sh          bump VERSION + stamp SCRIPT_VERSION/man page
pandoc/
├── templates/
│   ├── document-filters.lua     boxes, datatables, charts -> raw LaTeX
│   ├── slides.lua               slide splitter for the modern slides format
│   ├── eisvogel-wrapper.latex   default template (pristine Eisvogel + inserts)
│   ├── mvp.latex                standalone minimal template
│   ├── letter.latex             letter format (window envelope, refs, letterhead)
│   ├── beamer.latex             slides (stock beamer + brand-colour wiring)
│   ├── slides.latex             modern slides (full-bleed xelatex + eso-pic)
│   ├── featured.latex           report with a designed graphical cover (TikZ)
│   ├── pipeline-preamble.tex    portable shim (filter's package deps)
│   ├── conformance-test.md      fixture a template must render
│   └── vendor/                  pristine upstream Eisvogel (provenance)
├── brands/plain/                the only bundled brand (default + copy-me ref)
│                                (org brands live in a separate repo - see below)
├── skills/                      the pandoc-markdown skill (claude.ai + Claude Code)
└── documentation/               authoring guide, template contract, filter README
```

**Versioning:** `VERSION` is the single source of truth; `bump-version.sh`
stamps it into `SCRIPT_VERSION` (md-to-pdf.sh) and the man page `.TH`, and the
SBOM reads it directly. `build-deb.sh` bumps the **patch** per deb by default
(`--no-bump` to build the current version unchanged, or pass `X.Y.Z`).

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

## Template layering (see documentation/TEMPLATE-CONTRACT.md)

Three layers: a swappable **base template** (look only); the portable
**`pipeline-preamble.tex`** shim (every package the Lua filter's output
needs - tables, boxes, charts); and **brand** YAML (now slimmed to
colours, fonts, and heading colours only - the ~20 boilerplate
header-includes lines moved into the preamble/wrapper).

Active templates (`template:` selects by name):

- `eisvogel-wrapper.latex` - the default for all brands. Pristine Eisvogel
  3.4.0 (`vendor/eisvogel-3.4.0.latex`) plus several `pandoc-wrapper` marked
  inserts (each fenced `%% >>> pandoc-wrapper ... %% <<< pandoc-wrapper` or a
  one-line marked comment): the `\input{pipeline-preamble}`, the shared
  Eisvogel-look overrides, the duplex page-parity helpers, the roman/arabic
  front-to-main numbering transition, and the back cover. Upgrade Eisvogel by
  re-vendoring and re-applying every marked insert (grep `pandoc-wrapper`).
  Front matter is roman, body arabic-from-1; `backpage:` renders a back cover;
  `classoption: twoside` is duplex-aware (even page count, back cover on a
  verso, outer-edge `marginbox`). Known edge case: with a back cover **and**
  content that ends on a recto, the cover still lands on a verso and the total
  is still even, but two blank pages can precede it (a scrbook `openright`
  interaction; KOMA's own `\cleardoubleevenpage` does the same).
- `mvp.latex` - standalone minimal template (pandoc default + the preamble).
- `letter.latex` - letter format (pandoc default + preamble, forced to
  `scrartcl`). No title page; recipient address positioned for a DL window
  envelope; date + `our-ref`/`your-ref` on the right; optional `subject`,
  `opening`, `closing`, `signature`. Letterhead via a full-page `letterhead:`
  background, or built from `letterhead-logo`/`letterhead-company`/
  `letterhead-contact`. It neutralises chapter/frontmatter so a report-oriented
  brand (scrbook, chapter division) still renders without error.
- `beamer.latex` - slides. Pandoc's stock beamer template, forced to the
  `beamer` class, plus brand-colour wiring (`beamer-structure`/`beamer-accent`
  brand-colour names map onto the beamer palette) and no-op KOMA/frontmatter
  shims so a report brand merges cleanly. The document keeps full control of the
  beamer theme/colortheme/header-includes (these override the brand mapping).
  Selecting `template: beamer` switches the driver to the **beamer writer**
  (`-t beamer`) and drops chapter division.
- `slides.latex` - the modern (non-beamer) slides format. An `article`-based
  full-bleed deck in pure xelatex: eso-pic single-pass backgrounds (no TikZ
  `remember picture`/`overlay`, which need two passes), bold sans type, a
  title/section/content slide model, per-slide colour roles, and auto-boxed
  images (white rounded card). Ground colours default from the brand's
  `beamer-structure`/`beamer-accent` (override per deck with `slide-title-bg`/
  `slide-accent`). It reads `brand-colours` straight from metadata, so it does
  **not** use `document-filters.lua`; selecting `template: slides` swaps the
  content filter to **`slides.lua`** (the slide splitter: H1→`\SectionSlide`,
  H2→`\BeginSlide[role]`, columns→minipages, standalone images→`\slidecard`).
  Stays on the **pdf writer** (it is article-based, not beamer) but drops
  chapter division.

- `featured.latex` - a report with a designed graphical cover. Pandoc default +
  `pipeline-preamble` (so the full body feature set works) + an original TikZ
  cover: a half-height brand-colour band (lower 56mm), logo, title/subtitle, a
  metadata block, a "Document overview" panel, an optional `classification` chip,
  and an optional `cover-image` placed at its natural shape under the title (no
  crop/circle, clear of the band). Plus brand-coloured ragged-right headings, a
  styled blockquote, and a page X-of-Y footer (uses `\pageref*` so the total is
  not a coloured link). All cover colours come from the brand
  (`titlepage-color`/`-text-color`/`-rule-color` resolved to hex + `beamer-accent`
  as a name); override with `cover-color`/`cover-text-color`/`cover-accent`. Also
  supports `watermark` (diagonal text, content pages only, via `background`) and
  `page-background` (full-page image behind every page, via eso-pic). Forced to
  **scrartcl** (sections, not chapters; chapter mapped onto section like the
  letter template), so it stays on the pdf writer with `document-filters.lua` and
  needs **no driver change**. Ported from a hand-crafted PSTricks template (cover
  re-implemented in TikZ; no PSTricks dependency). Cover zones are hand-measured;
  if you change the cover layout, update `tools/bg-guides/featured.tex`. Best for
  proposals/briefings, not long books. (16-bit PNGs silently fail in xelatex -
  cover/background images must be 8-bit.)

A document's `template:` overrides the brand default, so the letter, slides (and
any alternative format) are selectable per document. The driver saves the
document's `template`/`engine` across the brand merge for this
(`load_brand_config` then re-extract in `main`). `template: beamer` also sets
`P_WRITER=beamer`; `template: slides` sets `P_LUA_FILTER=slides.lua` (writer
stays `pdf`).

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

Beyond pandoc + xelatex: `texlive-fonts-extra` (fontawesome5, source
fonts), `texlive-latex-recommended` (KOMA-Script), `texlive-latex-extra`
(tcolorbox, multirow, pgf-pie), `texlive-pictures` (pgf/pgfplots), and
`libyaml-libyaml-perl`. The full set is encoded in the `.deb` Depends
(see `scripts/build-deb.sh`). Flag missing ones - no sudo here.

## Gotchas

- Datatable rowspans emit `\multirow`; the filter now injects
  `\usepackage{multirow}` into `header-includes` so this no longer
  fails with "Undefined control sequence \multirow" (exit code 43).
- `LC_ALL=C` is set globally in the script; mind locale-sensitive sorts.
- Build artifacts go to `dist/` (gitignored); scratch to `tmp/`.
