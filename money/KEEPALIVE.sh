#!/usr/bin/env bash
# يبقي كل شيء حيًا للأبد: بوابة، وكيل، مراقب، قنوات، تجديد توكن، تقرير يومي
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
mkdir -p "$DATA" "$ROOT/logs"; L="$ROOT/logs/keepalive.log"
echo $$ > "$DATA/keepalive.pid"; LASTTOK=0
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock 2>/dev/null
up(){ [ -s "$DATA/$1.pid" ] && kill -0 "$(cat "$DATA/$1.pid")" 2>/dev/null; }
go(){ nohup "$@" </dev/null >> "$ROOT/logs/$2.log" 2>&1 & echo $! > "$DATA/$2.pid"; }
echo "[$(date -u +%FT%TZ)] keepalive started" >> "$L"
while true; do
  bash "$HERE/GATEWAY.sh" start >> "$L" 2>&1
  up agent || { go bash "$HERE/AGENT-MONEY.sh" agent; echo "[$(date -u +%FT%TZ)] restart agent" >> "$L"; }
  up watchkeys || { go bash "$HERE/WATCH-KEYS.sh" watchkeys; echo "[$(date -u +%FT%TZ)] restart watchkeys" >> "$L"; }
  up autopost || { go bash "$HERE/CHANNELS.sh" autopost; echo "[$(date -u +%FT%TZ)] restart channels" >> "$L"; }
  if [ "${WITH_BROWSER:-0}" = "1" ] && [ -d "$HERE/node_modules/playwright" ]; then
    up watchbot || { go node "$HERE/WATCH-BOT.js" watchbot; echo "[$(date -u +%FT%TZ)] restart watchbot" >> "$L"; }; fi
  NOW="$(date +%s)"; [ $((NOW-LASTTOK)) -gt 3000 ] && { bash "$HERE/lib/grefresh.sh" >> "$L" 2>&1; LASTTOK=$NOW; }
  [ "$(date -u +%H)" = "08" ] && [ ! -f "$DATA/.rep-$(date -u +%F)" ] && { bash "$HERE/DAILY-REPORT.sh" >> "$L" 2>&1; touch "$DATA/.rep-$(date -u +%F)"; }
  sleep 45
done
