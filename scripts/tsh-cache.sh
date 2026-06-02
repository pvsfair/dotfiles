#!/bin/bash

# Configuration
CACHE_DIR="${HOME}/.cache/tsh"
CACHE_MAX_AGE=$((24 * 60 * 60)) # 24 hours in seconds

# Parse flags and arguments
FORCE_RELOAD=false
RESOURCE_TYPE=""
RESOLVE_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) FORCE_RELOAD=true; shift ;;
    --resolve) RESOLVE_NAME="$2"; shift 2 ;;
    *) RESOURCE_TYPE="$1"; shift ;;
  esac
done

if [[ -z "$RESOURCE_TYPE" ]]; then
  echo "Usage: tsh-cache.sh [-f|--force] [--resolve <name>] <resource_type>" >&2
  echo "Examples: tsh-cache.sh apps | tsh-cache.sh db | tsh-cache.sh mgmt --resolve app-name" >&2
  exit 1
fi

# --resolve is only valid for mgmt
if [[ -n "$RESOLVE_NAME" ]] && [[ "$RESOURCE_TYPE" != "mgmt" ]]; then
  echo "Error: --resolve is only supported for 'mgmt' resource type" >&2
  exit 1
fi

CACHE_FILE="${CACHE_DIR}/${RESOURCE_TYPE}.txt"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Check if cache exists and is less than 24 hours old
if [[ "$FORCE_RELOAD" == false ]] && [[ -f "$CACHE_FILE" ]]; then
  file_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
  if (( file_age < CACHE_MAX_AGE )); then
    if [[ -n "$RESOLVE_NAME" ]]; then
      awk -F'\t' -v name="$RESOLVE_NAME" '$1 == name { print $2 }' "$CACHE_FILE"
    else
      cut -f1 "$CACHE_FILE"
    fi
    exit 0
  fi
fi

# Build command with resource-specific flags
# For "mgmt", we query apps but filter to mgmt cluster only
TSH_RESOURCE="$RESOURCE_TYPE"
TSH_CMD=(tsh "$TSH_RESOURCE" ls --format=json)
case "$RESOURCE_TYPE" in
  db) TSH_CMD+=(--search mongo) ;;
  mgmt) TSH_CMD=(tsh apps ls --format=json) ;;
esac

# Apply resource-specific jq filters
# "mgmt" stores name<TAB>public_addr for resolution
JQ_FILTER='.[].metadata.name'
case "$RESOURCE_TYPE" in
  apps) JQ_FILTER='[.[] | select(.metadata.labels.cluster_name != "mgmt")] | .[].metadata.name' ;;
  mgmt) JQ_FILTER='[.[] | select(.metadata.labels.cluster_name == "mgmt")] | .[] | "\(.metadata.name)\t\(.spec.public_addr)"' ;;
esac

# Refresh: run tsh command in JSON format to avoid truncation
# Strip any non-JSON lines (e.g. login prompts) before the JSON array
"${TSH_CMD[@]}" 2>/dev/null \
  | sed -n '/^\[/,$p' \
  | jq -r "$JQ_FILTER" \
  > "$CACHE_FILE"

# Output: resolve a name or list names
if [[ -n "$RESOLVE_NAME" ]]; then
  awk -F'\t' -v name="$RESOLVE_NAME" '$1 == name { print $2 }' "$CACHE_FILE"
else
  cut -f1 "$CACHE_FILE"
fi
