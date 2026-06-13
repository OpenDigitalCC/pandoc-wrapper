# REF: Template YAML Field Reference

Complete reference for YAML front matter fields supported by
`eisvogel-reorganized.latex`. Fields can appear in document front matter
or in brand YAML files. Document fields override brand defaults.

## Document Metadata

```yaml
title: "Document Title"
subtitle: "Document Subtitle"
author: "Author Name"
date: "January 2026"
institute: "Organisation Name"
subject: "Document Subject"
keywords: [keyword1, keyword2]
lang: en-GB
```

## Document Structure

```yaml
book: true                        # Enable book features
documentclass: scrbook            # scrbook | scrartcl | scrreprt
top-level-division: chapter       # chapter | section | part
classoption:
  - oneside                       # oneside | twoside
  - openright                     # openright | openany (twoside only)
```

With `top-level-division: chapter`: `#` = chapter, `##` = section.
With `top-level-division: section`: `#` = section, `##` = subsection.

## Page Layout

```yaml
papersize: a4                     # a4 | a5 | letter | legal

# Simple margins
margin-left: 2cm
margin-right: 5cm
margin-top: 2cm
margin-bottom: 1.5cm

# Or geometry package syntax
geometry:
  - inner=2cm
  - outer=5cm
  - top=2cm
  - bottom=3cm

fontsize: 11pt                    # 10pt | 11pt | 12pt | 14pt
linestretch: 1.2
mainfont: "Open Sans"
```

Wide `margin-right` (5cm) is needed for marginbox and margin-style charts.
Use `twoside` + `geometry` with `inner`/`outer` for print documents where
the binding side alternates.

## Title Page

```yaml
titlepage: true

# Optional assets
titlepage-background: Graphics/background.pdf
titlepage-logo: Graphics/logo.png
logo-width: 50mm

# Colours - raw hex or brand-colours names (resolved by document-filters.lua)
titlepage-color: "3B7A9E"         # Background colour
titlepage-text-color: "FFFFFF"    # Text colour
titlepage-rule-color: "E08A52"    # Decorative rule colour
titlepage-rule-height: 4          # Rule thickness in pt
```

Alternative - insert a pre-designed PDF as the cover page instead:

```yaml
titlepage: false
cover-pdf: Graphics/frontcover.pdf
```

## Back Cover

```yaml
backpage: true
backpage-title: "About This Book"           # Optional heading
backpage-text: |
  Description text.
  Multiple paragraphs supported.
backpage-publisher: "Publisher Name"
backpage-address: "City, Country"
backpage-website: "www.example.com"
backpage-isbn: "978-1-234567-89-0"
backpage-copyright: "© 2026 Publisher."
backpage-background: Graphics/back.pdf      # Optional
backpage-color: "E8E8E8"                    # Optional background colour
```

Text anchors at bottom. Horizontal line above publisher info. Inherits
titlepage styling if colour fields not set.

## Headers and Footers

```yaml
header-left: "Left text"
header-center: "Centre text"
header-right: ""               # Empty string suppresses default (date)

footer-left: "CONFIDENTIAL"
footer-center: "Project Name"
footer-right: ""               # Empty = page numbers (default behaviour)
```

Defaults when not set: `header-left` = title, `header-right` = date,
`footer-left` = author, `footer-right` = page number.

Empty string `""` suppresses the default. Omitting the field keeps the default.

Headers and footers extend into the margin area. Chapter pages use the same
style as regular pages.

## Table of Contents

```yaml
toc: true
toc-depth: 2                   # 0-5 levels
toc-own-page: true             # TOC on its own page
toc-compact: true              # Tighter spacing for large documents
```

`toc-depth` values: 0 = titles only, 1 = chapters, 2 = chapters + sections,
3 = + subsections, and so on.

### Chapter Mini TOC

```yaml
minitoc: true
minitoc-depth: 2               # 1 = sections, 2 = sections + subsections
minitoc-title: ""              # Empty = no title (default). Or: "In This Chapter"
```

Add `\minitoc` in the document body immediately after a chapter heading to
place a mini TOC there. Only chapters with `\minitoc` get one.

Recommended pattern: `toc-depth: 1` (chapters only in main TOC) +
`minitoc-depth: 2` (sections in chapter TOCs).

## Section Numbering

```yaml
numbersections: true
secnumdepth: 2                 # How many levels to number
```

With chapters: `secnumdepth: 1` → 1, 1.1; `secnumdepth: 2` → 1, 1.1, 1.1.1.

## Typography

```yaml
mainfont: "Open Sans"          # System font name
fontsize: 11pt
linestretch: 1.2
```

Coloured headings via `header-includes` (use `brand-colours` names if defined):

```yaml
header-includes: |
  \addtokomafont{chapter}{\color{my-blue}}
  \addtokomafont{section}{\color{my-blue}}
  \addtokomafont{subsection}{\color{my-steel}}
  \addtokomafont{subsubsection}{\color{my-slate}}
```

## Print Features

```yaml
printready: true               # Add crop marks for professional printing
```

When `true`: L-shaped corner marks at all corners, 1cm bleed area,
page count automatically rounded up to a multiple of 4 (required for
folded signatures). When `false`: no crop marks, no blank pages added.

## Code and Syntax Highlighting

```yaml
listings: true
highlight-style: tango         # tango | pygments | kate | monochrome |
                               # espresso | zenburn | haddock | breezedark
listings-disable-line-numbers: false
```

## Endnotes

```yaml
footnotes-as-endnotes: true
endnotes-heading: "References"
endnotes-custom-heading: true
endnotes-symmetric-margins: true   # 2cm symmetric margins for the endnotes section
```

Endnotes chapter appears in the TOC automatically. Only rendered if the
document has footnotes. See REF-document-authoring.md for footnote syntax.

## Bibliography

```yaml
bibliography: references.bib
biblio-title: "Bibliography"
```

## Colours and Links

```yaml
colorlinks: true
linkcolor: blue
urlcolor: blue
toccolor: black
```

Template colour fields (`titlepage-color`, `titlepage-text-color`,
`titlepage-rule-color`, `page-background-color`, `header-color`,
`footer-color`) accept raw hex values or `brand-colours` names, resolved by
`document-filters.lua`. See REF-brand-yaml.md.

## Template Engine Fields

```yaml
template: eisvogel-reorganized
pdf-engine: xelatex
from: markdown-smart
```

These are typically set in the brand YAML, not per document.

## Image Defaults

```yaml
float-placement-figure: H      # LaTeX float placement for figures
```

The template sets `\setkeys{Gin}{width=1\textwidth,keepaspectratio}` so all
images default to full text width. Override per image with `{ width=50% }`.

## Custom Boxes (pandoc-latex-environment)

```yaml
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]
  marginbox: [marginbox]
  examplebox: [examplebox]
  widebox: [widebox]
  textbox: [textbox]
```

The `marginbox`, `examplebox`, `widebox`, and `textbox` entries are processed
by `document-filters.lua`. The `note`, `tip`, `warning`, `caution`,
`important` entries are processed by the `pandoc-latex-environment` pandoc
filter (separate tool, must be installed independently).

## Troubleshooting Reference

Missing fonts
: Install system-wide or fall back to `mainfont: "Liberation Sans"`.

Crop marks not showing
: Requires `printready: true`, XeLaTeX, and a PDF viewer not cropping to
  content area.

Headers/footers missing
: Setting a field to `""` suppresses the default. Omit the field entirely
  to keep the default, or set actual content.

Chapter pages different style
: Add to `header-includes`:
  `\renewcommand*{\chapterpagestyle}{eisvogel-header-footer}`

TOC too narrow
: Template auto-widens TOC. If still an issue, check margin settings.

Datatable X columns too wide/narrow
: Set `textwidth: 14` in the datatable options for wide-margin templates
  (default assumption is 17cm for A4 with 2cm margins).
