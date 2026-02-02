#!/bin/bash
# Hadolint wrapper for Dockerfile linting

set -euo pipefail

FILE="$1"
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if ! command -v hadolint &> /dev/null; then
    echo "⚠️  hadolint not found. Install with: brew install hadolint"
    exit 0
fi

hadolint --config "$PROJECT_ROOT/.github/linters/.hadolint.yaml" "$FILE"
