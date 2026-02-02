#!/bin/bash
# Markdownlint wrapper for Markdown file linting

set -euo pipefail

FILE="$1"
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if ! command -v markdownlint &> /dev/null; then
    echo "⚠️  markdownlint not found. Install with: npm install -g markdownlint-cli"
    exit 0
fi

markdownlint --config "$PROJECT_ROOT/.github/linters/.markdownlint.json" "$FILE"
