#!/usr/bin/env bash
# Runs the tests that talk to real services, one file at a time.
#
# Those tests reach out to a dozen public services, and a run of the whole
# suite starts them next to every other file: a moment of slowness in one
# service then looks like a broken source. Run through this script they are
# read one after another, so a failure here is worth looking at, and a pass
# here means the earlier failure was the network.
set -u

cd "$(dirname "$0")/.." || exit 1

FLUTTER=${FLUTTER:-flutter}
FILES=(
  "test/services/music_source_e2e_live_test.dart"
  "test/services/music_source_live_test.dart"
)

failed=()
for file in "${FILES[@]}"; do
  printf '\n== %s\n' "$file"
  if ! "$FLUTTER" test --no-pub "$file"; then
    failed+=("$file")
  fi
done

printf '\n== summary\n'
for file in "${FILES[@]}"; do
  printf '%-52s %s\n' "$file" "$(if printf '%s\n' "${failed[@]:-}" | grep -qx "$file"; then echo FAILED; else echo ok; fi)"
done

[ ${#failed[@]} -eq 0 ]
