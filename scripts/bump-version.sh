#!/bin/bash
#
# bump-version.sh - the single place that changes the project version.
#
# Writes the new version to the VERSION file (the single source of truth) and
# stamps the copies that must carry a literal: SCRIPT_VERSION in the driver and
# the .TH line of the man page. The SBOM reads VERSION directly, so it needs no
# stamping.
#
#   scripts/bump-version.sh             # bump minor (X.Y.Z -> X.(Y+1).0)
#   scripts/bump-version.sh major       # X.Y.Z -> (X+1).0.0
#   scripts/bump-version.sh minor       # X.Y.Z -> X.(Y+1).0
#   scripts/bump-version.sh patch       # X.Y.Z -> X.Y.(Z+1)
#   scripts/bump-version.sh 2.3.4        # set an exact version
#
# Prints the new version to stdout.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VFILE="$REPO_ROOT/VERSION"

cur="$(tr -d '[:space:]' < "$VFILE")"
IFS='.' read -r M m p <<<"$cur"

arg="${1:-minor}"
case "$arg" in
    major) new="$((M + 1)).0.0" ;;
    minor) new="$M.$((m + 1)).0" ;;
    patch) new="$M.$m.$((p + 1))" ;;
    [0-9]*.[0-9]*.[0-9]*) new="$arg" ;;
    *) echo "usage: bump-version.sh [major|minor|patch|X.Y.Z]" >&2; exit 2 ;;
esac

printf '%s\n' "$new" > "$VFILE"

# Stamp the shipped literals from the new version.
sed -i "s/^SCRIPT_VERSION=.*/SCRIPT_VERSION=\"$new\"/" "$REPO_ROOT/md-to-pdf.sh"
sed -i "s/pandoc-wrapper [0-9][0-9.]*/pandoc-wrapper $new/" "$REPO_ROOT/man/md-to-pdf.1"

echo "$cur -> $new" >&2
printf '%s\n' "$new"
