#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$H/data/apex.pid" ] && kill -0 "$(cat "$H/data/apex.pid")" 2>/dev/null && exit 0
exec bash "$H/APEX.sh" start
