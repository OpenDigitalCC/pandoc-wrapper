---
name: pandoc-markdown
description: >-
  Produce Markdown in the house format for a Pandoc + LaTeX PDF publishing
  pipeline. Enforces YAML front matter with title/subtitle/brand, ATX headings,
  definition lists instead of bold labels, en-dashes, British English, the :::
  special boxes (widebox, examplebox, marginbox, textbox, recommendation,
  box-policysummary, budgetbox), datatable and chart code blocks, and footnote
  citations. Use whenever the user asks for a report, brief, policy document, or
  styled PDF, or any Markdown intended to be rendered to PDF through this
  pipeline. The user compiles the finished Markdown themselves.
---

# Pandoc publishing-pipeline Markdown format

The Markdown you produce is compiled by the user through Pandoc and a LaTeX
template into a styled, branded PDF. You do not run the build; you deliver a
clean `.md` file that follows these rules exactly. The complete reference, with
every box and option, is in `REFERENCE.md` bundled with this skill.

## Always start with YAML front matter

Every document opens with a front-matter block. `title`, `subtitle`, and `brand`
are required. Use `brand: plain` unless the user names a specific brand.

```yaml
---
title: "Document Title"
subtitle: "Document Subtitle"
brand: plain
---
```

The `brand` value selects a visual identity (colours, fonts, layout). Use exactly
the brand the user specifies; otherwise `plain`.

## Core formatting rules

- Headings: ATX only (`#`, `##`, `###`). Never skip a level. Blank line after every heading.
- Definition lists, not bold labels. Convert any `**term**: definition` to:

  ```markdown
  term
  : definition text
  ```

- Bold (`**...**`) only for genuine critical emphasis - never for labels or section markers.
- Lists use `-` (not `*`/`+`), two-space nested indent, blank line before the list.
- Dashes: en-dash `–` for ranges (2020–2024); for a sentence aside use space-hyphen-space ` - `. Never em-dash `—`.
- Single space after a full stop. Blank line before and after every block element.
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
characters in cells are handled automatically by the pipeline.

## Charts

Fenced `piechart` / `barchart` blocks, `Label: Value` data lines. Options:
`caption`, `style` (`full|medium|margin`), `axis` (`H|V`, bar only), `prefix`,
`postfix` (use `\%` for a percent sign).

## Citations

Inline footnotes; the pipeline collects them into a References chapter on render.

```markdown
...causes market degradation^[Akerlof, G.A. (1970). "The Market for Lemons", QJE 84(3), 488-500].
```

## Avoid the common build failure

Datatable row spans are fine - the pipeline handles the LaTeX `multirow`
requirement. Do not hand-write raw LaTeX commands in the Markdown unless asked;
stick to the constructs above so the document compiles cleanly.

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
