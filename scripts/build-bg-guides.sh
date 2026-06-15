#!/bin/bash
#
# build-bg-guides.sh - build the background safe-area guide PDFs.
#
# For each template (except letter, which has no background use), produces a PDF
# in pandoc/documentation/bg-guides/ showing the page(s) with light hatching over
# the zones the template fills with content. A designer making a background image
# uses it as a mask layer: keep focal points in the clear (un-hatched) areas.
# The PDFs live with the documentation (committed) so they are available without
# rebuilding.
#
#   scripts/build-bg-guides.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/tools/bg-guides"
OUT="$REPO_ROOT/pandoc/documentation/bg-guides"
WORK="$REPO_ROOT/tmp/bg-guides"

rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"

status=0
for g in featured report slides beamer; do
    src="$SRC/$g.tex"
    [[ -f "$src" ]] || { echo "  $g: no source"; continue; }
    # Two passes: the guides use remember-picture/current-page anchors.
    if ( cd "$SRC" && xelatex -interaction=nonstopmode -halt-on-error -output-directory="$WORK" "$g.tex" >/dev/null 2>&1 \
         && xelatex -interaction=nonstopmode -halt-on-error -output-directory="$WORK" "$g.tex" >/dev/null 2>&1 ); then
        cp "$WORK/$g.pdf" "$OUT/$g-background-guide.pdf"
        printf '  %-10s -> pandoc/documentation/bg-guides/%s-background-guide.pdf\n' "$g" "$g"
    else
        printf '  %-10s FAIL (see %s/%s.log)\n' "$g" "$WORK" "$g"
        status=1
    fi
done

[[ $status -eq 0 ]] && echo "background guides: built." || echo "background guides: at least one failed." >&2
exit $status
