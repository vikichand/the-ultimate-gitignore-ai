#!/usr/bin/env bash
#
# verify.sh — prove ultimate.gitignore does what it claims.
#
# Builds a throwaway git repo, materialises every path listed in
# tests/must-be-ignored.txt and tests/must-be-tracked.txt, then asks
# `git check-ignore` about each one.
#
# The must-be-tracked half is the half that matters. It catches greedy
# patterns like *.bin, *.key and models/ that silently drop your source.
#
# Usage:  ./verify.sh [path/to/ultimate.gitignore]
# Exit:   0 all assertions passed, 1 otherwise.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/ultimate.gitignore}"
IGNORE_LIST="$HERE/tests/must-be-ignored.txt"
TRACK_LIST="$HERE/tests/must-be-tracked.txt"

for f in "$TARGET" "$IGNORE_LIST" "$TRACK_LIST"; do
  [ -r "$f" ] || { echo "verify: cannot read $f" >&2; exit 1; }
done

# Neutralise the user's global and system git config. Claude Code writes
# `**/.claude/settings.local.json` into ~/.config/git/ignore, which would make
# this suite pass for the wrong reason on a developer machine.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git init -q "$WORK"
cp "$TARGET" "$WORK/.gitignore"

# [[:space:]] rather than \s, and a read loop rather than mapfile: macOS ships
# bash 3.2 and BSD grep, so neither `mapfile` nor `\s` is available there.
read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

MUST_IGNORE=()
while IFS= read -r line; do MUST_IGNORE+=("$line"); done < <(read_list "$IGNORE_LIST")
MUST_TRACK=()
while IFS= read -r line; do MUST_TRACK+=("$line"); done < <(read_list "$TRACK_LIST")

# Guard against a vacuous pass: a truncated fixture file must fail loudly, not
# report "PASS — 0 assertions". (This also sidesteps bash 3.2's unbound-variable
# abort when expanding an empty array under `set -u`.)
if [ "${#MUST_IGNORE[@]}" -lt 1 ] || [ "${#MUST_TRACK[@]}" -lt 1 ]; then
  echo "verify: a fixture list is empty — refusing to pass vacuously" >&2
  exit 1
fi

cd "$WORK" || exit 1
for p in "${MUST_IGNORE[@]}" "${MUST_TRACK[@]}"; do
  mkdir -p "$(dirname "$p")" && : > "$p"
done

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

misses=0
false_positives=0
git_errors=0

# git check-ignore exit codes: 0 = a pattern matched, 1 = no pattern matched,
# anything else = git itself failed. The error case must be counted, not
# swallowed — otherwise a broken repo makes every assertion "pass".

for p in "${MUST_IGNORE[@]}"; do
  git check-ignore -q -- "$p"
  rc=$?
  if [ "$rc" -eq 1 ]; then
    red "  MISS            $p"
    red "                  expected to be ignored, but no pattern matched"
    misses=$((misses + 1))
  elif [ "$rc" -gt 1 ]; then
    red "  GIT ERROR       $p (exit $rc)"
    git_errors=$((git_errors + 1))
  fi
done

for p in "${MUST_TRACK[@]}"; do
  out="$(git check-ignore -v -- "$p" 2>&1)"
  rc=$?
  [ "$rc" -eq 1 ] && continue
  if [ "$rc" -gt 1 ]; then
    red "  GIT ERROR       $p (exit $rc): $out"
    git_errors=$((git_errors + 1))
    continue
  fi
  # check-ignore -v also reports negation matches. A leading '!' on the pattern
  # means the file is explicitly re-included, which is the correct outcome.
  case "$out" in
    *:'!'*) continue ;;
  esac
  red "  FALSE POSITIVE  $p"
  red "                  $out"
  false_positives=$((false_positives + 1))
done

# Dead-pattern scan, two shapes:
#   1. Git only honours '#' at the start of a line, so a trailing comment
#      silently becomes part of the pattern and the rule matches nothing.
#   2. Leading whitespace is also part of the pattern (git strips trailing
#      spaces, never leading), so an indented rule is equally dead.
dead="$(grep -nE '^[^#[:space:]].*[[:space:]]#|^[[:space:]]+[^[:space:]]' .gitignore || true)"
dead_count=0
if [ -n "$dead" ]; then
  red "  DEAD PATTERNS   comments/whitespace have become part of the pattern:"
  printf '%s\n' "$dead" | sed 's/^/                  /'
  dead_count="$(printf '%s\n' "$dead" | wc -l | tr -d ' ')"
fi

total=$(( ${#MUST_IGNORE[@]} + ${#MUST_TRACK[@]} ))
failures=$(( misses + false_positives + dead_count + git_errors ))

echo
echo "  must be ignored   ${#MUST_IGNORE[@]} paths, $misses missed"
echo "  must be tracked   ${#MUST_TRACK[@]} paths, $false_positives wrongly ignored"
echo "  dead patterns     $dead_count"
if [ "$git_errors" -gt 0 ]; then
  echo "  git errors        $git_errors"
fi
echo "  ------------------------------------------"

if [ "$failures" -eq 0 ]; then
  green "  PASS — $total assertions"
  exit 0
fi

red "  FAIL — $failures problem(s) across $total assertions"
exit 1
