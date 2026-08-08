#!/usr/bin/env bash
# Validate YAML frontmatter on wiki/*.md pages (excludes index.md, log.md).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

VALID_TYPES="system|component|decision|feature|meeting|entity-person|entity-team|entity-external|practice"
VALID_STATUSES="draft|active|needs-review|superseded|archived"
VALID_FEATURE_STATUSES="in-progress|shipped|cancelled|on-pause"

violations=0
files_checked=0

is_valid_date() {
  local d="$1"
  [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

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

# Value of first single-line "key: value" (trimmed). Empty if key missing or value blank.
get_field() {
  local fm="$1" key="$2"
  printf '%s\n' "$fm" | sed -n "s/^${key}:[[:space:]]*//p" | head -n 1
}

# True if a line starts with "key:" (covers nested / empty values).
has_key() {
  local fm="$1" key="$2"
  printf '%s\n' "$fm" | grep -q "^${key}:"
}

report() {
  printf '%s\n' "$1"
  violations=$((violations + 1))
}

while IFS= read -r -d '' file; do
  # Normalize to path relative to repo root
  rel="${file#./}"
  files_checked=$((files_checked + 1))

  if ! has_frontmatter_block "$rel"; then
    report "${rel}: missing frontmatter"
    continue
  fi

  fm="$(extract_frontmatter "$rel")"

  type="$(get_field "$fm" type)"
  status="$(get_field "$fm" status)"
  created="$(get_field "$fm" created)"
  updated="$(get_field "$fm" updated)"
  feature_status="$(get_field "$fm" feature_status)"
  component="$(get_field "$fm" component)"
  review_by="$(get_field "$fm" review_by)"
  source_last_modified="$(get_field "$fm" source_last_modified)"
  last_synced="$(get_field "$fm" last_synced)"
  superseded_by="$(get_field "$fm" superseded_by)"
  date_field="$(get_field "$fm" date)"

  # Base required fields (scalar values must be non-empty)
  for field in type status created updated; do
    val="$(get_field "$fm" "$field")"
    if [[ -z "$val" ]]; then
      report "${rel}: missing required field ${field}"
    fi
  done

  # related_systems: key must exist (list contents not deeply validated)
  if ! has_key "$fm" related_systems; then
    report "${rel}: missing required field related_systems"
  fi

  # type enum (only if present — missing already reported)
  if [[ -n "$type" ]] && ! [[ "$type" =~ ^($VALID_TYPES)$ ]]; then
    report "${rel}: invalid type ${type}"
  fi

  # status enum
  if [[ -n "$status" ]] && ! [[ "$status" =~ ^($VALID_STATUSES)$ ]]; then
    report "${rel}: invalid status ${status}"
  fi

  # Conditional requirements by type
  case "$type" in
    feature)
      if [[ -z "$feature_status" ]]; then
        report "${rel}: missing required field feature_status for type feature"
      elif ! [[ "$feature_status" =~ ^($VALID_FEATURE_STATUSES)$ ]]; then
        report "${rel}: invalid feature_status ${feature_status}"
      fi
      if [[ -z "$component" ]]; then
        report "${rel}: missing required field component for type feature"
      fi
      ;;
    decision)
      if [[ "$status" == "superseded" ]]; then
        if [[ -z "$superseded_by" ]] || [[ ! -e "$REPO_ROOT/$superseded_by" ]]; then
          report "${rel}: superseded_by missing or points to nonexistent file"
        fi
      fi
      ;;
    system|component|practice)
      if [[ -z "$source_last_modified" || -z "$last_synced" ]]; then
        if [[ -z "$review_by" ]]; then
          report "${rel}: missing required field review_by for type ${type}"
        fi
      fi
      ;;
    meeting)
      for field in date attendees action_items; do
        if ! has_key "$fm" "$field"; then
          report "${rel}: missing required field ${field} for type meeting"
        fi
      done
      ;;
  esac

  # Date format checks for fields that are present
  for field in created updated review_by date; do
    val="$(get_field "$fm" "$field")"
    if [[ -n "$val" ]] && ! is_valid_date "$val"; then
      report "${rel}: invalid date format in ${field}"
    fi
  done
done < <(find wiki -type f -name '*.md' \
  ! -path 'wiki/index.md' \
  ! -path 'wiki/log.md' \
  -print0 | sort -z)

if [[ "$violations" -eq 0 ]]; then
  echo "validate-frontmatter: OK (${files_checked} files checked)"
  exit 0
fi

echo "validate-frontmatter: ${violations} violation(s) found"
exit 1
