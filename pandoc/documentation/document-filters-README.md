# document-filters.lua

Pandoc Lua filter providing charts, styled boxes, and a brand colour system for
PDF document generation via LaTeX. Designed for use with the Eisvogel template
and pandoc's markdown-to-PDF pipeline.

## Overview

A single filter file replacing separate `chart-filter.lua` and `boxes.lua`
files. Provides:

- Pie and bar charts from markdown code blocks
- Styled data tables with coloured headers, row shading, and rowspans
- Styled content boxes (info, example, recommendation, etc.)
- Brand colour system with single-source definitions
- Automatic `\definecolor` generation for LaTeX
- Metadata colour resolution for template fields (titlepage, etc.)

## Installation

Place `document-filters.lua` alongside your document files and invoke with:

```bash
pandoc document.md brand.yaml \
  --lua-filter=document-filters.lua \
  --template=eisvogel \
  --pdf-engine=xelatex \
  -o output.pdf
```

## Brand Colour System

Colours are defined once in the YAML metadata and used everywhere - charts,
boxes, LaTeX commands, and template fields.

### brand-colours

The master colour palette. Each entry becomes a `\definecolor` in LaTeX
automatically, so these names can be used in `\color{}`, `\colorbox{}`,
`\addtokomafont`, tcolorbox options, and anywhere else LaTeX expects a colour
name.

```yaml
brand-colours:
  tprf-blue: "3B7A9E"
  tprf-orange: "E08A52"
  tprf-yellow: "F0D264"
  tprf-green: "4CAF82"
  tprf-maroon: "9A6478"
  tprf-blue-light: "D8EBF2"
  tprf-maroon-light: "EEDBE1"
  tprf-text-dark: "1A1A2E"
```

Values are six-character hex strings without the `#` prefix.

### chart-colours

Ordered list of `brand-colours` names for chart segments. The first entry is
used for the largest segment, and so on in order.

```yaml
chart-colours:
  - tprf-blue
  - tprf-orange
  - tprf-yellow
  - tprf-green
  - tprf-maroon
```

If omitted, a default ten-colour palette is used.

### box-colours

Semantic colour assignments for content boxes. Values are LaTeX colour
expressions and support mixing syntax (e.g. `tprf-green!90`).

```yaml
box-colours:
  frame-info: tprf-green!90
  bg-info: tprf-blue-light!10
  frame-accent: tprf-blue!90
  bg-accent: tprf-blue-light!10
  frame-highlight: tprf-blue!90
  bg-highlight: tprf-blue-light!10
  frame-contrast: tprf-maroon!90
  bg-contrast: tprf-maroon-light!10
```

If omitted, a default palette of general-purpose colours is used.

The semantic names map to box types as follows:

frame-info / bg-info
: textbox

frame-accent / bg-accent
: recommendation, examplebox

frame-accent / bg-contrast
: box-policysummary

frame-contrast / bg-info
: budgetbox

frame-highlight / bg-highlight
: widebox

frame-contrast
: marginbox (frame only, no background fill)

### Template colour fields

Metadata fields that expect hex colour values can reference `brand-colours`
names instead of raw hex. The filter resolves them before the template
processes them.

```yaml
titlepage-color: tprf-blue
titlepage-text-color: white
titlepage-rule-color: tprf-orange
```

Supported fields:

- `titlepage-color`
- `titlepage-text-color`
- `titlepage-rule-color`
- `page-background-color`
- `header-color`
- `footer-color`

Convenience aliases `white` and `black` are also supported. Raw hex values
still work for any field.

## Charts

Charts are defined as fenced code blocks with class `piechart` or `barchart`.

### Pie chart

````markdown
```piechart
colours: tprf-blue, tprf-orange, tprf-yellow
caption: Total Expense: $233,739.75
style: full
postfix: \%
Program Expenses: 92
Administration Expenses: 4
Fundraising Expenses: 4
```
````

### Bar chart

````markdown
```barchart
caption: Spending by programme area (USD)
axis: H
style: full
prefix: $
Perl Core Maintenance: 95239
Raku Core Development: 28374
Events: 28291
```
````

### Chart options

style
: Layout mode. `full` (default), `medium`, or `margin`.

caption
: Figure caption text. LaTeX special characters are escaped automatically.

axis
: Bar chart direction. `H` for horizontal (default), `V` for vertical.

prefix
: Text before each value (e.g. `$`). Escaped for LaTeX.

postfix
: Text after each value (e.g. `\%`). Escaped for LaTeX.

colours
: Comma-separated list of `brand-colours` names to override chart-colours
  order for this chart. Optional; if omitted, uses the `chart-colours` palette
  in order.

### Chart styles

full
: Left-aligned, full text width. Pie radius 4, bar chart fills `\textwidth`.
  Uses `\captionof{figure}` for numbered captions. Best for standalone charts.

medium
: Centred minipage at 55% text width. Scaled to 0.8. Uses `\captionof{figure}`
  for numbered captions. Good for inline charts that don't need full width.

margin
: Placed in the page margin via `\marginnote`. Scaled to fit `\marginparwidth`
  using `\resizebox`. Pie charts show values inside segments with no legend.
  Caption is plain `\scriptsize` text without figure numbering. Good for
  supporting data alongside prose.

All styles use `\Needspace` to prevent page breaks splitting the chart from
its caption.

### Data format

Each data line is `Label: Value` where value is a number. Labels can contain
most characters; parentheses, currency symbols, and commas are automatically
escaped or converted for LaTeX safety.

Lines matching `key: non-numeric-value` are treated as options. Lines matching
`Label: 42` or `Label: 42.5` are treated as data entries.

## Boxes

Content boxes are defined as pandoc Div elements using the fenced div syntax.

### Box types

#### textbox

Wrapped to the right of the page at 60% width using `\wrapfigure`. Text flows
alongside. Uses `frame-info` / `bg-info` colours.

```markdown
::: textbox
Important information that sits alongside the main text.
:::
```

#### widebox

Full text width with rounded corners and a visible border. Uses
`frame-highlight` / `bg-highlight` colours.

```markdown
::: widebox
A key statement spanning the full width.
:::
```

#### examplebox

Full width with left border rule. Uses `frame-accent` / `bg-accent` colours.
Prefixed with a book icon (`\faBookOpen`).

```markdown
::: examplebox
**Netherlands**: Ministry of Health mandating AGPL licensing.
:::
```

#### recommendation

Full width with left border rule and auto-numbered heading. Uses
`frame-accent` / `bg-accent` colours. Counter increments across the document.

```markdown
::: recommendation
Establish a formal reserves policy targeting six months of operating expenses.
:::
```

#### box-policysummary

Full width with left border rule. Uses `frame-accent` / `bg-contrast` colours.
Prefixed with a scales icon (`\faBalanceScale`).

```markdown
::: box-policysummary
Summary of the policy concept and its implications.
:::
```

#### budgetbox

Full width with left border rule. Uses `frame-contrast` / `bg-info` colours.
Prefixed with a euro icon (`\faEuroSign`).

```markdown
::: budgetbox
Proposed budget allocation for the initiative.
:::
```

#### marginbox

Placed in the page margin via `\marginnote`. Uses `frame-contrast` for the
border. Automatically adjusts border position (left rule on odd pages, right
rule on even pages) via `\checkoddpage`.

```markdown
::: marginbox
"Quote or key point"

**Attribution**
:::
```

### Box vertical spacing

All boxes use `\Needspace` to prevent page breaks splitting the box. The
required space is calculated from character count, characters per line for the
box type, and a line height estimate.

### Markdown inside boxes

Box content is full pandoc markdown - bold, links, lists, definition lists, and
other formatting all work. The content is converted to LaTeX by pandoc before
being placed inside the tcolorbox environment.

## Data Tables

Styled tables are defined as fenced code blocks with class `datatable`. The
filter generates `longtable` output with coloured headers, alternating row
shading, and optional rowspans. Tables span pages automatically with repeated
headers.

### Basic table

````markdown
```datatable
columns: Phase | Actions | Deliverable
widths: 2.5cm | X | 4.5cm
bold: 1
tone: medium
---
Requirements | Define product context and top risks. | 1-page **Security Context & Assumptions**.
Design | Maintain architecture diagram with **trust boundaries**. | **Architecture + trust-boundary diagram**.
Development | Build secure defaults; enforce dependency hygiene. | CI evidence + **Secure coding checklist**.
```
````

### Table with rowspans

A blank leading cell continues the cell above. The filter emits `\multirow`
for the spanning cell and empty cells for continuation rows.

````markdown
```datatable
columns: Principle | Requirement | Implementation support
widths: 3cm | 3.5cm | X
bold: 1, 2
tone: medium
---
Trust boundaries | ANNEX-1.PT1.1 | Supports identification of cybersecurity risks.
 | ANNEX-1.PT1.2.d | Supports protection from unauthorised access.
 | ANNEX-1.PT1.2.e | Supports confidentiality protections.
Least privilege | ANNEX-1.PT1.2.d | Supports access limitation.
 | ANNEX-1.PT1.2.f | Supports integrity protection.
```
````

In the output, "Trust boundaries" spans three rows and "Least privilege" spans
two rows in the first column.

### Row groups (one shaded band)

A leading cell of `+` joins a row to the shading group above, so several rows
read as a single shaded block instead of alternating stripes. The shading
stripe then advances per group, not per row. Unlike a rowspan (blank leading
cell) the cells are *not* merged - each row keeps its own cells; only the
background is shared. The `+` itself is rendered blank.

````markdown
```datatable
columns: Phase | Step | Note
tone: medium
---
Discovery | Interviews and audit | weeks 1-2
+ | Baseline metrics | week 3
+ | Findings workshop | week 4
Delivery | Build and test | weeks 5-8
+ | Handover | week 9
```
````

Here "Discovery" is one shaded band of three rows and "Delivery" the next band
(unshaded) of two. Blank-cell rowspans and `+` groups are independent and can be
combined - a `+` row may still carry blank cells in other columns to continue a
rowspan there.

### Column spans

A cell of `>` merges leftward into its neighbour, so one cell can span several
columns (rendered with `\multicolumn`). Use it for a full-width banner row, a
group header, or a totals label that runs across the lead columns. The merged
cell's width is the sum of the columns it covers, so its text still wraps.

````markdown
```datatable
columns: Item | Q1 | Q2
tone: medium
---
Whole-year summary | > | >
Revenue | 100 | 200
Net total over both quarters | > | 300
```
````

"Whole-year summary" spans all three columns; the totals label spans the first
two, leaving its figure in the last. Column spans compose with both rowspans and
`+` row groups.

### Datatable options

Options appear before the `---` separator, one per line.

columns
: Pipe-separated header labels. If omitted, column count is inferred from the
  first data row and no header is shown.

widths
: Pipe-separated column widths. `X` for flexible (shares the remaining space),
  or a fixed width as `Ncm` (e.g. `3.5cm`). If omitted, all columns default to
  `X`. Flexible columns are **auto-sized by how much text each carries**, so a
  prose column beside short label columns is given the room it needs instead of
  an equal slice that wraps every word; columns of similar length still come out
  equal. Override the automatic split with explicit `Ncm` widths (e.g.
  `2.5cm | X | 4.5cm`) or the `text:` weights below. The cheapest fix for a
  squeezed table is usually to do nothing - the auto-sizing already favours the
  prose column - and only reach for `widths:`/`text:` when you want a specific
  proportion.

bold
: Comma-separated column numbers (1-based) to auto-bold. Optional.

text
: Comma-separated prose column numbers (1-based) that should take a heavier
  share of the flexible width, **overriding** the automatic content-based
  sizing for those columns. `text: 2` weights column 2 at x2 relative to the
  other `X` columns; `text: 2*3` at x3. Only affects `X` columns. Optional.

tone
: Colour intensity for the header row and alternating row shading. Named
  values or a bare number.

caption
: Table caption text. Optional. Rendered via `\caption{}` above the table.

textwidth
: Override the assumed text width in cm for X column calculations. Default is
  17 (A4 with 2cm margins). Set to 14 for templates with wide margins.

### Tone values

grey
: Neutral grey header (`black!60`), very light grey alternating rows
  (`black!4`). No brand colour.

light
: Brand accent at 30%, rows at 3%.

medium
: Brand accent at 60%, rows at 5%. This is the default.

strong
: Brand accent at 90%, rows at 8%.

A bare number (e.g. `40`)
: Brand accent at that percentage, rows derived proportionally.

The brand accent colour is the first entry in `chart-colours`. If no
`chart-colours` are defined, the default palette is used.

### Data format

Data rows follow the `---` separator. Cells are pipe-delimited. Blank lines
between rows are ignored.

Markdown `**bold**` in cell text is converted to `\textbf{}`. LaTeX special
characters (`&`, `%`, `#`, `_`, `$`) are escaped automatically.

A blank leading cell (empty text before the first `|`) means "continue the
cell above in this column". Multiple consecutive blank cells in the same
column extend the span. The filter emits `\multirow{N}{*}{content}` for the
first row and empty cells for the continuation rows.

### Data row example with mixed content

```
Testing & acceptance | Run automated security checks (**SAST**/dependency, basic DAST). | **Release security checklist** (pass/fail + exceptions).
```

The `&` in "Testing & acceptance" is escaped to `\&` automatically. The
`**SAST**` and `**Release security checklist**` are converted to `\textbf{}`.

## LaTeX Package Requirements

The following packages must be available. Most are loaded by the Eisvogel
template; the remainder should be in `header-includes`.

Charts require:

- `pgf-pie`
- `pgfplots` (with `\pgfplotsset{compat=1.18}`)
- `needspace`
- `caption`
- `graphicx`
- `marginnote` (for margin style)
- `changepage` (for margin style `\checkoddpage`)

Data tables require:

- `longtable`
- `multirow`
- `array`
- `xcolor` (with `table` option)

Boxes require:

- `tcolorbox` (with `most` library)
- `wrapfig` (for textbox)
- `needspace`
- `fontawesome5` (for box icons)
- `ifoddpage` (for marginbox)
- `marginnote` (for marginbox)

## Backwards Compatibility

The filter accepts several aliases for smooth migration from earlier versions:

- `size:` is accepted as an alias for `style:` in chart code blocks
- `flow` and `flow-mini` are accepted as aliases for `medium`
- The old `chart-colours` list format with `- name:` / `hex:` pairs is not
  supported; use the new `brand-colours` map plus flat `chart-colours` list

## Complete Brand YAML Example

```yaml
---
brand-colours:
  tprf-blue: "3B7A9E"
  tprf-orange: "E08A52"
  tprf-yellow: "F0D264"
  tprf-green: "4CAF82"
  tprf-maroon: "9A6478"
  tprf-blue-light: "D8EBF2"
  tprf-orange-light: "F7E0CF"
  tprf-yellow-light: "FBF2D4"
  tprf-green-light: "D6EDE2"
  tprf-maroon-light: "EEDBE1"
  tprf-text-dark: "1A1A2E"
  tprf-text-mid: "555555"
  tprf-text-light: "FFFFFF"
  onion-1: "40426C"
  onion-2: "6B6C8D"
  onion-3: "7E809C"
  onion-4: "9092AA"
  onion-5: "A5A6BA"
  onion-6: "B5B6C6"
  onion-7: "CBCBD6"

chart-colours:
  - tprf-blue
  - tprf-orange
  - tprf-yellow
  - tprf-green
  - tprf-maroon

box-colours:
  frame-info: tprf-green!90
  bg-info: tprf-blue-light!10
  frame-accent: tprf-blue!90
  bg-accent: tprf-blue-light!10
  frame-highlight: tprf-blue!90
  bg-highlight: tprf-blue-light!10
  frame-contrast: tprf-maroon!90
  bg-contrast: tprf-maroon-light!10

titlepage-color: tprf-blue
titlepage-text-color: white
titlepage-rule-color: tprf-orange

header-includes: |
  \usepackage{pgf-pie}
  \usepackage{pgfplots}
  \pgfplotsset{compat=1.18}
  \usepackage{multirow}
  \addtokomafont{section}{\color{tprf-blue}}
  \addtokomafont{subsection}{\color{tprf-blue}}
  \addtokomafont{chapter}{\color{tprf-text-dark}}
---
```

Note that `header-includes` no longer needs `\definecolor` lines - these are
generated automatically from `brand-colours`. Only structural LaTeX commands
(fonts, spacing, komafont, packages) belong in `header-includes`.
