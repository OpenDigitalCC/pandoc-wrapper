#!/bin/bash
#
# install.sh - install the pandoc-wrapper pipeline (md-to-pdf) for the current
# user or system-wide. No network access; pure file copy.
#
# The TOOL (FHS-style under <prefix>):
#   <prefix>/bin/md-to-pdf                          the driver
#   <prefix>/lib/md-to-pdf/extract-frontmatter.pl   YAML helper
#   <prefix>/share/pandoc-wrapper/templates/        *.latex *.tex *.lua
#
#   user   (default): prefix = ~/.local
#   system          : prefix = /usr/local   (override with --prefix DIR)
#
# BRANDS are user data and live OUTSIDE the tool, in a base folder of brand
# subfolders (<name>/template.yaml + assets). The installer seeds it from the
# bundled defaults (without overwriting your edits) and points the config at it:
#   brands base : ~/.local/share/pandoc-wrapper/brands  (user)  -- or --brands-dir
#   config      : ~/.config/pandoc-wrapper/config  (brands_dir = ...)
# Manage brands there, or in your own folder/repo, independent of the tool.
#
# Usage:
#   scripts/install.sh                 # user install into ~/.local
#   scripts/install.sh --system        # system install into /usr/local
#   scripts/install.sh --prefix /opt/pandoc-wrapper
#   scripts/install.sh --brands-dir ~/Nextcloud/brands   # external brands base
#   scripts/install.sh --uninstall [--system|--prefix DIR]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=install
PREFIX="$HOME/.local"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)    PREFIX="/usr/local" ;;
        --prefix)    PREFIX="${2:?--prefix needs a directory}"; shift ;;
        --user)       PREFIX="$HOME/.local" ;;
        --brands-dir) BRANDS_DIR="${2:?--brands-dir needs a directory}"; shift ;;
        --uninstall)  MODE=uninstall ;;
        -h|--help)    sed -n '2,32p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *)            echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib/md-to-pdf"
SHAREDIR="$PREFIX/share/pandoc-wrapper"

# Brands are user data and live OUTSIDE the tool. Default to an XDG data dir for
# user installs (writable, user-managed), or co-located for system installs.
# Override with --brands-dir.
if [[ -z "${BRANDS_DIR:-}" ]]; then
    if [[ "$PREFIX" == "$HOME"* ]]; then
        BRANDS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pandoc-wrapper/brands"
    else
        BRANDS_DIR="$SHAREDIR/brands"
    fi
fi
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pandoc-wrapper"
CONFIG_FILE="$CONFIG_DIR/config"

if [[ "$MODE" == uninstall ]]; then
    echo "Uninstalling tool from $PREFIX"
    rm -f  "$BINDIR/md-to-pdf"
    rm -rf "$LIBDIR" "$SHAREDIR"
    echo "Done. Brands at $BRANDS_DIR and the config file were left untouched."
    exit 0
fi

echo "Installing pandoc-wrapper into $PREFIX"

install -d "$BINDIR" "$LIBDIR" "$SHAREDIR/templates"

# Driver
install -m 0755 "$REPO_ROOT/md-to-pdf.sh" "$BINDIR/md-to-pdf"

# Helper
install -m 0755 "$REPO_ROOT/scripts/extract-frontmatter.pl" "$LIBDIR/extract-frontmatter.pl"

# Templates (LaTeX templates, shared preamble, Lua filter)
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.latex "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.tex   "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.lua   "$SHAREDIR/templates/" 2>/dev/null || true

# Brands: seed the external brands base from the bundled default set, WITHOUT
# overwriting any brand the user has already customised. Each brand is a folder.
install -d "$BRANDS_DIR"
seeded=0
for bdir in "$REPO_ROOT"/pandoc/brands/*/; do
    [[ -d "$bdir" ]] || continue
    name="$(basename "$bdir")"
    if [[ -e "$BRANDS_DIR/$name" ]]; then
        echo "  brand '$name' exists - left as is"
    else
        cp -r "$bdir" "$BRANDS_DIR/$name"
        seeded=$((seeded + 1))
    fi
done

# Write a config pointing at the brands base, if one does not already exist.
if [[ ! -f "$CONFIG_FILE" ]]; then
    install -d "$CONFIG_DIR"
    {
        echo "# pandoc-wrapper configuration"
        echo "# Base folder holding brand subfolders (<name>/template.yaml + assets)."
        echo "brands_dir = $BRANDS_DIR"
    } > "$CONFIG_FILE"
    echo "  wrote config: $CONFIG_FILE"
else
    echo "  config exists: $CONFIG_FILE (left as is)"
fi

echo "Installed:"
echo "  driver : $BINDIR/md-to-pdf"
echo "  helper : $LIBDIR/extract-frontmatter.pl"
echo "  templates: $SHAREDIR/templates"
echo "  brands : $BRANDS_DIR (seeded $seeded new)"

# PATH hint for user installs
case ":$PATH:" in
    *":$BINDIR:"*) : ;;
    *) echo ""
       echo "Note: $BINDIR is not on your PATH. Add it, e.g.:"
       echo "  echo 'export PATH=\"$BINDIR:\$PATH\"' >> ~/.bashrc" ;;
esac

echo ""
echo "Brands live in $BRANDS_DIR - manage them there (or point brands_dir"
echo "in $CONFIG_FILE at your own folder/repo)."
echo "Try: md-to-pdf --no-viewer your-document.md"
