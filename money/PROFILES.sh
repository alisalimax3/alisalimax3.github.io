#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$H/lib/profile.js"; echo; echo "  افتح: money/data/profiles/  وانسخ لكل منصة."
