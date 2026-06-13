# REF: Brand YAML Authoring

Reference for creating and editing brand YAML files used with the
`document-filters.lua` Lua filter and `eisvogel-reorganized` template.

## Purpose

A brand YAML file centralises all visual identity settings - colours, typography,
layout, and template fields - so multiple documents can share a consistent style.
Document-level YAML overrides brand defaults.

The `md-to-pdf.sh` script loads a brand file when the document front matter
contains `brand: name`, resolving to `~/.pandoc/brands/brand-name.yaml`.

## File Naming

Files must follow the pattern `brand-{name}.yaml` and live in `~/.pandoc/brands/`.
The `name` portion is what documents reference with `brand: name`.

## Sections

A brand YAML has two kinds of content: filter-specific colour keys consumed by
`document-filters.lua`, and template YAML fields passed through to
`eisvogel-reorganized`. Both live in the same file.

## Colour System

### brand-colours

Master palette. Each entry becomes a `\definecolor` in LaTeX automatically -
no manual `\definecolor` lines needed in `header-includes`.

```yaml
brand-colours:
  my-blue: "3B7A9E"
  my-orange: "E08A52"
  my-blue-light: "D8EBF2"
  my-text-dark: "1A1A2E"
```

Values are six-character hex strings without the `#` prefix. Names can be
any string and are used directly in LaTeX (`\color{my-blue}`, tcolorbox
options, `\addtokomafont`, etc.).

### chart-colours

Ordered list of `brand-colours` names. First entry is used for the first/largest
chart segment, and so on. Cycles if more segments than entries.

```yaml
chart-colours:
  - my-blue
  - my-orange
  - my-blue-light
```

If omitted, a built-in ten-colour palette is used. The first entry also sets
the accent colour for datatable headers.

### box-colours

Semantic colour assignments for content boxes. Values are LaTeX colour
expressions; mixing syntax is supported (`my-blue!90`).

```yaml
box-colours:
  frame-info: my-blue!80
  bg-info: my-blue-light!20
  frame-accent: my-blue!90
  bg-accent: my-blue-light!10
  frame-highlight: my-blue!90
  bg-highlight: my-blue-light!10
  frame-contrast: my-maroon!90
  bg-contrast: my-maroon-light!10
```

Semantic name to box type mapping:

`frame-info` / `bg-info`
: textbox

`frame-accent` / `bg-accent`
: recommendation, examplebox

`frame-accent` / `bg-contrast`
: box-policysummary

`frame-contrast` / `bg-info`
: budgetbox

`frame-highlight` / `bg-highlight`
: widebox

`frame-contrast` (frame only, no background)
: marginbox

If omitted, a built-in default palette using generic LaTeX colour names is used.

### Template colour fields

These fields normally expect raw hex values. The filter resolves `brand-colours`
names so you can use symbolic names instead.

```yaml
titlepage-color: my-blue
titlepage-text-color: white
titlepage-rule-color: my-orange
page-background-color: my-blue
header-color: my-blue
footer-color: my-blue
```

Convenience aliases `white` and `black` are supported. Raw hex still works.

## header-includes

Only structural LaTeX belongs here. Do not add `\definecolor` lines - these
are generated automatically from `brand-colours`.

```yaml
header-includes: |
  \usepackage{fontawesome5}
  \usepackage[default]{sourcesanspro}
  \usepackage{pgf-pie}
  \usepackage{pgfplots}
  \usepackage{wrapfig}
  \addtokomafont{chapter}{\color{my-blue}}
  \addtokomafont{section}{\color{my-blue}}
  \addtokomafont{subsection}{\color{my-steel}}
  \pgfplotsset{compat=1.18}
```

Required packages per feature:

Charts
: `pgf-pie` (pie), `pgfplots` + `\pgfplotsset{compat=1.18}` (bar)

Boxes
: `tcolorbox` (usually loaded by template), `wrapfig` (textbox),
  `fontawesome5` (icons in examplebox, budgetbox, box-policysummary),
  `marginnote` + `ifoddpage` (marginbox)

Datatables
: `longtable`, `multirow`, `array`, `xcolor` with `table` option

## Template Fields in Brand YAML

These are standard `eisvogel-reorganized` fields. See REF-template-yaml.md
for the full field reference.

Common fields to set at brand level:

```yaml
# Identity
institute: "Organisation Name"
subject: "Organisation Documents"

# Engine
template: eisvogel-reorganized
pdf-engine: xelatex
from: markdown-smart

# Document structure defaults
book: true
documentclass: scrbook
top-level-division: chapter

# Typography
mainfont: "Open Sans"
fontsize: 11pt

# Layout
classoption:
  - oneside
margin-left: 2cm
margin-right: 5cm
margin-top: 2cm
margin-bottom: 1.5cm

# TOC
toc: true
toc-depth: 2
numbersections: true
secnumdepth: 2

# Endnotes
footnotes-as-endnotes: true
endnotes-heading: References
endnotes-custom-heading: true
endnotes-symmetric-margins: true

# Styling
colorlinks: true
footnotes-pretty: true
float-placement-figure: H
listings: true
```

## Box Environment Registration

To use boxes in documents, register them in the brand YAML under
`pandoc-latex-environment`. This is consumed by the `pandoc-latex-environment`
pandoc filter (separate from `document-filters.lua`).

```yaml
pandoc-latex-environment:
  marginbox: [marginbox]
  examplebox: [examplebox]
  widebox: [widebox]
  textbox: [textbox]
  recommendation: [recommendation]
  budgetbox: [budgetbox]
  box-policysummary: [box-policysummary]
```

## Complete Minimal Example

```yaml
---
brand-colours:
  my-blue: "2C3E50"
  my-accent: "2980B9"
  my-light: "D6EAF5"
  my-text: "2C3E50"

chart-colours:
  - my-blue
  - my-accent

box-colours:
  frame-info: my-accent!80
  bg-info: my-light!20
  frame-accent: my-blue!90
  bg-accent: my-light!10
  frame-highlight: my-blue!80
  bg-highlight: my-light!10
  frame-contrast: my-blue!60
  bg-contrast: my-light!10

titlepage-color: my-blue
titlepage-text-color: white
titlepage-rule-color: my-accent

template: eisvogel-reorganized
pdf-engine: xelatex
from: markdown-smart
book: true
documentclass: scrbook
top-level-division: chapter
mainfont: "Open Sans"
fontsize: 11pt
classoption:
  - oneside
margin-left: 2cm
margin-right: 5cm
margin-top: 2cm
margin-bottom: 1.5cm
toc: true
toc-depth: 2
numbersections: true
footnotes-as-endnotes: true
endnotes-heading: References
endnotes-custom-heading: true
colorlinks: true

pandoc-latex-environment:
  marginbox: [marginbox]
  examplebox: [examplebox]
  widebox: [widebox]
  textbox: [textbox]

header-includes: |
  \usepackage{fontawesome5}
  \usepackage{pgf-pie}
  \usepackage{pgfplots}
  \usepackage{wrapfig}
  \pgfplotsset{compat=1.18}
  \addtokomafont{chapter}{\color{my-blue}}
  \addtokomafont{section}{\color{my-blue}}
  \addtokomafont{subsection}{\color{my-accent}}
---
```

## Rules and Constraints

- `brand-colours` hex values: exactly six characters, no `#` prefix
- `chart-colours` entries must match `brand-colours` names (or be bare hex)
- `box-colours` values are LaTeX colour expressions, not hex - use `name!percent` mixing
- Do not put `\definecolor` in `header-includes` - it conflicts with auto-generation
- Document YAML fields override brand YAML fields when the script merges them
- Brand file is prepended, so document settings win on conflict
