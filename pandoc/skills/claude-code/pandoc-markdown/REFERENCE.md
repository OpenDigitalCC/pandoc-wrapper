# pandoc-markdown — extended reference

`SKILL.md` covers the rules you need for almost every document. This file is the
deeper lookup for less-common front-matter and layout options. The fully worked,
rendered-example versions live in the project guides:

- `pandoc/documentation/Markdown-authoring-guide.md` — narrated guide with source + rendered output for every element
- `pandoc/documentation/TEMPLATE-CONTRACT.md` — what a template must provide (for template authors)
- `pandoc/brands/plain/template.yaml` — the commented default brand, the reference for brand fields

## Front-matter options beyond title/subtitle/brand

These are set per-document only when needed; the brand supplies sensible defaults.

`type`
: Document type label, used in the generated filename and sometimes the title page.

`date`
: Overrides the build date (otherwise today's date is used).

`toc`, `toc-depth`
: Table of contents on/off and depth.

`top-level-division`
: `chapter` (most brands) makes `#` a chapter; `section` makes `#` a section.

`minitoc`, `minitoc-depth`
: Per-chapter mini tables of contents. Add `\minitoc` on its own line right
  after a chapter heading to emit one for that chapter.

`titlepage`, `titlepage-color`, `titlepage-text-color`
: Built-in title page and its colours. Use hex or a brand-colour name.

`cover-pdf`
: Use a pre-designed PDF as the cover instead of the generated title page
  (set `titlepage: false`).

`backpage`, `backpage-text`, `backpage-publisher`, `backpage-website`,
`backpage-logo`, `backpage-color`, `backpage-text-color`
: Optional full-page back cover (defaults to the brand's title-page colour). In
  twoside it is always placed on a verso (the back of the last sheet).

`classoption: [oneside|twoside]`
: Single- vs double-sided. Reports number the front matter in roman (i, ii) and
  restart at arabic 1 on the first content page. `twoside` is duplex-aware: even
  page count, back cover on a verso, and `:::marginbox` notes on the outer edge
  (swapping left/right by page side).

`header-left/center/right`, `footer-left/center/right`
: Override running heads/feet. `""` suppresses a position; omitting the field
  keeps the brand default.

`code-accent-color`, `code-background-color`
: Style the code-block panel — the left rule/keyword colour and the fill. Hex or
  a brand-colour name; the brand supplies defaults. Fenced code is line-numbered
  by default (numbers sit in the margin, outside the copy text); opt a block out
  with the `.nonumber` class, e.g. ` ```{.python .nonumber} `.

## Slides (`template: slides`) front matter

The modern slide deck. Colours default from the brand; fonts and typography are
overridable per deck or in the brand.

`slide-title-bg`, `slide-accent`, `slide-bar`
: Title/section ground, accent colour, and top chrome-bar colour (brand-colour
  names). Per-slide role via an H2 attribute: `{.light}` (default), `{.dark}`,
  `{.accent}`.

`slide-logo`, `slide-logo-bar`, `slide-logo-text`
: Cover and content-bar logo images; or a text wordmark when no image is set
  (the wordmark uses `slide-title-font`).

`slide-display-font`, `slide-headline-font`, `slide-title-font`
: Three display roles, each defaulting to the one before it (ultimately Noto
  Serif Display): big stat/tier figures, `##` content headlines, and the title
  slide + `#` dividers + wordmark respectively. Pick a readable sans for
  `slide-headline-font` (e.g. `Inter Display`) and a brand/logo face for
  `slide-title-font` (e.g. `Audiowide`) while figures keep the serif. A
  non-default font must be available where the deck is built — either installed
  system-wide, or simply dropped into the brand folder (any `.ttf`/`.otf`/`.ttc`
  there is auto-registered for the render, like the logo assets). If it cannot be
  found, xelatex substitutes and the deck still builds. A single-weight face (no
  bold) is fine.

`slide-headline-size`, `slide-linespread`, `slide-parskip`, `slide-card-justify`
: Headline point size (default 27), body line spacing, paragraph gap, and
  whether card text is justified (default ragged-left).

## Special boxes — full list

| Box | Purpose | Auto-decoration |
|---|---|---|
| `widebox` | Thesis statement / key conclusion | Full-width coloured border |
| `examplebox` | Case study / evidence | Book icon |
| `marginbox` | Short quote / highlight | Placed in outer margin |
| `textbox` | Aside beside prose | 60% width, text flows alongside |
| `recommendation` | Formal recommendation | Auto-numbered "Recommendation N:" |
| `box-policysummary` | Policy mechanism summary | Scales icon + heading |
| `budgetbox` | Cost / budget proposal | Euro icon + heading |

The `recommendation` counter increments across the whole document.

## Datatable options — full semantics

`columns`
: Pipe-separated header labels. Omit the option entirely for a headerless table.

`widths`
: Pipe-separated. `X` = flexible (shares leftover space equally); `Ncm` = fixed.
  Omit to share all columns equally.

`bold`
: Comma-separated 1-based column numbers to embolden (e.g. `bold: 1, 2`).

`tone`
: Header/stripe intensity: `grey` (neutral), `light`, `medium` (default),
  `strong`, or a number like `40` for a custom percentage.

`caption`
: Caption rendered above the table.

Row spans: a blank leading cell continues the cell above in that column. This
emits `\multirow`; the pipeline loads the package automatically.

## Chart options

Blocks: `piechart`, `barchart`. Data lines are `Label: Value`.

`caption`
: Caption above the chart.

`style`
: `full` (text width, default), `medium` (~half width, centred), `margin`
  (outer margin, for small supporting data).

`axis`
: Bar charts only: `H` (horizontal, best for labels) or `V` (vertical).

`prefix` / `postfix`
: Symbol before / after each value. Use `\%` (with the backslash) for a percent sign.

## Images

Full text width by default; add `{ width=50% }` after the image for a different
size. `![Caption](path/to/image.png){ width=50% }`.

## Long code lines (paste-friendly wrapping)

The pipeline wraps over-long code lines so they never overflow the page, and the
line numbers and the wrap itself are excluded from the PDF's text layer (so they
are not copied). But a *visual* wrap is still a line break when the reader copies
the block — a long command or path pastes split across two lines and won't run.
The only fix is to hand-wrap the line in the source, so you control where the
break lands and it stays paste-runnable.

When a code line would exceed the template's content width, break it yourself
with the language's own line-continuation and keep each physical line within the
budget below:

- Shell: trailing `\`, continuation indented two spaces.
- Python and most C-likes: break inside the brackets/parens that are already open,
  or a trailing `\`.

Budgets are monospace characters per line, for the default brand margins:

| Template | Content width | Aim for | Hard limit |
|---|---|---|---|
| `eisvogel-wrapper` (report) | ~14 cm | **≤ 50** | ~61 |
| `mvp` | ~14 cm | **≤ 50** | ~56 |
| `featured` (widest) | ~16 cm | **≤ 60** | ~65 |
| `letter` | ~16 cm | **≤ 60** | ~65 |

The report is narrow because the default brand reserves a 5 cm right margin for
margin notes; a brand with wider or narrower margins shifts the budget, so treat
these as guidance, not exact. When unsure, target ~50 — it is safe everywhere.

Example (shell, report budget):

````markdown
```bash
DISPATCH=/usr/lib/xi-toolchain/build/\
  cross_platform_build_scripts/dispatch.sh
```
````
