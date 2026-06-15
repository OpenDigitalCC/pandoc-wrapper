---
title: "MVP Template Conformance Test"
subtitle: "Boxes, datatables, charts, citations"
documentclass: scrartcl
toc: true
brand-colours:
  accent: "2980B9"
  accent-light: "D6EAF5"
  steel: "5D6D7E"
  light: "F2F4F5"
  charcoal: "2C3E50"
  slate: "85929E"
  silver: "AEB6BF"
chart-colours:
  - charcoal
  - accent
  - steel
  - slate
  - silver
box-colours:
  frame-info: steel!80
  bg-info: light!50
  frame-accent: accent!80
  bg-accent: accent-light!20
  frame-highlight: charcoal!80
  bg-highlight: light!40
  frame-contrast: slate!80
  bg-contrast: light!30
---

# Headings and prose

A paragraph of body text to confirm basic flow renders.

Term
: A definition list entry, to confirm definition lists work.

## A datatable with a row span

```datatable
columns: Group | Item | Notes
widths: 3cm | X | X
bold: 1
tone: medium
---
Operations | Administration, compliance, accounts | shared label
 | Networking | spans down
 | Storage | spans down
Software | Licences | annual
```

## Boxes

::: widebox
A full-width box for a key statement.
:::

::: recommendation
Adopt a portable template contract so brands stop coupling to one template.
:::

::: examplebox
A worked example sits here, prefixed by an icon.
:::

::: textbox
A right-floating text box (wrapfigure), prefixed by an info icon.
:::

::: budgetbox
A budgetary proposal box, prefixed by a currency icon.
:::

::: marginbox
A margin note - exercises \marginnote and \checkoddpage so a missing package
fails the conformance render here, not in a user document.
:::

## Charts

```piechart
caption: Allocation
style: medium
postfix: \%
Delivery: 62
Admin: 18
Reserves: 20
```

```barchart
caption: Income by source
axis: H
prefix: £
Grants: 142000
Contracts: 87000
Donations: 23000
```

A claim needing a citation^[Example, A. (2026). A Source. Journal, 1(1), 1-2.].
