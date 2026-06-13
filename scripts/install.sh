#!/bin/bash
#
# install.sh - install the pandoc-wrapper pipeline (md-to-pdf) for the current
# user or system-wide. No network access; pure file copy.
#
# Layout (FHS-style, identical shape for user and system so the wrapper finds
# its own assets relatively, with no environment variables):
#
#   <prefix>/bin/md-to-pdf                      the driver
#   <prefix>/lib/md-to-pdf/extract-frontmatter.pl   YAML helper
#   <prefix>/share/pandoc-wrapper/templates/    *.latex *.tex *.lua
#   <prefix>/share/pandoc-wrapper/brands/       *.yaml
#
#   user   (default): prefix = ~/.local
#   system          : prefix = /usr/local   (override with --prefix DIR)
#
# Usage:
#   scripts/install.sh                 # user install into ~/.local
#   scripts/install.sh --system        # system install into /usr/local
#   scripts/install.sh --prefix /opt/pandoc-wrapper
#   scripts/install.sh --uninstall [--system|--prefix DIR]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=install
PREFIX="$HOME/.local"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)    PREFIX="/usr/local" ;;
        --prefix)    PREFIX="${2:?--prefix needs a directory}"; shift ;;
        --user)      PREFIX="$HOME/.local" ;;
        --uninstall) MODE=uninstall ;;
        -h|--help)   sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *)           echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib/md-to-pdf"
SHAREDIR="$PREFIX/share/pandoc-wrapper"

if [[ "$MODE" == uninstall ]]; then
    echo "Uninstalling from $PREFIX"
    rm -f  "$BINDIR/md-to-pdf"
    rm -rf "$LIBDIR" "$SHAREDIR"
    echo "Done. (Per-user ~/.pandoc assets, if any, were left untouched.)"
    exit 0
fi

echo "Installing pandoc-wrapper into $PREFIX"

install -d "$BINDIR" "$LIBDIR" "$SHAREDIR/templates" "$SHAREDIR/brands"

# Driver
install -m 0755 "$REPO_ROOT/md-to-pdf.sh" "$BINDIR/md-to-pdf"

# Helper
install -m 0755 "$REPO_ROOT/scripts/extract-frontmatter.pl" "$LIBDIR/extract-frontmatter.pl"

# Assets: templates (LaTeX templates, shared preamble, Lua filter) and brands
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.latex "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.tex   "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.lua   "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/brands/*.yaml      "$SHAREDIR/brands/"    2>/dev/null || true

echo "Installed:"
echo "  driver : $BINDIR/md-to-pdf"
echo "  helper : $LIBDIR/extract-frontmatter.pl"
echo "  assets : $SHAREDIR/{templates,brands}"

# PATH hint for user installs
case ":$PATH:" in
    *":$BINDIR:"*) : ;;
    *) echo ""
       echo "Note: $BINDIR is not on your PATH. Add it, e.g.:"
       echo "  echo 'export PATH=\"$BINDIR:\$PATH\"' >> ~/.bashrc" ;;
esac

echo ""
echo "Try: md-to-pdf --no-viewer your-document.md"
