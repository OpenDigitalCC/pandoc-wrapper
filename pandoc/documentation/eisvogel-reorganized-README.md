# Eisvogel Template - Enhanced Edition

A professional LaTeX template for Pandoc that creates high-quality PDF documents with extensive customization options. Based on the Eisvogel template with significant enhancements for book publishing, margin notes, print-ready output, and brand consistency.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Document Structure](#document-structure)
- [Covers and Pages](#covers-and-pages)
- [Page Layout](#page-layout)
- [Headers and Footers](#headers-and-footers)
- [Table of Contents](#table-of-contents)
- [Typography and Styling](#typography-and-styling)
- [Margin Notes](#margin-notes)
- [Print-Ready Features](#print-ready-features)
- [Code and Syntax Highlighting](#code-and-syntax-highlighting)
- [Custom Boxes](#custom-boxes)
- [Endnotes and References](#endnotes-and-references)
- [Brand Configuration](#brand-configuration)
- [Complete YAML Reference](#complete-yaml-reference)

## Overview

This template is designed for professional document production including:
- Technical documentation
- Books and reports
- Academic papers
- Policy documents
- Business proposals

Optimized for XeLaTeX with full Unicode support.

## Features

### Document Types
- **Books** with chapters (scrbook class)
- **Reports** with sections (scrartcl class)
- **Twoside/oneside** layouts for print or digital
- **Custom page sizes** (A4, A5, Letter, custom)

### Professional Output
- Print-ready PDFs with crop marks
- Symmetric margins for digital, asymmetric for print
- Wide outer margins for margin notes
- Custom front and back covers
- Consistent branding across documents

### Enhanced Typography
- Multiple font options (OpenSans, SourceSans, etc.)
- Colored section headings
- Customizable title pages
- Professional headers and footers
- Extended TOC width
- Chapter-level mini TOCs

### Special Features
- Margin notes and quotes
- Custom colored boxes
- Code syntax highlighting
- Endnotes support
- Automatic page numbering
- Print binding support (page count divisible by 4)

## Installation

### Prerequisites
- Pandoc 2.0 or later
- XeLaTeX (from TeX Live or MiKTeX)
- Required LaTeX packages (install via your TeX distribution)

### Template Installation

Place the template file where Pandoc can find it:

```bash
# Linux/Mac
mkdir -p ~/.pandoc/templates
cp eisvogel-reorganized.latex ~/.pandoc/templates/

# Windows
mkdir %APPDATA%\pandoc\templates
copy eisvogel-reorganized.latex %APPDATA%\pandoc\templates\
```

### Skills Installation (Optional)

For advanced document types, install the skills:

```bash
# Copy skills to pandoc data directory
cp -r skills ~/.pandoc/
```

## Basic Usage

### Minimal Document

```yaml
---
title: "Document Title"
author: "Your Name"
date: "2025-01-15"
---

# Chapter 1

Your content here.
```

Compile with:

```bash
pandoc document.md -o output.pdf \
  --template=eisvogel-reorganized \
  --pdf-engine=xelatex
```

### Book with All Features

```yaml
---
title: "Professional Book Title"
subtitle: "A Comprehensive Guide"
author: "Author Name"
date: "January 2025"
institute: "Your Organization"

# Document structure
book: true
documentclass: scrbook
top-level-division: chapter

# Page layout
classoption:
  - twoside
margin-left: 2cm
margin-right: 5cm
fontsize: 11pt

# Title page
titlepage: true
titlepage-background: Graphics/cover.pdf
titlepage-logo: Graphics/logo.png

# Table of contents
toc: true
toc-depth: 2
toc-own-page: true

# Section numbering
numbersections: true
secnumdepth: 2

# Headers and footers
header-left: ""
header-center: ""
header-right: ""
footer-left: "CONFIDENTIAL"
footer-center: "Project Name"
footer-right: ""

# Back cover
backpage: true
backpage-text: |
  Book description and key points.
  Multiple paragraphs supported.
backpage-publisher: "Publisher Name"
backpage-website: "www.example.com"
backpage-isbn: "978-1-234567-89-0"

# Print settings
printready: false  # Set true for crop marks
---

# Introduction

Your content starts here.
```

## Document Structure

### Document Classes

**For books with chapters:**
```yaml
book: true
documentclass: scrbook
top-level-division: chapter
```

**For articles with sections:**
```yaml
documentclass: scrartcl
top-level-division: section
```

### Markdown Heading Levels

With `top-level-division: chapter`:
- `#` → Chapter
- `##` → Section
- `###` → Subsection
- `####` → Subsubsection

With `top-level-division: section`:
- `#` → Section
- `##` → Subsection
- `###` → Subsubsection

## Covers and Pages

### Custom PDF Cover

Use a pre-designed PDF as your cover:

```yaml
titlepage: false
cover-pdf: Graphics/frontcover.pdf
```

The PDF will be inserted as page 1 before all other content.

### Template-Generated Title Page

```yaml
titlepage: true
titlepage-background: Graphics/background.pdf  # Optional
titlepage-logo: Graphics/logo.png              # Optional
logo-width: 50mm                                # Optional

# Styling
titlepage-color: "3F264F"                       # Hex color
titlepage-text-color: "FFFFFF"                  # Text color
titlepage-rule-color: "435488"                  # Decorative line
titlepage-rule-height: 4                        # Line thickness (pt)

title: "Your Title"
subtitle: "Your Subtitle"
author: "Author Name"
date: "Date"
institute: "Organization"
```

### Back Cover Page

```yaml
backpage: true
backpage-title: "About This Book"              # Optional
backpage-text: |
  Description of the book content.
  Key takeaways and target audience.
  
backpage-publisher: "Publisher Name"
backpage-address: "City, Country"
backpage-website: "www.example.com"
backpage-isbn: "978-1-234567-89-0"
backpage-copyright: "© 2025 Publisher. All rights reserved."

# Styling (inherits from titlepage if not set)
backpage-background: Graphics/backcover.pdf    # Optional
backpage-color: "E8E8E8"                       # Optional
```

**Layout:** Text anchors at bottom, horizontal line above publisher info, matches titlepage styling.

## Page Layout

### Margins

**Symmetric (for digital/screen):**
```yaml
classoption:
  - oneside
margin-left: 2.5cm
margin-right: 2.5cm
margin-top: 2cm
margin-bottom: 3cm
```

**Asymmetric (for print/binding):**
```yaml
classoption:
  - twoside
geometry:
  - inner=2cm      # Binding side
  - outer=5cm      # Outer edge (for margin notes)
  - top=2cm
  - bottom=3cm
```

Or using simple margins:
```yaml
margin-left: 2cm
margin-right: 5cm
```

### Paper Size

```yaml
# Standard sizes
papersize: a4      # or a5, letter, legal

# Custom size
geometry:
  - paperwidth=210mm
  - paperheight=297mm
```

### Font Size

```yaml
fontsize: 11pt     # Options: 10pt, 11pt, 12pt, 14pt
```

### Fonts

```yaml
mainfont: "Open Sans"
# Options: Open Sans, Source Sans Pro, Liberation Sans, etc.
```

## Headers and Footers

Headers and footers extend into the margin area for better visual balance.

```yaml
# Headers (top of page)
header-left: "Left Header"
header-center: "Center Header"
header-right: "Right Header"

# Footers (bottom of page)
footer-left: "CONFIDENTIAL"
footer-center: "Project Name"
footer-right: ""  # Empty = page numbers (default)

# Empty string suppresses default content
header-right: ""  # Removes date
```

**Defaults if not set:**
- `header-left`: title (suppressed if empty)
- `header-right`: date (suppressed if empty)
- `footer-left`: author (suppressed if empty)
- `footer-right`: page number (always shown unless explicitly set)

**Chapter pages** use the same header/footer style as regular pages.

## Table of Contents

```yaml
toc: true
toc-depth: 2           # How many levels to show (0-5)
toc-own-page: true     # TOC on separate page
toc-compact: true      # Compact spacing for large documents (optional)
```

The TOC automatically uses wider margins (symmetric 2cm) for better layout, then restores your document margins afterward.

**TOC Depth Levels:**
- `0`: No entries (titles only)
- `1`: Chapters only
- `2`: Chapters + Sections
- `3`: Chapters + Sections + Subsections

**Compact TOC:**
For large documents with many entries, enable compact spacing to fit more on one page:

```yaml
toc-compact: true
```

This reduces spacing above/below the TOC heading and between entries. Leave unset or set to `false` for standard spacing in shorter documents.

### Chapter-Level Table of Contents (MiniTOC)

Add per-chapter mini tables of contents showing sections within each chapter:

```yaml
minitoc: true
minitoc-depth: 2           # 1=sections only, 2=sections+subsections
minitoc-title: "Contents"  # Optional custom title (empty to suppress)
```

**Features:**
- No title by default (clean appearance)
- No leader dots between entries and page numbers
- Automatic depth control
- Selective placement (only where `\minitoc` is added)

**Usage in markdown:**

```markdown
# Chapter 1: Introduction

\minitoc

This chapter covers...

## Section 1.1
## Section 1.2

# Chapter 2: Methods

No mini TOC in this chapter

## Section 2.1
```

**Best practice:**
```yaml
toc-depth: 1        # Main TOC: chapters only
minitoc-depth: 2    # Chapter TOCs: sections + subsections
```

**When to use:**
- Long chapters with 5+ sections
- Reference books with detailed hierarchies
- Self-contained chapters
- Only add `\minitoc` where needed (selective control)

**Styling notes:**
- MiniTOC has no title by default for clean appearance
- Leader dots are removed automatically
- Uses small font size for compact display
- To add a title: `minitoc-title: "In This Chapter"`

## Typography and Styling

### Section Numbering

```yaml
numbersections: true
secnumdepth: 2        # How deep to number (0-5)
```

**With chapters:**
- `secnumdepth: 1` → 1, 1.1
- `secnumdepth: 2` → 1, 1.1, 1.1.1
- `secnumdepth: 3` → 1, 1.1, 1.1.1, 1.1.1.1

### Colored Headings

Add to your brand YAML or document header-includes:

```yaml
header-includes: |
  \addtokomafont{chapter}{\color{DeepPurple}}
  \addtokomafont{section}{\color{TealBlue}}
  \addtokomafont{subsection}{\color{TealBlue}}
  \addtokomafont{subsubsection}{\color{DarkGray}}
```

Colors available: DeepPurple, TealBlue, DarkGray, or define your own with `\definecolor`.

### Line Spacing

```yaml
linestretch: 1.2      # Default
# Options: 1.0 (single), 1.5, 2.0 (double)
```

### Lists

```yaml
# Compact lists
listings-disable-line-numbers: true

# Code blocks
listings: true
```

## Margin Notes

Wide outer margins (5cm) support margin notes and quotes.

### Margin Note

```markdown
\marginnote{This is a note in the margin that provides additional context.}
```

### Margin Quote Box

```markdown
\marginquote{Quote text here}{Attribution}
```

Creates a colored box in the margin with the quote and attribution.

**Requirements:**
- Set `margin-right: 5cm` or similar wide margin
- Uses `twoside` for proper placement

## Print-Ready Features

### Crop Marks

Add printer's crop marks for professional printing:

```yaml
printready: true
```

**Features:**
- L-shaped corner marks at all four corners
- 1cm bleed area on all sides
- Works with any paper size
- Automatic page positioning

**For different paper sizes:**
```yaml
printready: true
papersize: a5
```

### Page Count for Binding

When `printready: true`, documents automatically adjust page count to be divisible by 4 (required for folded signatures in book printing).

**How it works:**
- Backpage is placed on an even page number (4, 8, 12, 16...)
- Blank pages are added as needed before the backpage
- Total page count is always a multiple of 4

When `printready: false`, no blank pages are added.

### Twoside vs Oneside

**Print version:**
```yaml
printready: true
classoption:
  - twoside
```

**Digital version:**
```yaml
printready: false
classoption:
  - oneside
```

## Code and Syntax Highlighting

### Inline Code

Use backticks: `code here`

### Code Blocks

````markdown
```python
def hello():
    print("Hello, world!")
```
````

### Syntax Highlighting

```yaml
listings: true
highlight-style: tango
# Options: tango, pygments, kate, monochrome, espresso, zenburn, haddock, breezedark
```

### Line Numbers

```yaml
listings-disable-line-numbers: false  # Enable line numbers
```

## Custom Boxes

The template supports colored notification boxes:

```markdown
::: note
This is a note with important information.
:::

::: tip
This is a helpful tip.
:::

::: warning
This is a warning message.
:::

::: caution
This requires caution.
:::

::: important
This is critically important.
:::
```

Enable in YAML:
```yaml
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]
```

## Endnotes and References

### Convert Footnotes to Endnotes

```yaml
footnotes-as-endnotes: true
endnotes-heading: "References"
endnotes-custom-heading: true
endnotes-symmetric-margins: true  # Use 2cm margins for endnotes section
```

**Features:**
- Automatic "References" chapter in TOC
- Only appears if document has endnotes
- Symmetric margins for better readability
- Customizable heading text

### Bibliography

```yaml
bibliography: references.bib
biblio-title: "Bibliography"
```

## Brand Configuration

Create reusable brand configurations for consistent styling across documents.

### Brand YAML File (brand-odcc.yaml)

```yaml
---
# Brand identity
institute: "Your Organization"
subject: "Organization Documents"

# Template
template: eisvogel-reorganized
pdf-engine: xelatex

# Document structure
book: true
documentclass: scrbook
top-level-division: chapter

# Title page
titlepage: true
titlepage-background: /path/to/cover.pdf

# Typography
mainfont: "Open Sans"
fontsize: 11pt

# Page layout
classoption:
  - twoside
margin-left: 2cm
margin-right: 5cm
margin-top: 2cm
margin-bottom: 3cm

# Headers and footers
header-center: ""
header-left: ""
header-right: ""
footer-left: "CONFIDENTIAL"
footer-center: ""

# Styling
colorlinks: true
footnotes-pretty: true

# Endnotes
endnotes-heading: "References"
footnotes-as-endnotes: true
endnotes-custom-heading: true
endnotes-symmetric-margins: true

# TOC
toc-depth: 2
numbersections: true
secnumdepth: 2

# Colors and styling
header-includes: |
  \usepackage{fontawesome5}
  \addtokomafont{chapter}{\color{DeepPurple}}
  \addtokomafont{section}{\color{TealBlue}}
  \addtokomafont{subsection}{\color{TealBlue}}
  \addtokomafont{subsubsection}{\color{DarkGray}}
---
```

### Using Brand Configuration

**Per document:**
```yaml
---
title: "Document Title"
author: "Author"
brand: odcc  # References brand-odcc.yaml
---
```

**Command line:**
```bash
pandoc document.md brand-odcc.yaml -o output.pdf
```

**Override brand settings:**
```yaml
---
title: "Special Document"
brand: odcc
fontsize: 14pt        # Override brand default
printready: true      # Add print features
---
```

## Complete YAML Reference

### Document Metadata

```yaml
title: "Document Title"
subtitle: "Document Subtitle"
author: "Author Name"
date: "2025-01-15"
institute: "Organization Name"
subject: "Document Subject"
keywords: [keyword1, keyword2]
lang: en-US
```

### Document Structure

```yaml
book: true                        # Enable book features
documentclass: scrbook            # scrbook, scrartcl, scrreprt
top-level-division: chapter       # chapter, section, part
classoption:
  - twoside                       # twoside, oneside
  - openright                     # openright, openany
```

### Page Layout

```yaml
papersize: a4                     # a4, a5, letter, legal
fontsize: 11pt                    # 10pt, 11pt, 12pt, 14pt
mainfont: "Open Sans"
linestretch: 1.2

margin-left: 2cm
margin-right: 5cm
margin-top: 2cm
margin-bottom: 3cm

# Or use geometry
geometry:
  - inner=2cm
  - outer=5cm
  - top=2cm
  - bottom=3cm
```

### Title Page

```yaml
titlepage: true
titlepage-background: Graphics/bg.pdf
titlepage-logo: Graphics/logo.png
logo-width: 50mm
titlepage-color: "3F264F"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "435488"
titlepage-rule-height: 4
```

### Cover Pages

```yaml
# Custom PDF cover
titlepage: false
cover-pdf: Graphics/cover.pdf

# Back cover
backpage: true
backpage-title: "About"
backpage-text: |
  Description text
backpage-publisher: "Publisher"
backpage-address: "Address"
backpage-website: "www.example.com"
backpage-isbn: "978-1-234567-89-0"
backpage-copyright: "© 2025"
backpage-background: Graphics/back.pdf
backpage-color: "E8E8E8"
```

### Headers and Footers

```yaml
header-left: "Text"
header-center: "Text"
header-right: ""               # Empty to suppress
footer-left: "Text"
footer-center: "Text"
footer-right: ""               # Empty = page numbers
```

### Table of Contents

```yaml
toc: true
toc-depth: 2                   # 0-5
toc-own-page: true
toc-compact: true              # Compact spacing for large documents

# Chapter-level TOCs
minitoc: true
minitoc-depth: 2               # 1-3 (sections to show in chapter TOCs)
minitoc-title: ""              # Empty (default) or custom title
```

### Section Numbering

```yaml
numbersections: true
secnumdepth: 2                 # 0-5
```

### Print Features

```yaml
printready: true               # Add crop marks
```

### Endnotes

```yaml
footnotes-as-endnotes: true
endnotes-heading: "References"
endnotes-custom-heading: true
endnotes-symmetric-margins: true
```

### Code Highlighting

```yaml
listings: true
highlight-style: tango
listings-disable-line-numbers: false
```

### Colors and Styling

```yaml
colorlinks: true
linkcolor: blue
urlcolor: blue
toccolor: black

header-includes: |
  \usepackage{package-name}
  \definecolor{CustomColor}{HTML}{3F264F}
  \addtokomafont{chapter}{\color{CustomColor}}
```

### Custom Boxes

```yaml
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]
```

## Workflow Examples

### Digital Document Workflow

```yaml
---
title: "Digital Report"
classoption:
  - oneside
margin-left: 2.5cm
margin-right: 2.5cm
printready: false
titlepage: false
cover-pdf: Graphics/cover-digital.pdf
---
```

### Print Document Workflow

```yaml
---
title: "Print Book"
classoption:
  - twoside
margin-left: 2cm
margin-right: 5cm
printready: true
titlepage: true
titlepage-background: Graphics/cover-print.pdf
backpage: true
backpage-publisher: "Publisher"
---
```

### Brand-Based Workflow

Create brand YAML, then per-document:

```bash
# Digital version
pandoc doc.md brand-odcc.yaml \
  --variable printready=false \
  --variable classoption=oneside \
  -o output-digital.pdf

# Print version
pandoc doc.md brand-odcc.yaml \
  --variable printready=true \
  --variable classoption=twoside \
  -o output-print.pdf
```

## Troubleshooting

### Missing Fonts

If fonts aren't found, install them system-wide or use Liberation Sans as fallback:

```yaml
mainfont: "Liberation Sans"
```

### Crop Marks Not Showing

Ensure you have:
1. `printready: true` in YAML
2. PDF viewer showing full page (not cropped view)
3. XeLaTeX as PDF engine

### TOC Too Narrow

The template automatically widens TOC. If issues persist, check your margin settings.

### Headers/Footers Missing

Ensure you're not setting them to empty strings unintentionally. Remove the variable entirely or set actual content.

### Chapter Pages Different Style

This should be fixed in the template. If issues persist, add to header-includes:

```yaml
header-includes: |
  \renewcommand*{\chapterpagestyle}{eisvogel-header-footer}
```

## License

Based on the Eisvogel template by Pascal Wagler and John MacFarlane.

Enhanced edition with additional features for professional publishing.

## Credits

- Original Eisvogel template: Pascal Wagler, John MacFarlane
- KOMA-Script: Markus Kohm
- Pandoc: John MacFarlane

## Support

For issues with the base Eisvogel template, see: https://github.com/Wandmalfarbe/pandoc-latex-template

For issues with enhancements, refer to your local documentation or support channels.
