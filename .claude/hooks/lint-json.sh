#!/bin/bash
# JSON validation wrapper

set -euo pipefail

FILE="$1"

if ! command -v python3 &> /dev/null; then
    echo "⚠️  python3 not found. Required for JSON validation."
    exit 0
fi

python3 -m json.tool "$FILE" > /dev/null
