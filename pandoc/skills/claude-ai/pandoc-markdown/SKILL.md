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

## Use the pipeline's constructs, not plain-Markdown equivalents

The whole point of this pipeline is a Lua filter that turns extra fenced blocks
into branded, styled LaTeX. **Reach for these first** - plain-Markdown fallbacks
look unstyled and waste the pipeline:

| Need | Use this | Not this |
|------|----------|----------|
| Any table | a `datatable` block | a pipe table |
| A chart, proportion, breakdown | a `piechart` / `barchart` block | numbers in prose |
| Callout, recommendation, example, key statement | a `:::` box | a bold paragraph or blockquote |
| Term + explanation pairs | a definition list | `**bold label**: text` |
| A citation or source | a `^[...]` footnote | an inline parenthetical |

Each construct is detailed below. When a piece of content fits one of these,
always use it - including for the first table in a document, not just "fancy"
ones.

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

Optional page-layout field: report brands reserve a **wide outer margin** for
margin notes (`marginbox`). This is automatic - `margin-note-space: auto` (the
default) keeps the gutter only when the document actually uses margin content
and otherwise collapses to a centred, full-width page, so you normally set
nothing. Force it with `margin-note-space: on` (always reserve) or `off`
(never).

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
- Keep code lines short enough not to wrap. A long line still wraps in the PDF, but a wrap becomes a stray line break when the reader copies the block, so a pasted command/path breaks. Hand-wrap long shell commands in the source with a trailing `\` continuation (and indent the next line), sized to the template's content width: aim for **≤ 50 characters** on the report (`eisvogel-wrapper`) and `mvp`, **≤ 60** on the wider `featured`. See REFERENCE (Long code lines) for the why and the exact budgets.
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

## Tables - always use `datatable`

**Default to a `datatable` block for every table**, even a simple two-column one.
It gives the branded look - coloured header, row shading, controlled column
widths, row spans - that a plain pipe table cannot. Only fall back to a pipe
table if the user explicitly asks for plain Markdown; if in doubt, use
`datatable`.

A `datatable` is a fenced code block: options precede `---`, pipe-delimited rows
follow.

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
list), `text` (1-based prose columns - they claim a larger share of the flexible
width; `text: 2` weights column 2 x2, `text: 2*3` x3), `tone`
(`grey|light|medium|strong` or a number), `caption`. A blank leading cell
continues the cell above as a row span; a leading `+` instead joins the row to
the shaded band above (row group - one shade across several rows, cells not
merged); a cell of `>` merges leftward into its neighbour (column span, e.g. a
full-width banner or a totals label). `**bold**` and LaTeX special characters in
cells are handled automatically by the pipeline.

**Sizing columns.** Omit `widths:` and every column is flexible (`X`),
auto-sized by how much text it carries - a prose column gets the room it needs
while short label columns stay narrow, and columns of similar length come out
equal. So a one-long-column table is usually handled with no options at all.
Override only for a specific proportion: give the short columns fixed widths and
the prose column `X` (`widths: 3cm | X | 2cm`), or weight a column with `text:`
(`text: 2`), which overrides the automatic sizing for that column.

## Charts

Fenced `piechart` / `barchart` blocks, `Label: Value` data lines. Options:
`caption`, `style` (`full|medium|margin`), `axis` (`H|V`, bar only), `prefix`,
`postfix` (use `\%` for a percent sign).

## Citations

Inline footnotes; the pipeline collects them into a References chapter on render.

```markdown
...causes market degradation^[Akerlof, G.A. (1970). "The Market for Lemons", QJE 84(3), 488-500].
```

## Letters

For a letter rather than a report, select the letter format in the document's
front matter with `template: letter`. It has no title page; the recipient
address is positioned for a DL window envelope, with the date and references on
the right. The address is a YAML list of lines (one line per entry).

```yaml
---
template: letter
brand: plain
to:
  - "Ms Jane Smith"
  - "Acme Corporation"
  - "1 High Street"
  - "London SW1A 1AA"
from:                      # optional sender block (top right)
  - "Open Digital Ltd"
  - "10 Tech Park, Manchester M1 2AB"
our-ref: "OD/2026/014"     # optional
your-ref: "ACME-99"        # optional
date: "14 June 2026"       # optional; defaults to today
subject: "Renewal of support agreement"   # optional, bold above the body
opening: "Dear Ms Smith,"  # optional
closing: "Yours sincerely,"  # optional
signature: "S. J. Mackintosh"   # optional
signature-title: "Director"     # optional
signature-image:                # optional scanned signature(s), above the name
  - signature.png               #   one or more (co-signatories, side by side)
window-position: left           # optional; left (default) or right env. window
---

Body of the letter as ordinary Markdown. Boxes, datatables and charts all
still work if needed.
```

Everything except `to` is optional. The body is plain Markdown between the
opening and the closing. `window-position: right` swaps the address to the right
(date/refs to the left) for right-window envelopes. `signature-image` takes a
bare filename (brand folder) or full path; `signature-height` tunes it (18mm).

**Letterhead** - two mutually exclusive ways to brand the page:

- Full-page artwork: `letterhead: letterhead.pdf` overlays a background PDF/image
  (which supplies the logo, rule, contact details, etc.).
- Built from front matter: `letterhead-logo: logo.png` (top-right, first page),
  plus a ruled footer from `letterhead-company:` and `letterhead-contact:` (a
  list of contact lines). Optional: `letterhead-logo-height` (default 16mm),
  `letterhead-rule-colour`, `letterhead-text-colour` (brand-colour names work).
  Statutory second footer line: `letterhead-tel`, `letterhead-reg-number`,
  `letterhead-vat` (each optional, shown only if set). A stylised divider can
  replace the plain rule with `letterhead-rule-image: footer-rule.png`.

Asset files (logo, artwork) resolve by bare filename from the brand folder, the
same as brand logos. Layout can be nudged with `address-top` (default 40mm),
`letter-margin`, `letter-top`, `letter-bottom`.

## Featured cover (`template: featured`)

A client-facing report/proposal with a designed graphical cover: a brand-colour
band across the lower third, logo, title/subtitle, a metadata block, a "Document
overview" panel, an optional classification chip, and an optional `cover-image`
(its own natural shape, placed under the title) - then a section-based body with
brand-coloured headings and a page X-of-Y footer. Cover colours come from the
brand (title-page colour + accent); override with `cover-color` /
`cover-text-color` / `cover-accent`.

```yaml
template: featured
title: "Reserves Review"
clientname: "Acme Trust"      # optional, above the title
classification: "Confidential" # optional chip + header
fao: "The Board"              # optional
docver: "v1.0"                # optional
overview: [Reserves, Risk, Recommendations]   # optional panel
cover-image: cover.png        # optional; placed under the title (natural shape)
watermark: "DRAFT"            # optional; diagonal text, content pages only
page-background: texture.png  # optional; full-page image behind every page
```

Everything except `title` is optional. Uses sections (not chapters) - best for
briefings, proposals and board papers. Note: 16-bit PNGs silently fail to render
in xelatex - re-save cover/background images as 8-bit.

## Slides

Two slide formats, same heading model (`#` = section/divider slide, `##` =
content slide), both auto-styled from the brand's `beamer-structure`/
`beamer-accent` colours:

- `template: beamer` - classic beamer deck (full beamer theming).
- `template: slides` - modern, flat, full-bleed brand-colour deck (xelatex).

### Beamer (`template: beamer`)

Output is a beamer PDF. Structure: a level-1 heading (`#`) starts a section; a
level-2 heading (`##`) starts a new slide; content under it is the slide body.
An empty `##` gives an untitled slide.

```yaml
---
template: beamer
brand: plain
title: "London Perl Workshop"
subtitle: "The Perl and Raku Foundation"
author: "Stuart J Mackintosh"
institute: "The Perl and Raku Foundation"
date: "24 October 2024"
theme: Madrid           # any beamer theme
colortheme: whale       # any beamer colour theme
fonttheme: professionalfonts
---
```

Two-column slides use beamer's native column divs:

```markdown
::: columns
:::: column

## Left

- point

::::
:::: column

## Right

- point

::::
:::
```

Brand colours are wired into the beamer palette automatically (the brand sets
`beamer-structure`/`beamer-accent`); the document keeps full control of the
`theme`, `colortheme` and any `\setbeamercolor` it puts in `header-includes` -
those override the brand. Images use `![](logo.png)` as usual.

### Modern (`template: slides`)

A flat, full-bleed deck in pure xelatex. Each slide fills the page in the brand
colour, bold type, accent rule. Same heading model: `#` = big section/divider
slide, `##` = content slide. The front-matter `title`/`subtitle`/`author`/`date`
draw the title slide automatically.

```yaml
---
template: slides
brand: plain
title: "London Perl Workshop"
subtitle: "The Perl and Raku Foundation"
author: "Stuart J Mackintosh"
date: "24 October 2024"
---
```

- **Per-slide colour role** via an H2 attribute: `{.light}` (default), `{.dark}`
  (solid brand ground, white text), `{.accent}` (accent ground, white text).
- **Images** are auto-boxed in a white card; add `{.plain}` to drop the card.
  Width honoured: `![](chart.png){width=60%}`.
- **Columns** use the same `::: columns` / `:::: column` divs as beamer.
- **Override grounds** per deck with `slide-title-bg:` / `slide-accent:` in the
  front matter (any brand colour name).
- **Fonts** are three display roles, each overridable in front matter (or the
  brand): `slide-display-font` (big stat/tier figures), `slide-headline-font`
  (`##` content headlines — a readable sans like `Inter Display` reads far better
  than the default high-contrast serif), `slide-title-font` (the title slide,
  `#` dividers and the text wordmark — e.g. a brand logo face like `Audiowide`).
  A non-default font must be available where the deck is built — installed
  system-wide, or just dropped into the brand folder (any `.ttf`/`.otf`/`.ttc`
  there is auto-registered for the render). If missing, xelatex substitutes and
  the build still succeeds.

The datatable, chart and `:::` box constructs are report features and are not
available on either slide format; use columns, lists and images instead.

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
- [ ] Every table is a `datatable` block, not a pipe table
- [ ] Charts/proportions use `piechart`/`barchart`, not prose
- [ ] Citations use `^[...]`; British English throughout
- [ ] Boxes used sparingly with blank lines around them
