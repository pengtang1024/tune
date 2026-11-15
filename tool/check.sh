#!/usr/bin/env bash
# Runs the gates a change has to pass before it can be merged.
#
#   ./tool/check.sh            analyze + every test except the ones that need the network
#   ./tool/check.sh --live     analyze + every test, including the ones that need the network
#   ./tool/check.sh --l10n     also fail when lib/l10n is out of date with the ARB files
#   ./tool/check.sh --tools    also run tool/*_test.dart (the screenshot harnesses)
#   ./tool/check.sh --docs     also check every Markdown page against docs/document-style.md
#
# Flags compose: CI runs `./tool/check.sh --l10n --tools --docs`.
#
# Why --tools is a flag and not always on: those harnesses render whole pages and
# write PNGs under build/, so they are slower than the unit tests, and they are the
# one part of the suite that no other gate touches (see docs/oss-maintenance.md).
#
# CI runs this same script (with --l10n), so a green run here means a green build
# there — as long as your Flutter version matches the one pinned in
# .github/workflows/ci.yml. Run `flutter pub get` first if you just cloned.
#
# The two live test files (test/services/music_source_live_test.dart and
# music_source_e2e_live_test.dart) reach real services; a failure there may be
# the network rather than the change. ./tool/live_sources.sh runs them one by one
# and is the better tool when you need to tell those apart.
set -u

cd "$(dirname "$0")/.." || exit 1

FLUTTER=${FLUTTER:-flutter}
live=0
l10n=0
tools=0
docs=0

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

for arg in "$@"; do
  case "$arg" in
    --live) live=1 ;;
    --l10n) l10n=1 ;;
    --tools) tools=1 ;;
    --docs) docs=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      printf 'unknown option: %s\n\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  printf 'flutter not found: %s\nSet FLUTTER=/path/to/flutter or add it to PATH.\n' "$FLUTTER" >&2
  exit 2
fi

status=0

printf '\n== flutter gen-l10n\n'
if [ "$l10n" -eq 1 ]; then
  if ! "$FLUTTER" gen-l10n; then
    status=1
  elif [ -n "$(git status --porcelain -- lib/l10n)" ]; then
    printf '\nlib/l10n changed: run "flutter gen-l10n" and commit the generated files.\n' >&2
    git --no-pager diff --stat -- lib/l10n >&2 || true
    status=1
  fi
else
  printf 'skipped (pass --l10n to assert the generated files are committed)\n'
fi

printf '\n== flutter analyze\n'
"$FLUTTER" analyze || status=1

printf '\n== flutter test\n'
# shellcheck disable=SC2046
if [ "$live" -eq 1 ]; then
  files=$(find test -name '*_test.dart' | sort)
else
  files=$(find test -name '*_test.dart' ! -name '*live*' | sort)
fi
# Word splitting is the point here: the file list is passed one path per argument.
# shellcheck disable=SC2086
"$FLUTTER" test $files || status=1

printf '\n== tool tests\n'
if [ "$tools" -eq 1 ]; then
  # Only the harnesses that can run unattended. tool/tooltip_shots_test.dart
  # compares against goldens written to build/tooltip-shots/ (not committed), so on
  # a clean checkout it fails with "non-existent file" until you seed them once with
  #   flutter test tool/tooltip_shots_test.dart --update-goldens
  # It stays a local visual spot-check instead of a gate.
  tool_files="tool/layout_shots_test.dart tool/local_feature_shots_test.dart"
  for f in $tool_files; do
    if [ ! -f "$f" ]; then
      printf 'missing tool test: %s\n' "$f" >&2
      status=1
    fi
  done
  # shellcheck disable=SC2086
  "$FLUTTER" test $tool_files || status=1
else
  printf 'skipped (pass --tools to run the screenshot harnesses)\n'
fi

printf '\n== docs\n'
if [ "$docs" -eq 1 ]; then
  python3 tool/check_docs.py || status=1
else
  printf 'skipped (pass --docs to check Markdown against docs/document-style.md)\n'
fi

printf '\n== summary\n'
if [ "$status" -eq 0 ]; then
  printf 'all gates passed\n'
else
  printf 'gates FAILED\n' >&2
fi
exit "$status"
