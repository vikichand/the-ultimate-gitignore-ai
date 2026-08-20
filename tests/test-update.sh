#!/bin/sh
# Assertions for update.sh. It edits a file people keep their own rules in, so every path that
# writes - and every path that must refuse to write - is exercised here. Runs offline: GITIGNORE_URL
# points at a local file, the same override a fork would use.
#
# SC2015 (`A && pass || bad` is not if-then-else): here it is safe and deliberate - `pass` ends in a
# printf and always returns 0, so the `|| bad` branch cannot fire after a successful assertion.
# SC1007 (`CDPATH= cd`): a deliberate prefix assignment that stops a user's CDPATH from making `cd`
# print and jump elsewhere. Same idiom as verify.sh and the-agent-kit's installer.
# shellcheck disable=SC2015,SC1007
set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0
pass() { printf 'PASS: %s\n' "$1"; }
bad()  { printf 'FAIL: %s\n' "$1"; fail=1; }

w=$(mktemp -d) || exit 2
trap 'rm -rf "$w"' EXIT
cd "$w" || exit 2

# A stand-in "new upstream": the real file with one added pattern, so an update is detectable.
sed 's|^# <<< the-ultimate-gitignore-ai:END|NEWLY-ADDED-PATTERN/\n# <<< the-ultimate-gitignore-ai:END|' \
  "$ROOT/ultimate.gitignore" > "$w/upstream.gitignore"
grep -q 'NEWLY-ADDED-PATTERN' "$w/upstream.gitignore" || { echo "setup failed"; exit 2; }
up() { GITIGNORE_URL="$w/upstream.gitignore" sh "$ROOT/update.sh" "$@"; }

# T1 no file yet -> create it
rm -f .gitignore
up >/dev/null 2>&1 || bad "T1 exited non-zero"
grep -q 'NEWLY-ADDED-PATTERN' .gitignore && pass "T1 created a missing .gitignore" || bad "T1 file not created"

# T2 the common case: markers present, and the user has their own rules on BOTH sides
{ printf 'my-secret-dir/\n\n'; cat "$ROOT/ultimate.gitignore"; printf '\nmy-trailing-rule/\n'; } > .gitignore
up >/dev/null 2>&1 || bad "T2 exited non-zero"
grep -q 'NEWLY-ADDED-PATTERN' .gitignore && pass "T2 managed block updated"        || bad "T2 block NOT updated"
grep -q 'my-secret-dir/'      .gitignore && pass "T2 user rules above preserved"   || bad "T2 rules ABOVE lost"
grep -q 'my-trailing-rule/'   .gitignore && pass "T2 user rules below preserved"   || bad "T2 rules BELOW lost"
[ "$(grep -c 'the-ultimate-gitignore-ai:START' .gitignore)" = "1" ] \
  && pass "T2 exactly one managed block" || bad "T2 block was duplicated"

# T3 running again is a no-op, not a second write
d=$(up 2>&1)
printf '%s\n' "$d" | grep -qi 'already has the current block' && pass "T3 no-op detected" || bad "T3 no-op NOT detected"

# T4 a hand-written file with no markers must be APPENDED to, never rewritten
printf 'node_modules/\nmy-own-thing/\n' > .gitignore
up >/dev/null 2>&1 || bad "T4 exited non-zero"
grep -q 'my-own-thing/'       .gitignore && pass "T4 marker-less file preserved" || bad "T4 hand-written rules LOST"
grep -q 'NEWLY-ADDED-PATTERN' .gitignore && pass "T4 block appended"             || bad "T4 block not appended"

# T5 fail-closed: a download that is not this file must change nothing
cp .gitignore before.txt
printf 'this is a 404 page\n' > bogus.txt
if GITIGNORE_URL="$w/bogus.txt" sh "$ROOT/update.sh" >/dev/null 2>&1; then bad "T5 bogus payload accepted"; else pass "T5 bogus payload refused"; fi
cmp -s before.txt .gitignore && pass "T5 target untouched after refusal" || bad "T5 target was MODIFIED"

# T6 a directory argument resolves to its .gitignore
mkdir -p proj && up proj >/dev/null 2>&1
[ -f proj/.gitignore ] && pass "T6 directory argument resolved" || bad "T6 directory argument not handled"

# T7/T8 isolate the two guards. T5's payload trips BOTH, so on its own it proves neither: with the
# START check deleted the END check still catches it, and the mutant survives. These do not overlap.
printf 'rules\n# <<< the-ultimate-gitignore-ai:END\n' > end-only.txt
if GITIGNORE_URL="$w/end-only.txt" sh "$ROOT/update.sh" >/dev/null 2>&1; then bad "T7 payload without START accepted"; else pass "T7 payload without START refused"; fi
sed '/the-ultimate-gitignore-ai:END/d' "$w/upstream.gitignore" > truncated.txt
if GITIGNORE_URL="$w/truncated.txt" sh "$ROOT/update.sh" >/dev/null 2>&1; then bad "T8 truncated payload accepted"; else pass "T8 truncated payload refused"; fi

echo "---"
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES PRESENT"; exit 1; }
