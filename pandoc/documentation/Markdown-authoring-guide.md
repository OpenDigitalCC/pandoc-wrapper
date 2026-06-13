---
title: "Document Authoring Guide"
subtitle: "Writing for the Publishing Pipeline"
brand: plain
---

# How the pipeline works

This guide covers how to write documents for this publishing pipeline. Documents
are written in Markdown, compiled by Pandoc, and rendered to PDF using a
professional LaTeX template. You don't need to know anything about LaTeX or Pandoc
to write good documents - but understanding the conventions here will help you get
clean, well-structured output.

For each element, this guide shows both the source syntax and how it looks when
rendered in the document.


You write a plain Markdown file. At the top of that file is a small block of
settings (called YAML front matter) that tells the system what the document is,
which visual brand to apply, and how to lay it out. When you pass the file to
the build script, it merges your content with the brand settings and produces
a PDF.

The key things you control as an author:

- The YAML front matter at the top of your document
- The structure and content of your Markdown
- Which special elements (boxes, tables, charts) you use

Everything visual - colours, fonts, margins, header and footer styling - comes
from the brand configuration. You reference a brand by name; you don't need
to configure it yourself.

# Front matter

The top of every document must have a YAML block. At minimum:

```yaml
---
title: "Your Document Title"
subtitle: "Your Subtitle"
brand: plain
---
```

The three dashes open and close the block. `title` and `subtitle` are always
required. `brand` tells the system which visual identity to apply - use `plain`
unless you've been told to use a specific brand for your project.

Other settings can be added to the front matter when needed - for example,
whether to show a table of contents, page numbering depth, or print settings.
These will be specified for you when relevant.

# Heading structure

Use `#` for top-level headings, `##` for the next level down, and so on.
Never skip levels - don't jump from `#` to `###`.

Whether `#` produces a "chapter" or a "section" in the output depends on the
brand configuration. Most brand setups use `top-level-division: chapter`, which
means:

- `#` becomes a chapter
- `##` becomes a section
- `###` becomes a subsection
- `####` becomes a subsubsection

Always leave a blank line after a heading before your content.

Write this:

```markdown
# Chapter Title

## Section Title

### Subsection Title
```

It renders as:

# Chapter Title

## Section Title

### Subsection Title

## Chapter mini table of contents

In long documents you can add a per-chapter table of contents by placing
`\minitoc` on its own line immediately after the chapter heading:

```markdown
# Chapter Title

\minitoc

Chapter introduction text begins here...

## First Section
```

Only chapters where you explicitly add `\minitoc` will have one. Use it
selectively for long chapters with five or more sections.

# Formatting conventions

These conventions exist to produce clean, consistent output across all documents.

## Definition lists

Don't use bold labels for definitions. Use a definition list instead.

Write this:

```markdown
Open source software
: Software whose source code is publicly available and may be freely used,
  modified, and distributed.

Proprietary software
: Software whose source code is not publicly available and is owned by
  a specific person or company.
```

It renders as:

Open source software
: Software whose source code is publicly available and may be freely used,
  modified, and distributed.

Proprietary software
: Software whose source code is not publicly available and is owned by
  a specific person or company.

Each term goes on its own line. The definition follows on the next line,
indented with `: `.

## Bold and emphasis

Bold is for genuine critical emphasis only - a word or short phrase that
absolutely must stand out. Don't use it for labels, headings, or to introduce
topics. If you find yourself using bold frequently, that's a sign the structure
should be doing that work instead.

Write this:

```markdown
The report found several issues, but the **critical failure** was in data handling.
```

It renders as:

The report found several issues, but the **critical failure** was in data handling.

## Dashes

Use an en-dash (–) for ranges: pages 10–15, the 2020–2024 period.

For a dash in a sentence - like this one - use a space, a hyphen, and a space.
Do not use an em-dash (—).

Write this:

```markdown
The project ran from 2022–2024 and covered pages 10–45 of the report.

The result was unexpected - but it confirmed the hypothesis.
```

It renders as:

The project ran from 2022–2024 and covered pages 10–45 of the report.

The result was unexpected - but it confirmed the hypothesis.

## Spacing

Leave a blank line before every block element: before lists, before code blocks,
before tables, before boxes, before headings, before definition lists. This keeps
the source readable and ensures clean rendering.

Single space after full stops.

## Horizontal rules

Don't use `---` as a visual divider in your content. Structure comes from the
heading hierarchy. The `---` sequence is only used for the YAML front matter
block delimiters.

## Lists

Use `-` for bullet points. Indent nested lists by two spaces. Only add blank
lines between list items if individual items contain multiple paragraphs.

Write this:

```markdown
- First item
- Second item
  - Nested item
  - Another nested item
- Third item
```

It renders as:

- First item
- Second item
  - Nested item
  - Another nested item
- Third item

## Checklists

The `- [ ]` syntax produces a checkbox list. Items can be marked complete
with `- [x]`.

Write this:

```markdown
- [ ] Draft the introduction
- [x] Gather supporting data
- [ ] Review with stakeholders
```

It renders as:

- [ ] Draft the introduction
- [x] Gather supporting data
- [ ] Review with stakeholders

# Special boxes

The pipeline supports several types of highlighted content blocks. Use these
sparingly - overuse reduces their impact.

All boxes use the same basic syntax: three colons, the box type name, content,
and three closing colons. Leave blank lines before and after each box.

## widebox

A full-width box with a coloured border, for thesis statements, critical
conclusions, or key findings you want to stand out.

Write this:

```markdown
::: widebox
Open source powers the vast majority of digital infrastructure, yet the value
chain creating that infrastructure remains excluded from financial flows.
:::
```

It renders as:

::: widebox
Open source powers the vast majority of digital infrastructure, yet the value
chain creating that infrastructure remains excluded from financial flows.
:::

## examplebox

For concrete examples, case studies, or supporting evidence. Automatically
prefixed with a book icon.

Write this:

```markdown
::: examplebox
**Netherlands**: The Ministry of Health mandated AGPL licensing for infrastructure
development, achieving €15 million in successful procurement outcomes.
:::
```

It renders as:

::: examplebox
**Netherlands**: The Ministry of Health mandated AGPL licensing for infrastructure
development, achieving €15 million in successful procurement outcomes.
:::

## marginbox

Placed in the wide outer margin of the page, alongside the main text. Good for
quotes, attributions, or brief highlights that complement the prose without
interrupting it. Requires a document layout with a wide outer margin.

Write this:

```markdown
::: marginbox
"Technology is not the limiting factor"

**2018 NHS Research**
:::
```

It renders as:

::: marginbox
"Technology is not the limiting factor"

**2018 NHS Research**
:::

## textbox

A 60%-width box that the main text flows alongside. For supporting information,
asides, or brief notes that sit beside the prose rather than interrupting it.

Write this:

```markdown
::: textbox
Key finding: organisations with open procurement policies reported 40% lower
long-term maintenance costs.
:::
```

It renders as:

::: textbox
Key finding: organisations with open procurement policies reported 40% lower
long-term maintenance costs.
:::

## recommendation

Use this for formal recommendations in reports and policy documents. Each one
is automatically numbered ("Recommendation 1:", "Recommendation 2:") in the
order they appear across the whole document.

Write this:

```markdown
::: recommendation
Establish a formal reserves policy targeting six months of operating expenses,
reviewed annually by the board.
:::
```

It renders as:

::: recommendation
Establish a formal reserves policy targeting six months of operating expenses,
reviewed annually by the board.
:::

## box-policysummary

For policy mechanism explanations. Automatically headed "Policy concept summary"
with a scales icon.

Write this:

```markdown
::: box-policysummary
Requiring AGPL licensing for publicly funded software ensures that modifications
made by vendors during delivery remain available to the commissioning authority,
preventing stealth lock-in.
:::
```

It renders as:

::: box-policysummary
Requiring AGPL licensing for publicly funded software ensures that modifications
made by vendors during delivery remain available to the commissioning authority,
preventing stealth lock-in.
:::

## budgetbox

For budget proposals and cost summaries. Automatically headed "Budgetary
proposal" with a euro icon.

Write this:

```markdown
::: budgetbox
Proposed investment in open infrastructure tooling: €50,000 in year one,
reducing to €15,000 per annum in years two and three.
:::
```

It renders as:

::: budgetbox
Proposed investment in open infrastructure tooling: €50,000 in year one,
reducing to €15,000 per annum in years two and three.
:::

# Tables

For simple tables, use standard Markdown pipe syntax.

Write this:

```markdown
| Approach | Cost | Risk |
|---|---|---|
| Proprietary | High | High lock-in |
| Open source | Low | Low lock-in |
```

It renders as:

| Approach | Cost | Risk |
|---|---|---|
| Proprietary | High | High lock-in |
| Open source | Low | Low lock-in |

For tables that need styled headers, alternating row colours, column width
control, or cells that span multiple rows, use a datatable block instead.

## Datatables

A datatable is a fenced code block with class `datatable`. Options go before
the `---` separator; data rows follow it, separated by pipes.

Write this:

````markdown
```datatable
columns: Phase | Actions | Deliverable
widths: 2.5cm | X | 4.5cm
bold: 1
tone: medium
---
Requirements | Define scope and identify top risks. | Security context document.
Design | Maintain architecture diagram. | Architecture diagram.
Development | Build secure defaults. | CI checklist.
```
````

It renders as:

```datatable
columns: Phase | Actions | Deliverable
widths: 2.5cm | X | 4.5cm
bold: 1
tone: medium
---
Requirements | Define scope and identify top risks. | Security context document.
Design | Maintain architecture diagram. | Architecture diagram.
Development | Build secure defaults. | CI checklist.
```

The options available are:

`columns`
: Pipe-separated column header labels. Leave out this option entirely if you
  don't want a header row.

`widths`
: Pipe-separated column widths. Use `X` for a flexible column that shares the
  remaining space equally with other `X` columns. Use a fixed measurement like
  `3.5cm` for columns with known content width. If you omit this option,
  all columns share space equally.

`bold`
: A comma-separated list of column numbers (starting from 1) whose content
  should be bold. For example, `bold: 1, 2` bolds the first two columns.

`tone`
: Controls how strongly the brand colour is applied to the header and alternating
  rows. Options are `grey` (neutral, no brand colour), `light`, `medium`
  (the default), and `strong`. You can also use a number like `40` for a
  custom percentage.

`caption`
: An optional caption that appears above the table.

You can use `**bold**` inside cell text - it will be converted automatically.
Characters like `&`, `%`, and `$` are also escaped automatically so you don't
need to worry about them.

## Row spans

A blank cell at the start of a row causes the cell above it in the same column
to span down. This is useful for grouping related rows under a shared label.

Write this:

````markdown
```datatable
columns: Category | Item | Notes
widths: 3cm | X | X
bold: 1
---
Infrastructure | Servers | On-premise hardware
 | Networking | Managed switches
 | Storage | NAS array
Software | OS licences | Annual renewal
 | Security tools | Per-seat pricing
```
````

It renders as:

```datatable
columns: Category | Item | Notes
widths: 3cm | X | X
bold: 1
---
Infrastructure | Servers | On-premise hardware
 | Networking | Managed switches
 | Storage | NAS array
Software | OS licences | Annual renewal
 | Security tools | Per-seat pricing
```

"Infrastructure" spans three rows, "Software" spans two.

# Charts

Charts are defined as fenced code blocks. Data lines use `Label: Value` format.

## Pie chart

Write this:

````markdown
```piechart
caption: Budget allocation by area
style: medium
postfix: \%
Programme delivery: 62
Administration: 18
Communications: 12
Reserves: 8
```
````

It renders as:

```piechart
caption: Budget allocation by area
style: medium
postfix: \%
Programme delivery: 62
Administration: 18
Communications: 12
Reserves: 8
```

## Bar chart

Write this:

````markdown
```barchart
caption: Income by source
axis: H
prefix: £
Grants: 142000
Contracts: 87000
Donations: 23000
Events: 11000
```
````

It renders as:

```barchart
caption: Income by source
axis: H
prefix: £
Grants: 142000
Contracts: 87000
Donations: 23000
Events: 11000
```

## Chart options

The `style` option controls placement:

`full`
: Full text width. The default. Best for standalone charts needing maximum space.

`medium`
: Centred at about half text width. Good for smaller charts alongside prose.

`margin`
: Placed in the outer page margin. Suited to small supporting data points.

The `axis` option in bar charts controls direction: `H` for horizontal bars
(usually best for labelled data), `V` for vertical bars.

Use `prefix` for a symbol before values (like `£` or `$`) and `postfix` for
a symbol after them (like `\%` - note the backslash before the percent sign).

# Citations and references

Use inline footnote syntax for citations. When the document is compiled,
footnotes are collected and printed as a References chapter at the end.

Write this:

```markdown
Digital infrastructure requires long-term investment models^[Smith, J. (2023).
"Sustainable Open Source Funding". Journal of Digital Policy, Vol. 4, pp. 12-28.].
```

It renders as:

Digital infrastructure requires long-term investment models^[Smith, J. (2023).
"Sustainable Open Source Funding". Journal of Digital Policy, Vol. 4, pp. 12-28.].

The superscript number appears in the text. The full citation is collected in
the References chapter at the end of the document.

# Images and code

## Images

Images render at full text width by default. To use a different size, add a
width attribute.

Write this:

```markdown
![A descriptive caption for the image](path/to/image.png)

![A smaller image at half width](path/to/image.png){ width=50% }
```

## Code

Inline code uses backticks.

Write this:

```markdown
Set the `brand` field to match your project.
```

It renders as:

Set the `brand` field to match your project.

Code blocks use fenced syntax with a language identifier.

Write this:

````markdown
```python
def calculate_total(items):
    return sum(item.price for item in items)
```
````

It renders as:

```python
def calculate_total(items):
    return sum(item.price for item in items)
```

Always specify the language - it enables syntax highlighting in the output.
Common identifiers: `python`, `bash`, `javascript`, `yaml`, `markdown`, `sql`.

# Document layout options

## Covers and title pages

The brand configuration usually handles the title page. When needed, you can
control it from the document front matter.

To use the template's built-in title page:

```yaml
titlepage: true
titlepage-color: "2C3E50"
titlepage-text-color: "FFFFFF"
```

To use a pre-designed PDF as your cover instead:

```yaml
titlepage: false
cover-pdf: Graphics/frontcover.pdf
```

A back cover can also be added:

```yaml
backpage: true
backpage-text: |
  Description of the document and its purpose.
  Can span multiple lines.
backpage-publisher: "Organisation Name"
backpage-website: "www.example.com"
```

## Print vs digital output

Documents can be produced in two modes. The brand or build process usually
handles this, but you can control it from your front matter.

For digital distribution (symmetric layout, no crop marks):

```yaml
classoption:
  - oneside
printready: false
```

For professional printing (binding-ready layout, crop marks, page count
rounded to a multiple of 4):

```yaml
classoption:
  - twoside
printready: true
```

## Headers and footers

The brand configuration sets sensible defaults. You can override them in your
document front matter:

```yaml
header-left: ""
header-center: "Project Name"
header-right: ""
footer-left: "CONFIDENTIAL"
footer-center: ""
footer-right: ""
```

Setting a field to an empty string `""` suppresses the default content for that
position. Leaving the field out entirely keeps the brand default. The defaults
are: title top-left, date top-right, author bottom-left, page number bottom-right.

# British English

Use British spelling throughout: organise, realise, favour, whilst, colour,
programme, licence (noun), license (verb), centre, analyse.

Use single quotation marks for quotes within prose. Use double quotation marks
for quotes within quotes.

Dates in day-month-year format: 15 January 2026 or 15/01/2026.

# Quick checklist

Before handing over a document:

- [ ] YAML front matter has `title`, `subtitle`, and `brand`
- [ ] Heading levels are sequential with no gaps
- [ ] Term-definition pairs use definition lists, not bold labels
- [ ] Bold used only for genuine critical emphasis
- [ ] Blank line before every block element (lists, boxes, code, tables)
- [ ] En-dashes for ranges, space-hyphen-space for sentence dashes
- [ ] No horizontal rules (`---`) in content
- [ ] Unordered lists use `-`
- [ ] Citations use `^[...]` footnote syntax
- [ ] Code blocks have a language identifier
- [ ] British English spelling throughout
- [ ] Boxes used sparingly, with blank lines before and after
