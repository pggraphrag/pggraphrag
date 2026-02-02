#!/bin/bash
# Yamllint wrapper for YAML file linting

set -euo pipefail

FILE="$1"
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if ! command -v yamllint &> /dev/null; then
    echo "⚠️  yamllint not found. Install with: pip install yamllint"
    exit 0
fi

yamllint --config-file "$PROJECT_ROOT/.github/linters/.yamllint.yml" "$FILE"
