#!/bin/sh
# Update the-ultimate-gitignore-ai's managed block inside a project's .gitignore.
#
#   ./update.sh                 # updates ./.gitignore
#   ./update.sh path/to/project # updates path/to/project/.gitignore
#   ./update.sh some/other.gitignore
#
# Everything OUTSIDE the >>> :START / <<< :END markers is yours and is preserved byte-for-byte.
# A file with no markers is never rewritten in place - the block is appended below your rules.
#
# Fails closed: a failed download, an empty download, or a download without the markers changes
# nothing. Set GITIGNORE_URL to update from a fork or a local file.
set -eu

URL="${GITIGNORE_URL:-https://raw.githubusercontent.com/vikichand/the-ultimate-gitignore-ai/main/ultimate.gitignore}"
START='# >>> the-ultimate-gitignore-ai:START'
END='# <<< the-ultimate-gitignore-ai:END'

TARGET="${1:-.gitignore}"
if [ -d "$TARGET" ]; then TARGET="${TARGET%/}/.gitignore"; fi

tmp=$(mktemp) || exit 2
trap 'rm -f "$tmp" "$tmp.new"' EXIT

# A local path is allowed so you can test a fork, or update from a clone with no network.
if [ -f "$URL" ]; then
  cat "$URL" > "$tmp"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$tmp" || { echo "  ! download failed ($URL) - nothing changed."; exit 2; }
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$URL" || { echo "  ! download failed ($URL) - nothing changed."; exit 2; }
else
  echo "  ! need curl or wget to fetch $URL - nothing changed."; exit 2
fi

# Prove we fetched the real file before it is allowed to overwrite anything: a captive-portal HTML
# page, a 404 body, or a truncated transfer all fail here instead of landing in your .gitignore.
[ -s "$tmp" ] || { echo "  ! downloaded file is empty - nothing changed."; exit 2; }
grep -qF "$START" "$tmp" || { echo "  ! downloaded file has no managed-block marker - not the gitignore. Nothing changed."; exit 2; }
grep -qF "$END"   "$tmp" || { echo "  ! downloaded file is missing its END marker (truncated?). Nothing changed."; exit 2; }

if [ ! -e "$TARGET" ]; then
  cp "$tmp" "$TARGET"
  echo "  + created $TARGET"
  exit 0
fi

if grep -qF "$START" "$TARGET" && grep -qF "$END" "$TARGET"; then
  # Replace the managed region only. Pass 1 buffers the new block; pass 2 copies the target through,
  # swapping the old region for it. Your rules above and below the markers are untouched.
  awk -v s="$START" -v e="$END" '
    NR==FNR { if (index($0,s)==1) c=1
              if (c) blk = blk $0 ORS
              if (index($0,e)==1) c=0
              next }
    index($0,s)==1 { skip=1; printf "%s", blk }
    !skip { print }
    index($0,e)==1 { skip=0 }
  ' "$tmp" "$TARGET" > "$tmp.new"
  [ -s "$tmp.new" ] || { echo "  ! rewrite produced an empty file - aborted, nothing changed."; exit 2; }
  if cmp -s "$tmp.new" "$TARGET"; then
    echo "  = $TARGET already has the current block - nothing to do."
  else
    cat "$tmp.new" > "$TARGET"
    echo "  + updated the managed block in $TARGET (your own rules kept)"
  fi
else
  # No markers: this is a hand-written .gitignore, or a copy taken before markers existed. Appending
  # is the only safe move - rewriting it in place would silently delete rules we cannot identify.
  printf '\n' >> "$TARGET"
  cat "$tmp" >> "$TARGET"
  echo "  + appended the managed block to $TARGET (your existing rules kept above it)"
  echo "    If your old copy of this file is still up there, delete those lines - they are now duplicated."
fi

echo "  Then check nothing tracked is now ignored:  git ls-files -i -c --exclude-standard"
