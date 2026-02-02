#!/bin/bash
# ShellCheck wrapper for shell script linting

set -euo pipefail

FILE="$1"

if ! command -v shellcheck &> /dev/null; then
    echo "⚠️  shellcheck not found. Install with: brew install shellcheck"
    exit 0
fi

shellcheck --severity=warning "$FILE"
