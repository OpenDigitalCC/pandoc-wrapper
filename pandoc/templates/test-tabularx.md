---
title: "Tabularx Feature Test"
subtitle: "Testing tabularx support in reorganized template"
author: "Test Author"
date: "2025-12-11"
titlepage: true
titlepage-color: "3f264f"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "32707e"
header-left: "Tabularx Test"
header-right: "December 2025"
footer-left: "Test Document"
footer-right: "\\thepage"
toc: false
listings: false
tables: true
colorlinks: true
geometry: "margin=2.5cm"
header-includes:
  - |
    ```{=latex}
    % Define custom column types for tabularx
    \newcolumntype{L}{>{\raggedright\arraybackslash}X}
    \newcolumntype{C}{>{\centering\arraybackslash}X}
    \newcolumntype{R}{>{\raggedleft\arraybackslash}X}
    ```
---

# Introduction

This document demonstrates the use of `tabularx` package which is now included in the reorganized template.

# Standard Pandoc Tables

These work as before:

| Service | Description | Price |
|---------|-------------|-------|
| Hosting | Web hosting | $9.99 |
| Domain | Domain registration | $12.99 |
| Email | Email service | $4.99 |

# Using tabularx Directly

You can use tabularx in your documents by including raw LaTeX blocks:

```{=latex}
\begin{table}[h]
\caption{Example tabularx table with flexible columns}
\begin{tabularx}{\textwidth}{lLr}
\toprule
Short & Long Description Column (auto-wraps) & Price \\
\midrule
Service 1 & This is a long description that will automatically wrap to fill the available space in the column. The X column type expands to use available width. & \$99.99 \\
Service 2 & Another long description demonstrating how tabularx handles text wrapping automatically without manual intervention. & \$149.99 \\
Service 3 & Yet another description showing the flexibility of the tabularx package for creating professional-looking tables. & \$199.99 \\
\bottomrule
\end{tabularx}
\end{table}
```

# Benefits of tabularx

The `tabularx` package provides:

- **Automatic width calculation**: The `X` column type expands to fill available space
- **Better text wrapping**: Long content wraps automatically
- **Flexible layouts**: Mix fixed and flexible columns
- **Professional appearance**: Works well with booktabs package

## Custom Column Types

With the custom column types defined in the header, you can use:

- `L` - Left-aligned flexible column
- `C` - Center-aligned flexible column  
- `R` - Right-aligned flexible column
- `X` - Default flexible column (left-aligned)

```{=latex}
\begin{table}[h]
\caption{Using custom column types}
\begin{tabularx}{\textwidth}{|L|C|R|}
\hline
Left Aligned & Center Aligned & Right Aligned \\
\hline
This text is left-aligned and will wrap in the available space & This text is centered and wraps & This text is right-aligned \\
\hline
Short & Medium length text & Long \\
\hline
\end{tabularx}
\end{table}
```

# Mixed Column Types

You can mix fixed-width and flexible columns:

```{=latex}
\begin{table}[h]
\caption{Mixed fixed and flexible columns}
\begin{tabularx}{\textwidth}{lcXr}
\toprule
ID & Code & Description & Amount \\
\midrule
1 & ABC & This is a flexible column that will expand to use available space and wrap text as needed & 1,234.56 \\
2 & DEF & Another flexible description column demonstrating automatic width adjustment & 2,345.67 \\
3 & GHI & The ID, Code, and Amount columns are fixed width while Description flexes & 3,456.78 \\
\bottomrule
\end{tabularx}
\end{table}
```

# Conclusion

The reorganized template now includes `tabularx` support, allowing you to create more flexible and professional tables in your documents. You can use it directly in LaTeX blocks or extend pandoc's markdown to leverage it.
