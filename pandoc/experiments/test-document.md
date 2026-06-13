---
title: "Template Feature Test Document"
subtitle: "Comprehensive Verification of Eisvogel Template"
author: "Test Author"
date: "2025-12-11"
titlepage: true
titlepage-color: "3f264f"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "32707e"
titlepage-rule-height: 4
header-left: "Template Test"
header-right: "December 2025"
footer-left: "Test Document"
footer-right: "\\thepage"
toc: true
toc-own-page: true
listings: true
tables: true
graphics: true
colorlinks: true
linkcolor: TealBlue
urlcolor: DeepPurple
geometry: "margin=2.5cm"
---

# Introduction

This document tests all major features of the reorganized Eisvogel Pandoc LaTeX template. It includes various elements to verify that the template maintains all functionality after reorganization.

## Purpose

The purpose is to ensure that:

- All sections compile correctly
- Colors are properly defined and applied
- Code listings work as expected
- Tables render correctly
- Graphics and images function properly
- Custom ODCC features work

# Typography and Formatting

## Font Styles

This paragraph contains **bold text**, *italic text*, and ***bold italic text***. We can also test `inline code` formatting.

Here's a test of different emphasis levels:

- Regular text
- *Emphasized text*
- **Strong emphasis**
- ***Strong and emphasized***

## Text Colors

The template defines several ODCC colors that should be available throughout the document. The heading colors use the DeepPurple shade, while links use TealBlue.

## Quotes and Blockquotes

> This is a standard blockquote. It should have a left border in the blockquote-border color and text in blockquote-text color.
>
> Blockquotes can span multiple paragraphs.

# Lists and Enumeration

## Unordered Lists

- First item
- Second item
  - Nested item 1
  - Nested item 2
    - Deeply nested item
- Third item

## Ordered Lists

1. First numbered item
2. Second numbered item
   1. Nested numbered item
   2. Another nested item
3. Third numbered item

## Definition Lists

Term 1
:   Definition of term 1

Term 2
:   Definition of term 2 with more detail
:   Alternative definition

# Code and Syntax Highlighting

## Inline Code

Use the `print()` function to display output in Python. Configuration files often use `key=value` pairs.

## Code Blocks

### Python Example

```python
def fibonacci(n):
    """Calculate the nth Fibonacci number."""
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)

# Test the function
for i in range(10):
    print(f"F({i}) = {fibonacci(i)}")
```

### Bash Script Example

```bash
#!/bin/bash

# System information script
echo "System Information Report"
echo "========================"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"

# Check disk usage
df -h | grep -E '^/dev/'
```

### Java Example

```java
public class HelloWorld {
    public static void main(String[] args) {
        // Print greeting
        System.out.println("Hello, World!");
        
        // Demonstrate basic types
        int number = 42;
        String text = "The answer";
        
        System.out.println(text + " is " + number);
    }
}
```

### XML Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <database>
        <host>localhost</host>
        <port>5432</port>
        <name>testdb</name>
    </database>
    <features>
        <feature name="logging" enabled="true"/>
        <feature name="caching" enabled="false"/>
    </features>
</configuration>
```

# Tables

## Simple Table

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Row 1-1  | Row 1-2  | Row 1-3  |
| Row 2-1  | Row 2-2  | Row 2-3  |
| Row 3-1  | Row 3-2  | Row 3-3  |

Table: A simple three-column table

## Complex Table with Alignment

| Left Aligned | Center Aligned | Right Aligned | Default |
|:-------------|:--------------:|--------------:|---------|
| Left         | Center         | Right         | Default |
| Text         | Text           | Text          | Text    |
| 123          | 456            | 789           | 000     |

Table: Table demonstrating different alignments

## Long Table Content

| Service | Description | Price | Status |
|---------|-------------|-------|--------|
| Web Hosting | Basic shared hosting package | $9.99/mo | Active |
| Domain Registration | .com domain registration | $12.99/yr | Active |
| Email Service | Professional email hosting | $4.99/mo | Active |
| SSL Certificate | Standard SSL/TLS certificate | $49.99/yr | Pending |
| Backup Service | Automated daily backups | $14.99/mo | Active |
| CDN Service | Content delivery network | $19.99/mo | Inactive |

Table: Service listing with multiple columns

## tabularx

\setlength{\extrarowheight}{8pt}
\renewcommand{\arraystretch}{0.8}
\begin{table}[ht]
 \centering
 % Define alternating row colors
 \rowcolors{2}{gray!10}{white} % Alternates between light gray and white rows
 \begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}lccc} 
  % Define column widths: 
  % X for flexible width, c for centered columns
  \toprule
  \rowcolor{gray!30} % Header row background color
  \textbf{Category}  &  \textbf{\% of total}  &  \textbf{€50Bn (Low estimate)}  &  \textbf{€80Bn (High estimate)} \\
  \midrule
  Software & 20–30\% & €10–€15 billion & €16–€24 billion \\
  Hardware & 20–25\% & €10–€12.5 billion & €16–€20 billion \\
  Cloud Services & 10–20\% & €5–€10 billion & €8–€16 billion \\
  Professional Services & 30–40\% & €15–€20 billion & €24–€32 billion\\
  Total & 100\% & €50 billion & €80 billion \\
  \bottomrule
 \end{tabularx}
 \caption{European public sector’s IT spending by category in euros. Source: ChatGPT summary: European public sector IT spend by category in €.}
 \label{tab:styled-table}
\end{table}


# Mathematics

## Inline Math

The quadratic formula is $x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$ and Euler's identity states that $e^{i\pi} + 1 = 0$.

## Display Math

The Gaussian integral:

$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$

Matrix representation:

$$\begin{bmatrix}
a & b \\
c & d
\end{bmatrix}
\begin{bmatrix}
x \\
y
\end{bmatrix}
=
\begin{bmatrix}
ax + by \\
cx + dy
\end{bmatrix}$$

# Links and References

## External Links

- Visit [Pandoc's website](https://pandoc.org) for more information
- The [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template) on GitHub
- Reference documentation at [LaTeX Project](https://www.latex-project.org)

## Internal References

This document has sections that can be referenced (if you set up labels).

# Special Characters

Testing various special characters that work with pdflatex:

- Accented characters: café, résumé, naïve
- Currency: dollar sign, cents
- Common symbols: copyright, registered trademark
- Math operators: plus, minus, times, divide
- Comparison: less than, greater than, equal

For full Unicode support (Greek letters, arrows, etc.), use XeLaTeX or LuaLaTeX.

# Footnotes and Citations

This is a sentence with a footnote.[^1] Here's another one with more detail.[^2]

[^1]: This is the first footnote with some explanation.

[^2]: This second footnote can contain more complex content, including **formatted text** and even `code`.

# Nested Structures

## Lists with Code

1. First step: Install the package
   ```bash
   sudo apt-get install pandoc
   ```

2. Second step: Create your markdown file
   - Use proper formatting
   - Include metadata in YAML front matter

3. Third step: Convert to PDF
   ```bash
   pandoc input.md -o output.pdf --template eisvogel
   ```

## Tables with Formatting

| Feature | Status | Notes |
|---------|:------:|-------|
| **Bold** | [x] | Fully supported |
| *Italic* | [x] | Works correctly |
| `Code` | [x] | Inline formatting |

# Page Breaks and Layout

\newpage

# New Section After Page Break

This section appears after a manual page break, testing the layout and header/footer functionality.

## Subsection Content

More content to verify that pagination works correctly throughout the document.

# Conclusion

This test document exercises the major features of the reorganized Eisvogel template:

- Color definitions (ODCC palette)
- Typography and fonts
- Code listings (multiple languages)
- Tables (simple and complex)
- Mathematics (inline and display)
- Lists (ordered, unordered, nested)
- Links and references
- Special characters (ASCII compatible)
- Page layout and breaks
- Headers and footers
- Title page customization

The reorganized template should maintain all functionality while being more maintainable.

# Appendix: Technical Details

## Color Palette Reference

The ODCC color palette includes:

- **DeepPurple** (RGB: 0.247, 0.149, 0.310)
- **TealBlue** (RGB: 0.196, 0.439, 0.494)
- **WarmGray** (RGB: 0.776, 0.776, 0.773)
- **DarkGray** (RGB: 0.235, 0.235, 0.231)

## Template Sections

The reorganized template is divided into logical sections:

1. Document Class and Basic Options
2. Color Definitions
3. Geometry and Page Layout
4. Footnotes
5. Section Numbering
6. Fonts and Typography
7. Mathematics
8. Graphics and Images
9. Tables
10. Code Listings
11. Text Formatting
12. Language Support
13. Citations and Bibliography
14. Hyperlinks
15. Captions
16. Blockquotes
17. Page Style
18. Title Page
19. Headers and Footers
20. ODCC Customizations

## Compilation Notes

This document is designed to work with both pdflatex and xelatex:

- **pdflatex**: Fast compilation, limited Unicode support
- **xelatex**: Full Unicode support, slightly slower

For production documents with international characters or special symbols, use xelatex:

```bash
pandoc input.md -o output.pdf --template=eisvogel --pdf-engine=xelatex
```
