#!/usr/bin/env bash
# Lint entrypoint: validate frontmatter, then regenerate wiki/index.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate_out=""
validate_status=0
set +e
validate_out="$("$SCRIPT_DIR/validate-frontmatter.sh" 2>&1)"
validate_status=$?
set -e

printf '%s\n' "$validate_out"

if [[ "$validate_status" -ne 0 ]]; then
  exit "$validate_status"
fi

"$SCRIPT_DIR/build-index.sh"
