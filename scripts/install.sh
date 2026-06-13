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
# BRANDS. The 'plain' brand ships WITH the tool as the bundled default
# (<prefix>/share/pandoc-wrapper/brands) and is the always-available fallback
# (and the reference to copy). Your organisation brands live OUTSIDE the tool,
# in an external base
# of brand subfolders (<name>/template.yaml + assets) that you manage separately
# (e.g. its own repo). The installer creates that base and points the config at
# it; you populate it with your brands.
#   brands base : ~/.local/share/pandoc-wrapper/brands  (user)  -- or --brands-dir
#   config      : ~/.config/pandoc-wrapper/config  (brands_dir = ...)
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

install -d "$BINDIR" "$LIBDIR" "$SHAREDIR/templates" "$SHAREDIR/brands"

# Driver
install -m 0755 "$REPO_ROOT/md-to-pdf.sh" "$BINDIR/md-to-pdf"

# Helper
install -m 0755 "$REPO_ROOT/scripts/extract-frontmatter.pl" "$LIBDIR/extract-frontmatter.pl"

# Templates (LaTeX templates, shared preamble, Lua filter)
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.latex "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.tex   "$SHAREDIR/templates/" 2>/dev/null || true
install -m 0644 "$REPO_ROOT"/pandoc/templates/*.lua   "$SHAREDIR/templates/" 2>/dev/null || true

# The bundled default brand (plain) ships WITH the tool as the always-available
# fallback (and copy-me reference). Organisation brands are NOT bundled - they
# live in the external brands base, managed separately.
for bdir in "$REPO_ROOT"/pandoc/brands/*/; do
    [[ -d "$bdir" ]] || continue
    cp -r "$bdir" "$SHAREDIR/brands/$(basename "$bdir")"
done

# Ensure the external brands base exists (the user fills it with their brands,
# e.g. by cloning their brands repo) and point the config at it.
install -d "$BRANDS_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
    install -d "$CONFIG_DIR"
    {
        echo "# pandoc-wrapper configuration"
        echo "# Base folder holding your brand subfolders (<name>/template.yaml + assets)."
        echo "# 'plain' ships with the tool as the default; add your own brands here."
        echo "brands_dir = $BRANDS_DIR"
    } > "$CONFIG_FILE"
    echo "  wrote config: $CONFIG_FILE"
else
    echo "  config exists: $CONFIG_FILE (left as is)"
fi

echo "Installed:"
echo "  driver   : $BINDIR/md-to-pdf"
echo "  helper   : $LIBDIR/extract-frontmatter.pl"
echo "  templates: $SHAREDIR/templates"
echo "  default  : $SHAREDIR/brands (plain)"
echo "  brands   : $BRANDS_DIR (your brands - add them here)"

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
