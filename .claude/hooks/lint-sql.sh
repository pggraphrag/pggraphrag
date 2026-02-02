#!/bin/bash
# SQLFluff wrapper for SQL file linting

set -euo pipefail

FILE="$1"

if ! command -v sqlfluff &> /dev/null; then
    echo "⚠️  sqlfluff not found. Install with: pip install sqlfluff==4.0.0"
    exit 0
fi

sqlfluff lint --dialect postgres "$FILE"
