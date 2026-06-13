When generating Markdown content for reports and documentation, use these Markdown Formatting Instructions.

## YAML Front Matter

All documents must include a YAML front matter block. Always include `title` and `subtitle`.
Use `brand: plain` unless the project context makes a different brand obvious, or a brand is specified in the conversation.
Other front matter fields will be specified as required.

```yaml
---
title: "Document Title"
subtitle: "Document Subtitle"
brand: plain
---
```

## Core Formatting Rules

### Headers

- Use ATX-style headers only: `# Header`
- Consistent heading hierarchy (no skipped levels)
- Insert blank line after titles and before all formatting changes

### Horizontal Rules

- No horizontal rules (`---`) unless explicitly requested
- Use section breaks through heading hierarchy instead

### Bold and Emphasis

- Minimise bold formatting (`**text**`) - use only for critical emphasis
- Never use bold for labels or section markers
- For term/definition pairs, use definition lists not bold labels

### Lists

- Use `-` for unordered lists (not `*` or `+`)
- Use 2-space indentation for nested lists
- Blank lines between list items only when items contain multiple paragraphs
- Insert blank line before list starts

### Definition Lists

- Use definition lists for all term/definition pairs:

```markdown
term
: definition text
```

- Convert any `**term**: definition` pattern to definition list format
- Do not use bold labels as pseudo-definitions

### Spacing

- Single space after periods (European convention)
- Insert blank line after titles
- Insert blank line before all formatting changes (lists, code blocks, tables)
- Insert blank line before and after all block elements
- Blank line before and after definition lists

### Dashes

- Use en-dashes (–) for ranges: 2010–2012, 5–10 year
- Do not use em-dashes (—) - replace with space-dash-space: ` - `
- Humans don't type em-dash (no keyboard key for it)

## Special Formatting Boxes

Pandoc-compatible markdown divs for visual emphasis, framed by three colons `:::`.
All box content supports full markdown - bold, lists, definition lists, links all work inside boxes.
Separate boxes from surrounding content with blank lines.

### marginbox

```markdown
::: marginbox
"Quote or key point"

**Attribution**
:::
```

Purpose: Text in the page margin, good for quotes and brief highlights. Requires wide outer margin in document layout.

### examplebox

```markdown
::: examplebox
Evidence or example content here.
:::
```

Purpose: Highlight evidence, case studies, concrete examples. Prefixed automatically with a book icon.

### widebox

```markdown
::: widebox
Important statement spanning full width.
:::
```

Purpose: Full-width coloured box with rounded border for critical points, thesis statements, key conclusions.

### textbox

```markdown
::: textbox
Short highlighted statement.
:::
```

Purpose: 60% width coloured box, text flows alongside it. For supporting information beside prose.

### recommendation

```markdown
::: recommendation
Establish a formal reserves policy targeting six months of operating expenses.
:::
```

Purpose: Auto-numbered recommendation boxes ("Recommendation 1:", "Recommendation 2:"). Counter increments across the whole document. Use for formal recommendations in reports and policy documents.

### box-policysummary

```markdown
::: box-policysummary
Summary of the policy concept and its implications for implementation.
:::
```

Purpose: Policy concept summaries. Prefixed automatically with a scales icon and "Policy concept summary" heading.

### budgetbox

```markdown
::: budgetbox
Proposed budget allocation for the initiative: €50,000 in year one.
:::
```

Purpose: Budget proposals and cost summaries. Prefixed automatically with a euro icon and "Budgetary proposal" heading.

## Code Blocks

- Use fenced code blocks: ` ```language `
- Always specify language identifier: ` ```bash `, ` ```python `, ` ```markdown `
- Blank line before and after code block

## Tables

- Use pipe format: `| item | item | item |`
- Include header row separator
- Blank line before and after table

For complex tables with coloured headers, alternating row shading, and rowspans, use
datatable syntax (see below).

## Datatables

For styled tables with coloured headers, alternating row shading, column width control,
and optional rowspans, use a fenced code block with class `datatable`.

Options appear before the `---` separator. Data rows follow it, pipe-delimited.

```markdown
    ```datatable
    columns: Phase | Actions | Deliverable
    widths: 2.5cm | X | 4.5cm
    bold: 1
    tone: medium
    ---
    Requirements | Define product context and top risks. | 1-page security context.
    Design | Maintain architecture diagram with trust boundaries. | Architecture diagram.
    Development | Build secure defaults. | CI evidence.
    ```
```

A blank leading cell continues the cell above as a rowspan:

```markdown
    ```datatable
    columns: Principle | Requirement | Notes
    widths: 3cm | 3.5cm | X
    bold: 1, 2
    tone: medium
    ---
    Trust boundaries | ANNEX-1.PT1.1 | Supports risk identification.
     | ANNEX-1.PT1.2.d | Supports access protection.
    Least privilege | ANNEX-1.PT1.2.d | Supports access limitation.
     | ANNEX-1.PT1.2.f | Supports integrity protection.
    ```
```

Datatable options:

`columns`
: Pipe-separated header labels. Omit for no header row.

`widths`
: Pipe-separated. `X` = flexible width. `Ncm` = fixed (e.g. `3.5cm`). Default all `X`.

`bold`
: Comma-separated 1-based column numbers to auto-bold (e.g. `1, 2`).

`tone`
: `grey` | `light` | `medium` (default) | `strong`. Or a number (e.g. `40`) for custom percentage.

`caption`
: Optional table caption rendered above the table.

Markdown `**bold**` in cell text is converted automatically. LaTeX special characters are escaped automatically.

## Links and Citations

### Standard Links

- Use reference-style links for readability:

```markdown
[text][ref]

[ref]: url
```

- Place reference definitions at document end

### Footnote Citations

- Use footnote format for citations:

```markdown
some point^[citation text <link>]
```

- Citations appear as endnotes when rendered
- Include full citation details in footnote text

## Dates and Numbers

- Dates in European format: DD/MM/YYYY or DD Month YYYY
- Use en-dashes for year ranges: 2020–2024

## Pandoc Compatibility

- No inline HTML - use Markdown equivalents only
- Ensure all Markdown is pandoc-parseable without additional processing
- Test complex structures are valid CommonMark/pandoc markdown

## Document Structure Best Practices

### Breaking Long Content

- Break very long definition list entries into separate paragraphs with headers
- Keep organised point-based flow
- Use prose for complex arguments
- Reserve definition format for true term definitions

### Visual Balance

- Avoid overuse of any single formatting element
- Mix prose paragraphs with structured elements (lists, boxes, definitions)
- Use special boxes sparingly for maximum impact
- Datatables suit complex multi-column reference data; standard pipe tables suit simple data

## British English Conventions

- British spelling throughout: organise, realise, favour, whilst, colour
- Single space after periods
- Quotation marks: single quotes for quotes, double for quotes within quotes

## Common Patterns to Avoid

Don't use:

```markdown
**Risk reduction**: text here
**Value optimisation**: more text

---

Some text without blank line before list
- Item one
```

Do use:

```markdown
Risk reduction
: Text here

Value optimisation
: More text

Some text with blank line before list

- Item one
```

## Checklist for Document Review

- [ ] All headers use ATX-style (`#`)
- [ ] No horizontal rules unless explicitly requested
- [ ] Bold formatting minimised (only critical emphasis)
- [ ] All term/definition pairs use definition lists
- [ ] Single space after periods
- [ ] En-dashes for ranges, space-dash-space instead of em-dashes
- [ ] Blank line before all block elements
- [ ] Blank line after titles
- [ ] Unordered lists use `-` only
- [ ] Special boxes used appropriately and sparingly
- [ ] Footnote citations use `^[text <link>]` format
- [ ] No inline HTML present
- [ ] British English spelling throughout
- [ ] Reference-style links for readability
- [ ] Language specified for all code blocks
- [ ] Datatables used for complex styled tables, pipe tables for simple data

## Examples

### Good Definition List Usage

```markdown
Traditional proprietary procurement
: Evaluate vendor (limited choice), purchase licence (significant cost), procure bundled services (single provider), accept lock to vendor (switching costs prohibitive)

Open digital procurement
: Adopt commodity software (freely available), evaluate separately, select best specialists, maintain competitive service market
```

### Good Special Box Usage

```markdown
::: widebox
Open Source powers the vast majority of digital infrastructure, yet the value chain creating this infrastructure remains excluded from financial flows.
:::

::: marginbox
"Technology is not the limiting factor"

**2018 NHS Research**
:::

::: examplebox
**Netherlands**: Ministry of Health mandating AGPL licensing for infrastructure development, achieving €15 million in successful procurement.
:::

::: recommendation
Mandate open licensing for all publicly funded digital infrastructure procurement above €50,000.
:::

::: box-policysummary
Requiring AGPL licensing for infrastructure software ensures that modifications made by vendors remain available to the commissioning authority.
:::
```

### Good Datatable Usage

```markdown
    ```datatable
    columns: Risk | Likelihood | Impact | Mitigation
    widths: X | 2.5cm | 2.5cm | X
    bold: 1
    tone: medium
    ---
    Vendor lock-in | High | High | Mandate open standards in contracts.
    Data loss | Low | Critical | Daily encrypted offsite backups.
    Staff turnover | Medium | Medium | Document all processes; cross-train teams.
    ```
```

### Good Citation Usage

```markdown
Information asymmetry between buyers and sellers causes market degradation^[Akerlof, G.A. (1970). "The Market for 'Lemons': Quality Uncertainty and the Market Mechanism", Quarterly Journal of Economics, Vol. 87, No. 3, pp. 488-500].
```

### Good Spacing and Structure

```markdown
# Main Section

Content paragraph introducing the topic.

## Subsection

More detailed content here with proper spacing.

Key point
: Definition or explanation

Another point
: Further explanation

Transitional paragraph before list.

- First list item
- Second list item
- Third list item

Concluding paragraph after list.
```

## Template Structure

```markdown
# Document Title

Brief introduction paragraph.

## First Major Section

Content with proper spacing.

Definition term
: Definition content

### Subsection

::: widebox
Critical point spanning full width
:::

Regular paragraph content.

::: examplebox
Example or evidence
:::

More content.

## Second Major Section

Continue pattern throughout.

::: marginbox
"Quote"

**Attribution**
:::

## Conclusion

Concluding content.

## References

[1]: https://example.com/source1
[2]: https://example.com/source2
```

## Notes on Maintaining Flow

- Use special boxes to break up long sections of prose
- Place marginbox quotes near relevant content
- Use widebox for thesis statements or critical conclusions
- Use textbox for brief policy statements or key findings
- Use examplebox for concrete evidence or case studies
- Use recommendation boxes for formal numbered recommendations
- Use box-policysummary for policy mechanism explanations
- Use budgetbox for cost proposals and financial summaries
- Ensure boxes don't interrupt logical argument flow
- Space boxes with blank lines like other block elements
