#!/usr/bin/env bash
# Fails when line coverage of the layers that must stay well tested is too low.
#
# Usage: tool/check_coverage.sh [lcov-file] [minimum-percent]
#
# Checked groups (hand-written files only; generated code is ignored):
#   * domain/                      use cases, entities, repository contracts
#   * presentation/viewmodels/     Stacked ViewModels
set -euo pipefail

lcov="${1:-coverage/lcov.info}"
minimum="${2:-80}"

if [ ! -f "$lcov" ]; then
  echo "Coverage file not found: $lcov (run 'flutter test --coverage' first)" >&2
  exit 2
fi

status=0

check_group() {
  local label="$1" pattern="$2"
  awk -F: -v label="$label" -v pattern="$pattern" -v minimum="$minimum" '
    /^SF:/ {
      file = $2
      use = (file ~ pattern) && (file !~ /\.(g|freezed|mocks)\.dart$/) \
            && (file !~ /l10n\/app_localizations/)
    }
    use && /^LF:/ { found += $2 }
    use && /^LH:/ { hit += $2 }
    END {
      if (found == 0) {
        printf "%-14s no lines found for pattern %s\n", label, pattern
        exit 1
      }
      percent = 100 * hit / found
      printf "%-14s %6.1f%%  (%d/%d lines, minimum %d%%)\n", \
             label, percent, hit, found, minimum
      exit (percent + 0 < minimum + 0) ? 1 : 0
    }
  ' "$lcov" || status=1
}

check_group "domain" "/domain/"
check_group "viewmodels" "/presentation/viewmodels/|/integrity_gate_view_model"

if [ "$status" -ne 0 ]; then
  echo "Coverage is below the required minimum." >&2
fi
exit "$status"
