#!/bin/bash
# Pre-file-change hook dispatcher
# Runs appropriate linters based on file type before Edit/Write operations

set -euo pipefail

# Get file path from Claude environment
FILE="${CLAUDE_FILE_PATH:-}"
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if [[ -z "$FILE" ]]; then
    # No file path available, nothing to check
    exit 0
fi

# Get absolute path
if [[ ! "$FILE" = /* ]]; then
    FILE="$PROJECT_ROOT/$FILE"
fi

# Check if file exists (for Write operations on new files, skip linting)
if [[ ! -f "$FILE" ]]; then
    exit 0
fi

# Get filename and extension
FILENAME=$(basename "$FILE")
FILE_EXT="${FILENAME##*.}"
HOOK_DIR="$PROJECT_ROOT/.claude/hooks"

# Route to appropriate linter based on file type
case "$FILENAME" in
    Dockerfile*)
        exec "$HOOK_DIR/lint-dockerfile.sh" "$FILE"
        ;;
    *.dockerfile)
        exec "$HOOK_DIR/lint-dockerfile.sh" "$FILE"
        ;;
esac

case "$FILE_EXT" in
    yml|yaml)
        exec "$HOOK_DIR/lint-yaml.sh" "$FILE"
        ;;
    md)
        exec "$HOOK_DIR/lint-markdown.sh" "$FILE"
        ;;
    sh)
        exec "$HOOK_DIR/lint-shell.sh" "$FILE"
        ;;
    sql)
        exec "$HOOK_DIR/lint-sql.sh" "$FILE"
        ;;
    json)
        exec "$HOOK_DIR/lint-json.sh" "$FILE"
        ;;
esac

# No linter for this file type
exit 0
