---
name: pandoc-markdown
description: >-
  Author Markdown for the pandoc-wrapper PDF publishing pipeline (md-to-pdf.sh).
  Enforces the house format: YAML front matter with title/subtitle/brand, ATX
  headings, definition lists instead of bold labels, en-dashes, British English,
  the ::: special boxes (widebox, examplebox, marginbox, textbox, recommendation,
  box-policysummary, budgetbox), datatable and chart code blocks, and footnote
  citations. Use whenever creating or editing any .md file that will be rendered
  to PDF through this pipeline, or whenever the user asks for a report, brief,
  policy document, or styled PDF in this project.
---

# Pandoc-wrapper Markdown format

Markdown written for this project is compiled by Pandoc through a Lua filter and
an Eisvogel-derived LaTeX template into a styled, branded PDF via `md-to-pdf.sh`.
Follow these rules whenever you create or edit a `.md` document here. For the
exhaustive reference (every box, every option, rendered examples) read
`REFERENCE.md` in this skill folder, or the project guides under
`pandoc/documentation/`.

## Always start with YAML front matter

Every document opens with a front-matter block. `title`, `subtitle`, and `brand`
are required. Use `brand: plain` unless a specific brand is named.

```yaml
---
title: "Document Title"
subtitle: "Document Subtitle"
brand: plain
---
```

Available brands live in `pandoc/brands/` (`brand-<name>.yaml`): plain, oca,
odcc, cloudient, dhcf, mg, sc, tprf, xisl. The `brand:` value is the `<name>`.

## Core formatting rules

- Headings: ATX only (`#`, `##`, `###`). Never skip a level. Blank line after every heading.
- Definition lists, not bold labels. Convert any `**term**: definition` to a definition list:

  ```markdown
  term
  : definition text
  ```

- Bold (`**...**`) only for genuine critical emphasis - never for labels or section markers.
- Lists use `-` (not `*`/`+`), two-space nested indent, blank line before the list.
- Dashes: en-dash `–` for ranges (2020–2024); for a sentence aside use space-hyphen-space ` - `. Never em-dash `—`.
- Single space after a full stop. Blank line before and after every block element (list, table, code, box, definition list).
- No horizontal rules (`---`) in body content - `---` is only the front-matter delimiter. Structure comes from headings.
- Code blocks always carry a language identifier (` ```bash `, ` ```python `, ` ```yaml `).
- British English throughout: organise, realise, colour, favour, whilst, programme, licence (noun) / license (verb). Single quotes for quotes; dates as 15 January 2026 or 15/01/2026.

## Special boxes

Pandoc fenced divs (`:::`), separated from surrounding text by blank lines. Use
sparingly. Full Markdown works inside them.

- `widebox` - full-width bordered box for a thesis statement or key conclusion.
- `examplebox` - case studies / evidence (book icon).
- `marginbox` - short quote or highlight in the outer margin.
- `textbox` - 60%-width box the text flows alongside.
- `recommendation` - auto-numbered "Recommendation N:" for formal recommendations.
- `box-policysummary` - policy mechanism summary (scales icon).
- `budgetbox` - cost/budget proposal (euro icon).

```markdown
::: recommendation
Establish a formal reserves policy targeting six months of operating expenses.
:::
```

## Tables

Simple data: standard pipe tables. Styled tables (coloured header, row shading,
column widths, row spans): a fenced `datatable` block. Options precede `---`;
pipe-delimited rows follow.

```datatable
columns: Phase | Actions | Deliverable
widths: 2.5cm | X | 4.5cm
bold: 1
tone: medium
---
Requirements | Define scope and top risks. | Security context document.
Design | Maintain architecture diagram. | Architecture diagram.
```

Options: `columns`, `widths` (`X` flexible / `Ncm` fixed), `bold` (1-based column
list), `tone` (`grey|light|medium|strong` or a number), `caption`. A blank
leading cell continues the cell above as a row span. `**bold**` and LaTeX special
characters in cells are handled automatically.

## Charts

Fenced `piechart` / `barchart` blocks, `Label: Value` data lines. Options:
`caption`, `style` (`full|medium|margin`), `axis` (`H|V`, bar only), `prefix`,
`postfix` (use `\%` for a percent sign).

## Citations

Inline footnotes; they are collected into a References chapter on render.

```markdown
...causes market degradation^[Akerlof, G.A. (1970). "The Market for Lemons", QJE 84(3), 488-500].
```

## Building the PDF

After writing or editing a document, render it with the driver script:

```bash
./md-to-pdf.sh path/to/document.md
```

Useful flags: `--no-viewer` (don't auto-open the PDF), `--order-alpha` (sort
multiple inputs), `--debug`. The script reads brands and templates from
`~/.pandoc/`, so that deployment must be in place.

## If a build fails with "\multirow" (exit code 43)

A datatable row span needs the LaTeX `multirow` package. The current pipeline
loads it automatically. On an older pipeline, add to the front matter:
`header-includes: \usepackage{multirow}`. Read the first `! ` line of the LaTeX
log for the real cause of any build failure.

## Pre-handover checklist

- [ ] Front matter has `title`, `subtitle`, `brand`
- [ ] ATX headings, no skipped levels, blank line after each
- [ ] Term/definition pairs are definition lists, not bold labels
- [ ] Bold only for critical emphasis
- [ ] En-dashes for ranges, space-hyphen-space for asides, no em-dashes
- [ ] Blank line before every block element; no stray `---` in body
- [ ] Lists use `-`; code blocks name their language
- [ ] Citations use `^[...]`; British English throughout
- [ ] Boxes used sparingly with blank lines around them
