#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"
[ -f "$ROOT/money/data/bot.pid" ] && kill -0 "$(cat "$ROOT/money/data/bot.pid")" 2>/dev/null && exit 0
exec bash "$H/BOT.sh" start
