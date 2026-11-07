#!/bin/bash
# CRAP gate (AGENTS.md -> Quality gates, D-004, D-027).
#
#   scripts/crap.sh                     run the tests with coverage, then score
#   scripts/crap.sh path/to/X.xcresult  score an existing result bundle (CI)
#
# Needs: Xcode, python3, and lizard (`pip install lizard`; the Homebrew
# formula named "lizard" is an unrelated compressor). Set LIZARD to point at
# a specific lizard binary. Set CRAP_DESTINATION to change the simulator.
set -euo pipefail
cd "$(dirname "$0")/.."

LIZARD="${LIZARD:-lizard}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

RESULT="${1:-}"
if [ -z "$RESULT" ]; then
  RESULT="$WORK/tests.xcresult"
  xcodebuild -project Genki.xcodeproj -scheme Genki \
    -destination "${CRAP_DESTINATION:-platform=iOS Simulator,name=iPhone 17}" \
    -enableCodeCoverage YES -resultBundlePath "$RESULT" -quiet test
fi

xcrun xccov view --report --json "$RESULT" > "$WORK/coverage.json"
"$LIZARD" -l swift --csv Genki > "$WORK/complexity.csv"
python3 scripts/crap.py --coverage "$WORK/coverage.json" --complexity "$WORK/complexity.csv"
