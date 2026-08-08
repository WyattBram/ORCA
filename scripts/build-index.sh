#!/usr/bin/env bash
# Regenerate wiki/index.md from frontmatter across wiki/ pages.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

INDEX_FILE="wiki/index.md"
TMP_ROWS="$(mktemp)"
trap 'rm -f "$TMP_ROWS"' EXIT

extract_frontmatter() {
  local file="$1"
  awk '
    /^---[[:space:]]*$/ {
      count++
      if (count == 2) exit
      next
    }
    count == 1 { print }
  ' "$file"
}

has_frontmatter_block() {
  local file="$1"
  awk '
    /^---[[:space:]]*$/ { count++; if (count == 2) { found=1; exit } }
    END { exit found ? 0 : 1 }
  ' "$file"
}

get_field() {
  local fm="$1" key="$2"
  printf '%s\n' "$fm" | sed -n "s/^${key}:[[:space:]]*//p" | head -n 1
}

# Flatten "[a, b]" -> "a,b" (strip brackets and spaces after commas). Absent -> "-"
flatten_related_systems() {
  local raw="$1"
  if [[ -z "$raw" ]]; then
    printf '%s' "-"
    return
  fi
  if [[ "$raw" =~ ^\[.*\]$ ]]; then
    local inner="${raw#\[}"
    inner="${inner%\]}"
    # Trim spaces around commas and ends
    inner="$(printf '%s' "$inner" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/,[[:space:]]*/,/g')"
    if [[ -z "$inner" ]]; then
      printf '%s' "-"
    else
      printf '%s' "$inner"
    fi
  else
    # Non-bracketed value: keep trimmed, or "-" if blank
    local trimmed
    trimmed="$(printf '%s' "$raw" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ -z "$trimmed" ]]; then
      printf '%s' "-"
    else
      printf '%s' "$trimmed"
    fi
  fi
}

entry_count=0

while IFS= read -r -d '' file; do
  rel="${file#./}"

  if ! has_frontmatter_block "$rel"; then
    echo "build-index: skipping ${rel}, no frontmatter" >&2
    continue
  fi

  fm="$(extract_frontmatter "$rel")"

  type="$(get_field "$fm" type)"
  status="$(get_field "$fm" status)"
  feature_status="$(get_field "$fm" feature_status)"
  updated="$(get_field "$fm" updated)"
  related_raw="$(get_field "$fm" related_systems)"

  [[ -z "$feature_status" ]] && feature_status="-"
  [[ -z "$type" ]] && type="-"
  [[ -z "$status" ]] && status="-"
  [[ -z "$updated" ]] && updated="-"

  related_systems="$(flatten_related_systems "$related_raw")"

  # path	type	status	feature_status	updated	related_systems
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$rel" "$type" "$status" "$feature_status" "$updated" "$related_systems" >> "$TMP_ROWS"
  entry_count=$((entry_count + 1))
done < <(find wiki -type f -name '*.md' \
  ! -path 'wiki/index.md' \
  ! -path 'wiki/log.md' \
  -print0 | sort -z)

{
  printf '%s\n' $'path\ttype\tstatus\tfeature_status\tupdated\trelated_systems'
  if [[ -s "$TMP_ROWS" ]]; then
    # Sort by type (col 2), then path (col 1)
    sort -t $'\t' -k2,2 -k1,1 "$TMP_ROWS"
  fi
} > "$INDEX_FILE"

echo "build-index: wrote ${entry_count} entries to wiki/index.md"
