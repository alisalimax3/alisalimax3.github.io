#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$H/data/zero.pid" ] && kill -0 "$(cat "$H/data/zero.pid")" 2>/dev/null && exit 0
exec bash "$H/ZERO.sh" start
