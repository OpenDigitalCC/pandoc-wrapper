# pandoc-markdown — extended reference (standalone)

`SKILL.md` covers the rules you need for almost every document. This file is the
deeper lookup for less-common front-matter and layout options. It is
self-contained so it works without access to the pipeline repository.

## Front-matter options beyond title/subtitle/brand

These are set per-document only when needed; the brand supplies sensible defaults.

`type`
: Document type label, used in the generated filename and sometimes the title page.

`date`
: Overrides the build date (otherwise the build date is used).

`toc`, `toc-depth`
: Table of contents on/off and depth.

`top-level-division`
: `chapter` (most brands) makes `#` a chapter; `section` makes `#` a section.

`minitoc`, `minitoc-depth`
: Per-chapter mini tables of contents. Add `\minitoc` on its own line right
  after a chapter heading to emit one for that chapter.

`titlepage`, `titlepage-color`, `titlepage-text-color`
: Built-in title page and its colours. Use a hex value or a brand-colour name.

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

Row spans: a blank leading cell continues the cell above in that column. The
pipeline renders this with `\multirow` and loads the package automatically, so
row spans are safe to use.

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
size: `![Caption](path/to/image.png){ width=50% }`.

## Worked skeleton

```markdown
---
title: "Reserves and Sustainability Review"
subtitle: "Board briefing"
brand: plain
---

# Summary

Opening paragraph in prose.

::: widebox
The organisation holds under two months of operating reserves against a policy
target of six.
:::

## Findings

Reserve position
: Current reserves cover 1.8 months of operating expenditure.

Income concentration
: 62% of income derives from a single grant.

```datatable
columns: Risk | Likelihood | Impact | Mitigation
widths: X | 2.5cm | 2.5cm | X
bold: 1
---
Grant non-renewal | Medium | Critical | Diversify income; build 6-month reserve.
Cost inflation | High | Medium | Index core contracts; review quarterly.
```

::: recommendation
Establish a formal reserves policy targeting six months of operating expenses,
reviewed annually by the board.
:::

# References
```
```
