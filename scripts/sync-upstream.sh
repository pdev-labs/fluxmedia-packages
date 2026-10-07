#!/usr/bin/env bash
# Sync packaging to the latest upstream FluxMedia release.
#
# Usage:
#   scripts/sync-upstream.sh [--check] [--version X.Y.Z]
#
#   --check    exit 0 if packaging is current, 1 if an update is available
#              (no files changed). Prints versions to stdout.
#   --version  bump to an explicit version instead of querying GitHub/PyPI.
#
# Default (no flags): query upstream, bump PKGBUILD + .SRCINFO +
# fluxmedia.spec + debian/changelog + README if a newer release exists.
#
# Files updated on a bump:
#   PKGBUILD            pkgver=, pkgrel=1, sha256sums[0]=
#   .SRCINFO            regenerated via `makepkg --printsrcinfo`
#   fluxmedia.spec      Version:, Release: reset, %changelog entry
#   debian/changelog    new stanza on top
#   README.md           "Upstream version packaged: **X.Y.Z**" + install snippets
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_REPO="pdev-labs/FluxMedia"

CHECK_ONLY=0
PIN_VERSION=""

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1; shift ;;
    --version) PIN_VERSION="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

current_version() {
  grep -E '^pkgver=' "$REPO_DIR/PKGBUILD" | cut -d= -f2
}

latest_upstream_version() {
  if [ -n "$PIN_VERSION" ]; then
    echo "$PIN_VERSION"
    return 0
  fi
  local tag=""
  # 1. GitHub releases API (prefers stable, skips drafts/prereleases via jq-less parsing)
  tag="$(curl -fsSL --max-time 30 "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" \
    | grep -E '"tag_name":' | head -1 | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"
  # 2. PyPI fallback
  if [ -z "$tag" ]; then
    tag="$(curl -fsSL --max-time 30 https://pypi.org/pypi/fluxmedia/json \
      | grep -E '"version":' | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/' || true)"
  fi
  echo "$tag"
}

CURRENT="$(current_version)"
LATEST="$(latest_upstream_version)"

if [ -z "$LATEST" ]; then
  echo "ERROR: could not determine latest upstream version (network/API failure)" >&2
  exit 3
fi

echo "packaged: $CURRENT"
echo "upstream: $LATEST"

# Compare with sort -V (1.18.0 vs 1.9.5 handled correctly)
newer="$(printf '%s\n%s\n' "$CURRENT" "$LATEST" | sort -V | tail -1)"
if [ "$newer" = "$CURRENT" ] && [ "$CURRENT" = "$LATEST" ]; then
  echo "Up to date."
  exit 0
fi
if [ "$newer" = "$CURRENT" ]; then
  echo "Packaged version ($CURRENT) is newer than upstream ($LATEST); nothing to do."
  exit 0
fi

echo "Update available: $CURRENT -> $LATEST"

if [ "$CHECK_ONLY" = 1 ]; then
  exit 1
fi

TARBALL_URL="https://github.com/${UPSTREAM_REPO}/archive/refs/tags/v${LATEST}.tar.gz"
echo "Fetching $TARBALL_URL for sha256..."
SHA="$(curl -fsSL --max-time 120 "$TARBALL_URL" | sha256sum | cut -d' ' -f1)"
if [ -z "$SHA" ] || [ "${#SHA}" -ne 64 ]; then
  echo "ERROR: failed to compute sha256 for $TARBALL_URL" >&2
  exit 4
fi
echo "sha256: $SHA"

# --- PKGBUILD ---
sed -i -E "s/^pkgver=.*/pkgver=${LATEST}/" "$REPO_DIR/PKGBUILD"
sed -i -E "s/^pkgrel=.*/pkgrel=1/" "$REPO_DIR/PKGBUILD"
# Replace first sha256sums entry (the upstream tarball; local files stay SKIP).
# Handles both one-line and multi-line sha256sums arrays.
python3 - "$REPO_DIR/PKGBUILD" "$SHA" <<'EOF'
import re, sys
path, sha = sys.argv[1], sys.argv[2]
text = open(path).read()
pat = re.compile(r"(sha256sums=\()['\"]?[0-9a-f]{64}['\"]?", re.IGNORECASE)
new, n = pat.subn(r"\1'" + sha + "'", text, count=1)
if n != 1:
    # fallback: single-line form sha256sums=('...')
    pat2 = re.compile(r"sha256sums=\('[^']*'")
    new, n = pat2.subn("sha256sums=('" + sha + "'", text, count=1)
assert n == 1, "could not locate tarball sha256 in PKGBUILD"
open(path, "w").write(new)
print("PKGBUILD sha256 updated")
EOF

# --- .SRCINFO ---
if command -v makepkg >/dev/null 2>&1; then
  (cd "$REPO_DIR" && makepkg --printsrcinfo > .SRCINFO)
  echo ".SRCINFO regenerated"
else
  # Minimal fallback when makepkg is unavailable (e.g. CI container without base-devel):
  # patch pkgver + tarball sha in place.
  sed -i -E "s/^\tpkgver = .*/\tpkgver = ${LATEST}/" "$REPO_DIR/.SRCINFO"
  python3 - "$REPO_DIR/.SRCINFO" "$SHA" <<'EOF'
import re, sys
path, sha = sys.argv[1], sys.argv[2]
lines = open(path).read().splitlines(keepends=True)
done = False
for i, l in enumerate(lines):
    if not done and l.strip().startswith("sha256sums = ") and "SKIP" not in l:
        lines[i] = re.sub(r"sha256sums = \S+", f"sha256sums = {sha}", l)
        done = True
        break
assert done, "sha256 entry not found in .SRCINFO"
open(path, "w").write("".join(lines))
print(".SRCINFO patched (makepkg not available)")
EOF
fi

# --- fluxmedia.spec ---
sed -i -E "s/^Version:.*/Version:        ${LATEST}/" "$REPO_DIR/fluxmedia.spec"
sed -i -E "s/^Release:.*/Release:        1%{?dist}/" "$REPO_DIR/fluxmedia.spec"
sed -i -E "s|^# SHA256: .*|# SHA256: ${SHA}|" "$REPO_DIR/fluxmedia.spec"
DATE="$(date '+%a %b %d %Y')"
CHANGELOG_ENTRY="* ${DATE} pdev-labs <https://github.com/pdev-labs> - ${LATEST}-1\n- Auto-sync to upstream v${LATEST}.\n"
# Insert after %changelog line
python3 - "$REPO_DIR/fluxmedia.spec" "$CHANGELOG_ENTRY" <<'EOF'
import sys
path, entry = sys.argv[1], sys.argv[2].replace("\\n", "\n")
text = open(path).read()
assert "%changelog" in text
text = text.replace("%changelog\n", "%changelog\n" + entry, 1)
open(path, "w").write(text)
print("spec changelog updated")
EOF

# --- debian/changelog ---
DEB_DATE="$(date -R)"
DEB_ENTRY="fluxmedia (${LATEST}-1) unstable; urgency=medium\n\n  * Auto-sync to upstream v${LATEST}.\n\n -- pdev-labs <https://github.com/pdev-labs>  ${DEB_DATE}\n\n"
printf "%b%s" "$DEB_ENTRY" "$(cat "$REPO_DIR/debian/changelog")" > "$REPO_DIR/debian/changelog"
echo "debian/changelog updated"

# --- README.md ---
sed -i -E "s/Upstream version packaged: \*\*[0-9.]+\*\*/Upstream version packaged: **${LATEST}**/" "$REPO_DIR/README.md"
sed -i -E "s/fluxmedia_1[0-9.]+\.[0-9.]+-1_all\.deb/fluxmedia_${LATEST}-1_all.deb/" "$REPO_DIR/README.md"
sed -i -E "s|FluxMedia-1[0-9.]+\.tar\.gz|FluxMedia-${LATEST}.tar.gz|g" "$REPO_DIR/README.md"
sed -i -E "s|FluxMedia-1[0-9.]+/debian|FluxMedia-${LATEST}/debian|; s|cd FluxMedia-1[0-9.]+|cd FluxMedia-${LATEST}|" "$REPO_DIR/README.md"
sed -i -E "s/fluxmedia-1[0-9.]+\.[0-9.]+-1\*/fluxmedia-${LATEST}-1*/" "$REPO_DIR/README.md"
echo "README.md updated"

echo ""
echo "Bumped to $LATEST. Changed files:"
(cd "$REPO_DIR" && git status --porcelain || true)
