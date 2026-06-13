# pandoc-markdown — extended reference

`SKILL.md` covers the rules you need for almost every document. This file is the
deeper lookup for less-common front-matter and layout options. The fully worked,
rendered-example versions live in the project guides:

- `pandoc/documentation/Markdown-authoring-guide.md` — narrated guide with source + rendered output for every element
- `pandoc/documentation/claude-markdown-formatting-instructions.md` — the condensed rule set
- `pandoc/documentation/REF-brand-yaml.md`, `REF-template-yaml.md` — brand and template field references

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

`backpage`, `backpage-text`, `backpage-publisher`, `backpage-website`
: Optional back cover.

`classoption: [oneside|twoside]`, `printready: true|false`
: Digital (symmetric, no crop marks) vs print (binding-ready, crop marks, page
  count rounded to a multiple of 4).

`header-left/center/right`, `footer-left/center/right`
: Override running heads/feet. `""` suppresses a position; omitting the field
  keeps the brand default.

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
