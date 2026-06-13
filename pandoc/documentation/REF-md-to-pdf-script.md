# REF: md-to-pdf.sh Script Operation

Reference for operating the `md-to-pdf.sh` build script that compiles
markdown sources to PDF via pandoc and xelatex.

## Basic Usage

```bash
md-to-pdf.sh [options] <source files or directory or URL> [working directory]
```

The working directory argument is optional. Default is the current directory.
The output PDF is written there.

## Input Sources

The script accepts any combination of:

Single file:
```bash
md-to-pdf.sh document.md
```

Multiple files (concatenated in order given):
```bash
md-to-pdf.sh chapter1.md chapter2.md appendix.md
```

Directory (all `.md` and `.yaml` files gathered recursively):
```bash
md-to-pdf.sh ./my-document/
```

URL (downloaded to a temp file, TOC markers removed):
```bash
md-to-pdf.sh https://example.com/document.md
```

Mixed:
```bash
md-to-pdf.sh brand.yaml chapter1.md chapter2.md
```

## Options

`--order-alpha`
: Sort all collected input files alphabetically (dictionary order) before
  concatenation. Useful when loading a directory and relying on filename
  prefixes to control order (e.g. `01-intro.md`, `02-methods.md`).

`--debug`
: Enable debug output to stderr. Also passes `+RTS -s -RTS --log=/tmp/pandoc.log.json`
  to pandoc. Useful for diagnosing pandoc failures.

```bash
md-to-pdf.sh --order-alpha --debug ./my-document/
```

## Brand Loading

If the compiled document content contains `brand: name` in its YAML front
matter, the script loads `~/.pandoc/brands/brand-name.yaml` and prepends it
before the document content. Document YAML settings override brand defaults
because they appear later in the merged content.

If a brand-specific Lua filter exists at `~/.pandoc/brands/brand-name.lua`,
it is also loaded automatically.

## Output File Naming

The output filename is derived from the `type`, `title`, and `subtitle`
metadata fields. Non-alphanumeric characters become underscores. The filename
is capped at 80 characters.

Example: `title: "My Report"` + `subtitle: "2026 Edition"` →
`My_Report_2026_Edition.pdf`

The PDF is written to the working directory.

## Pandoc Command

The script builds and runs:

```bash
pandoc \
  --lua-filter="~/.pandoc/templates/document-filters.lua" \
  [--lua-filter="brand-specific.lua" if present] \
  --pdf-engine="xelatex" \
  --template=<from YAML or default> \
  --top-level-division=<from YAML if set> \
  --metadata=date:"<date>" \
  -f markdown+inline_notes \
  <compiled-content-file> \
  -t pdf \
  -o <output.pdf>
```

The `-f markdown+inline_notes` flag enables the `^[footnote text]` inline
footnote syntax.

## Template and Engine Resolution

`template`
: Read from `template:` or `pandoc-template:` in YAML. Resolved from
  `~/.pandoc/templates/<name>.latex`.

`pdf-engine`
: Read from `pdf-engine:` in YAML. Default is `xelatex`.

`top-level-division`
: Read from `top-level-division:` in YAML if present.

## Date Handling

`date:` in YAML is used if present. If absent, the current date at run time
is used in the format "Day DD Month YYYY".

## Error Handling

On pandoc failure, the script:

- Prints the exit code and the pandoc command used
- Points to `<tmpdir>/pandoc-stdout.txt` for the full log
- If running in an X session, opens a GUI dialog (zenity, gmessage, or
  xmessage in that preference order) showing the log content

On success, the PDF is opened with `evince` (configured in `PDF_VIEWER`).

## Configuration Constants

These are set at the top of the script and may need adjusting per installation:

`INCDIR`
: `~/.pandoc/templates` - location of Lua filter and template files

`BRANDDIR`
: `~/.pandoc/brands` - location of brand YAML and brand Lua files

`PDF_VIEWER`
: `/usr/bin/evince` - PDF viewer opened on success

`P_ENGINE`
: `xelatex` - default PDF engine (overridden by `pdf-engine:` in YAML)

## Temp Files

The script creates a temp directory via `mktemp -d`. Compiled content is
written to `<tmpdir>/<filename>-compiled.md`. Pandoc stdout/stderr goes to
`<tmpdir>/pandoc-stdout.txt`. Temp files are not cleaned up on exit (useful
for debugging).

## Typical Workflows

Single document with brand:
```bash
md-to-pdf.sh my-report.md
```

Multi-chapter book, explicit order:
```bash
md-to-pdf.sh 00-front.md 01-intro.md 02-methods.md 03-results.md
```

Multi-chapter book, directory with alpha ordering:
```bash
md-to-pdf.sh --order-alpha ./book-chapters/
```

Debug a failing build:
```bash
md-to-pdf.sh --debug my-report.md
# Then check /tmp/pandoc-stdout.txt or the GUI error dialog
```

Override brand settings on the command line (not supported directly - put
overrides in the document YAML instead, as document YAML wins over brand YAML).
