#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$H/.." && pwd)"
[ -f "$H/data/final.pid" ] && kill -0 "$(cat "$H/data/final.pid")" 2>/dev/null && exit 0
exec bash "$H/FINAL.sh" start
