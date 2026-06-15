#!/bin/bash
#
# conformance.sh - render the conformance fixture through each document template.
#
# conformance-test.md exercises every feature the Lua filter emits (all box
# types, datatables with row spans, charts, citations). Rendering it through a
# template proves that template + the portable preamble carry every package the
# filter's output needs. A missing package (e.g. marginnote/changepage for
# ::: marginbox) fails here instead of in a user's document.
#
# Scope: the document-style templates that share document-filters.lua and the
# portable preamble - eisvogel-wrapper, mvp, letter. The slide formats use a
# different content pipeline (beamer writer / slides.lua) and a deck-shaped
# fixture, so they are out of scope for this feature-coverage check.
#
#   scripts/conformance.sh            # render all; non-zero exit if any fail
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$REPO_ROOT/pandoc/templates/conformance-test.md"
WORK="$REPO_ROOT/tmp/conformance"
DRIVER="$REPO_ROOT/md-to-pdf.sh"

# Bundled 'plain' resolves even with no external brands base, but be explicit.
export MD_TO_PDF_BRANDS="${MD_TO_PDF_BRANDS:-$REPO_ROOT/pandoc/brands}"

# Templates to exercise. eisvogel-wrapper selects its class from book:/chapter
# (it ignores documentclass), so it needs those set the way a report brand does;
# mvp and letter render the fixture's scrartcl front matter as-is.
TEMPLATES=(eisvogel-wrapper mvp letter)

# Per-template front-matter injected after the opening '---' (newline-separated).
prep_for() {
    case "$1" in
        eisvogel-wrapper) printf 'template: eisvogel-wrapper\nbook: true\ntop-level-division: chapter' ;;
        *)                printf 'template: %s' "$1" ;;
    esac
}

rm -rf "$WORK"
mkdir -p "$WORK"

status=0
for t in "${TEMPLATES[@]}"; do
    src="$WORK/conf-$t.md"
    log="$WORK/conf-$t.log"
    # Build the source: opening '---', the template's front-matter lines, then
    # the rest of the fixture (its own front matter + body).
    {
        head -n 1 "$FIXTURE"
        prep_for "$t"
        printf '\n'
        tail -n +2 "$FIXTURE"
    } > "$src"
    if bash "$DRIVER" --no-viewer "$src" > "$log" 2>&1; then
        printf '  %-18s PASS\n' "$t"
    else
        printf '  %-18s FAIL  (see %s)\n' "$t" "$log"
        grep -iE 'undefined|! |\.sty|error' "$log" | head -3 | sed 's/^/      /'
        status=1
    fi
done

if [[ $status -eq 0 ]]; then
    echo "conformance: all templates rendered the full feature set."
else
    echo "conformance: at least one template failed (see logs above)." >&2
fi
exit $status
