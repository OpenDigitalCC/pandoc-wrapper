# REF: Document Authoring

Reference for writing markdown documents that compile via `md-to-pdf.sh`
using `document-filters.lua` and `eisvogel-reorganized`.

## Document Front Matter

Every document needs a YAML front matter block. Minimal example:

```yaml
---
title: "Document Title"
subtitle: "Subtitle"
author: "Author Name"
date: "January 2026"
brand: plain
---
```

The `brand` field loads `~/.pandoc/brands/brand-{name}.yaml`. Fields in the
document override brand defaults. See REF-brand-yaml.md for brand authoring
and REF-template-yaml.md for all available fields.

## Document Structure

With `top-level-division: chapter` (set in brand or document):

- `#` → Chapter
- `##` → Section
- `###` → Subsection
- `####` → Subsubsection

With `top-level-division: section`:

- `#` → Section
- `##` → Subsection
- `###` → Subsubsection

### Mini TOC per Chapter

Place `\minitoc` immediately after a chapter heading to insert a
section-level table of contents for that chapter:

```markdown
# Chapter Title

\minitoc

Chapter introduction text...

## Section One
```

Requires `minitoc: true` in YAML. Only chapters where `\minitoc` appears
get a mini TOC - selective control is intentional.

## Content Boxes

All boxes use the fenced div syntax. Content inside boxes is full pandoc
markdown - bold, links, lists, definition lists all work.

### widebox

Full text width, rounded border. For key statements and thesis points.
Uses `frame-highlight` / `bg-highlight` colours.

```markdown
::: widebox
A key statement spanning the full width of the text area.
:::
```

### examplebox

Full width with left border rule. Prefixed with a book icon automatically.
For evidence, case studies, concrete examples. Uses `frame-accent` / `bg-accent`.

```markdown
::: examplebox
**Netherlands**: Ministry of Health mandating AGPL licensing for infrastructure
development, achieving €15 million in successful procurement.
:::
```

### marginbox

Placed in the page margin. Left rule on odd pages, right rule on even pages.
For quotes and brief highlights. Uses `frame-contrast` (no background fill).

```markdown
::: marginbox
"Quote or key point here"

**Attribution or source**
:::
```

Requires wide outer margin (typically `margin-right: 5cm`).

### textbox

60% width, wraps to the right of the page with text flowing alongside.
For supporting information beside prose. Uses `frame-info` / `bg-info`.

```markdown
::: textbox
Important information that sits alongside the main text flow.
:::
```

### recommendation

Full width with left border rule and auto-numbered heading ("Recommendation 1:",
"Recommendation 2:", etc.). Counter increments across the whole document.
Uses `frame-accent` / `bg-accent`.

```markdown
::: recommendation
Establish a formal reserves policy targeting six months of operating expenses.
:::
```

### box-policysummary

Full width with left border rule. Prefixed with a scales icon and bold
"Policy concept summary" heading automatically. Uses `frame-accent` / `bg-contrast`.

```markdown
::: box-policysummary
Summary of the policy concept and its implications for implementation.
:::
```

### budgetbox

Full width with left border rule. Prefixed with a euro icon and bold
"Budgetary proposal" heading automatically. Uses `frame-contrast` / `bg-info`.

```markdown
::: budgetbox
Proposed budget allocation for the initiative: €50,000 in year one.
:::
```

## Charts

Charts are fenced code blocks. The block class determines chart type.
Data lines are `Label: Value`. Option lines are `key: non-numeric-value`.

### Pie Chart

```markdown
    ```piechart
    caption: Total Expense: $233,739.75
    style: full
    postfix: \%
    Program Expenses: 92
    Administration Expenses: 4
    Fundraising Expenses: 4
    ```
```

### Bar Chart

```markdown
    ```barchart
    caption: Spending by programme area (USD)
    axis: H
    style: full
    prefix: $
    Perl Core Maintenance: 95239
    Raku Core Development: 28374
    Events: 28291
    ```
```

### Chart Options

`style`
: `full` (default) - left-aligned, full text width. `medium` - centred at
  55% width. `margin` - placed in page margin, no legend.

`caption`
: Figure caption. LaTeX special characters escaped automatically.

`axis`
: Bar chart only. `H` (horizontal, default) or `V` (vertical).

`prefix`
: Text before each value label (e.g. `$`).

`postfix`
: Text after each value label (e.g. `\%`). Note the backslash before `%`.

`colours`
: Comma-separated `brand-colours` names to override the brand palette for
  this chart only. Optional.

### Chart Style Detail

`full`
: Full `\textwidth`. Pie radius 4. Numbered figure caption. Best for
  standalone charts needing maximum space.

`medium`
: Centred minipage at 55% text width, scaled to 0.8. Numbered figure caption.
  Good for charts that don't need full width.

`margin`
: In the page margin via `\marginnote`. Scaled to `\marginparwidth`.
  Pie charts show values inside segments (no legend). Plain scriptsize caption,
  no figure number. Requires wide outer margin.

## Data Tables

Datatables are fenced code blocks with class `datatable`. Options appear
before the `---` separator. Data rows follow it, pipe-delimited.

### Basic Datatable

```markdown
    ```datatable
    columns: Phase | Actions | Deliverable
    widths: 2.5cm | X | 4.5cm
    bold: 1
    tone: medium
    ---
    Requirements | Define product context and top risks. | 1-page security context.
    Design | Maintain architecture diagram with trust boundaries. | Architecture diagram.
    Development | Build secure defaults; enforce dependency hygiene. | CI evidence.
    ```
```

### Datatable with Rowspans

A blank leading cell continues the cell above in a `\multirow` span:

```markdown
    ```datatable
    columns: Principle | Requirement | Notes
    widths: 3cm | 3.5cm | X
    bold: 1, 2
    tone: medium
    ---
    Trust boundaries | ANNEX-1.PT1.1 | Supports risk identification.
     | ANNEX-1.PT1.2.d | Supports access protection.
     | ANNEX-1.PT1.2.e | Supports confidentiality.
    Least privilege | ANNEX-1.PT1.2.d | Supports access limitation.
     | ANNEX-1.PT1.2.f | Supports integrity protection.
    ```
```

### Datatable Options

`columns`
: Pipe-separated header labels. If omitted, column count inferred from first
  data row and no header row is shown.

`widths`
: Pipe-separated. `X` = flexible (divides remaining space equally among X
  columns). `Ncm` = fixed width (e.g. `3.5cm`). Default is all `X`.

`bold`
: Comma-separated 1-based column numbers to auto-bold (e.g. `1, 2`).

`tone`
: Header and alternating row shade intensity. Options: `grey` (neutral,
  no brand colour), `light` (30%), `medium` (60%, default), `strong` (90%).
  Or a bare number (e.g. `40`) for custom percentage.

`caption`
: Optional table caption rendered above the table.

`textwidth`
: Override assumed text width in cm for X column calculations. Default 17
  (A4 with 2cm margins). Use 14 for templates with wide margins.

### Cell Content

Markdown `**bold**` in cells is converted to `\textbf{}`. LaTeX special
characters (`&`, `%`, `#`, `_`, `$`) are escaped automatically.

## Footnotes and Endnotes

Inline footnote syntax:

```markdown
Some claim supported by evidence^[Author (2024). "Article Title". Journal Name.]
```

With `footnotes-as-endnotes: true` in YAML, footnotes collect as endnotes
in a "References" chapter at the end of the document. The chapter appears
in the TOC automatically and only if the document has footnotes.

## Margin Notes (LaTeX Direct)

These use raw LaTeX commands directly in markdown:

Plain margin note:
```markdown
\marginnote{Text that appears in the margin at this point in the document.}
```

Margin quote box:
```markdown
\marginquote{Quote text here}{Attribution}
```

Both require a wide outer margin (`margin-right: 5cm` or similar).

## Standard Markdown

All standard pandoc markdown works. Items relevant to this pipeline:

Definition lists:
```markdown
Term one
: Definition text here

Term two
: Another definition
```

Images default to full text width (`\textwidth`) due to the template's
`\setkeys{Gin}{width=1\textwidth,keepaspectratio}`.

Override image width inline:
```markdown
![Caption](image.png){ width=50% }
```

## Multi-File Documents

The `md-to-pdf.sh` script concatenates multiple source files. Split long
documents across files and pass them all to the script. YAML front matter
should be in the first file only. See REF-md-to-pdf-script.md for ordering
options.
