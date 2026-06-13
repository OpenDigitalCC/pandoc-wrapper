#!/bin/bash
#
# build-deb.sh - build a binary .deb for the pandoc-wrapper pipeline.
#
# No root required: uses `dpkg-deb --build --root-owner-group`. Output is written
# to dist/ in the repo (gitignored). Run from anywhere.
#
#   scripts/build-deb.sh [version]      # default version below

set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH="all"
PKG="pandoc-wrapper"
MAINTAINER="Stuart J Mackintosh <sjm@opendigital.cc>"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$REPO_ROOT/tmp/deb-build/${PKG}_${VERSION}"
DIST="$REPO_ROOT/dist"

rm -rf "$REPO_ROOT/tmp/deb-build"
mkdir -p "$BUILD/DEBIAN" \
         "$BUILD/usr/bin" \
         "$BUILD/usr/lib/md-to-pdf" \
         "$BUILD/usr/share/pandoc-wrapper/templates" \
         "$BUILD/usr/share/pandoc-wrapper/brands" \
         "$BUILD/usr/share/man/man1" \
         "$BUILD/usr/share/doc/$PKG"
mkdir -p "$DIST"

# --- payload ---------------------------------------------------------------
install -m 0755 "$REPO_ROOT/md-to-pdf.sh"                  "$BUILD/usr/bin/md-to-pdf"
install -m 0755 "$REPO_ROOT/scripts/extract-frontmatter.pl" "$BUILD/usr/lib/md-to-pdf/extract-frontmatter.pl"

# Templates the pipeline actually uses (not the vendored provenance copy).
for f in eisvogel-wrapper.latex mvp.latex pipeline-preamble.tex document-filters.lua conformance-test.md; do
    install -m 0644 "$REPO_ROOT/pandoc/templates/$f" "$BUILD/usr/share/pandoc-wrapper/templates/$f"
done

# Bundled default brand.
cp -r "$REPO_ROOT/pandoc/brands/plain" "$BUILD/usr/share/pandoc-wrapper/brands/plain"
find "$BUILD/usr/share/pandoc-wrapper/brands" -type f -exec chmod 0644 {} +

# Man page (gzipped, as policy expects).
install -m 0644 "$REPO_ROOT/man/md-to-pdf.1" "$BUILD/usr/share/man/man1/md-to-pdf.1"
gzip -9n "$BUILD/usr/share/man/man1/md-to-pdf.1"

# Docs + example config.
install -m 0644 "$REPO_ROOT"/pandoc/documentation/*.md "$BUILD/usr/share/doc/$PKG/" 2>/dev/null || true
cat > "$BUILD/usr/share/doc/$PKG/config.example" <<EOF
# Copy to ~/.config/pandoc-wrapper/config and edit.
# Base folder holding your brand subfolders (<name>/template.yaml + assets).
# 'plain' ships with the package; add your own brands in this folder.
brands_dir = $HOME/pandoc-brands
EOF

# --- metadata --------------------------------------------------------------
INSTALLED_KB="$(du -ks "$BUILD" | cut -f1)"

cat > "$BUILD/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: text
Priority: optional
Architecture: $ARCH
Depends: pandoc, texlive-xetex, texlive-latex-recommended, texlive-latex-extra, texlive-fonts-extra, texlive-pictures, libyaml-libyaml-perl, perl
Recommends: evince, fonts-open-sans
Maintainer: $MAINTAINER
Installed-Size: $INSTALLED_KB
Description: Markdown to branded PDF publishing pipeline
 A wrapper around Pandoc and XeLaTeX that turns Markdown with YAML front matter
 into styled, branded PDFs. Provides special boxes, styled datatables and charts
 via a Lua filter, an Eisvogel-based template plus a portable preamble, and a
 brand system (colours, fonts, logos, cover PDFs) resolved from an external
 brands folder. The default 'plain' brand ships with the package.
EOF

# Changelog (native package -> changelog.gz). Users edit their own external
# brands, not the bundled default, so nothing under /usr is a conffile.
cat > "$BUILD/usr/share/doc/$PKG/changelog" <<EOF
$PKG ($VERSION) unstable; urgency=low

  * Three-layer templates (vendored Eisvogel 3.4.0 wrapper + portable preamble).
  * Extensible YAML front-matter parsing; multirow fix.
  * External, folder-based brands resolved via config; bundled 'plain' default.

 -- $MAINTAINER  Sat, 13 Jun 2026 12:00:00 +0000
EOF
gzip -9n "$BUILD/usr/share/doc/$PKG/changelog"

# Copyright (BSD-3-Clause; Eisvogel parts BSD-3-Clause too).
cat > "$BUILD/usr/share/doc/$PKG/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: pandoc-wrapper

Files: *
Copyright: 2018-2026 Stuart J Mackintosh <sjm@opendigital.cc>
License: BSD-3-Clause

Files: usr/share/pandoc-wrapper/templates/eisvogel-wrapper.latex
Copyright: 2017-2026 Pascal Wagler; 2014-2026 John MacFarlane
License: BSD-3-Clause
 Derived from the Eisvogel pandoc LaTeX template (v3.4.0).

Files: usr/share/pandoc-wrapper/templates/mvp.latex
Copyright: 2014-2026 John MacFarlane
License: BSD-3-Clause
 Derived from the pandoc default LaTeX template (dual GPL-2+/BSD-3-Clause;
 used here under the BSD-3-Clause option).

License: BSD-3-Clause
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the conditions of the
 3-clause BSD licence are met. This software is provided "as is" without
 warranty of any kind.
EOF

# The build tree may sit under a setgid parent (/srv/projects); strip the setgid
# bit dpkg-deb rejects on the control directory (numeric chmod won't clear it
# here, so clear it symbolically).
find "$BUILD" -type d -exec chmod g-s {} +
find "$BUILD" -type d -exec chmod 0755 {} +
# Normalise file perms: the setgid environment yields group-writable (0664/0775);
# policy wants 0644 / 0755. Clearing group-write gives exactly that.
find "$BUILD" -path "$BUILD/DEBIAN" -prune -o -type f -exec chmod g-w {} +

# --- build -----------------------------------------------------------------
OUT="$DIST/${PKG}_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$BUILD" "$OUT"

echo ""
echo "Built: $OUT"
dpkg-deb --info "$OUT" | sed 's/^/  /'
echo "  --- contents ---"
dpkg-deb --contents "$OUT" | awk '{print "  "$NF}'
