#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
mkdir -p "$DATA" "$ROOT/logs"; LOG="$ROOT/logs/agent-money.log"; INT="${HARVEST_INTERVAL:-300}"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
tg(){ [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ] && curl -sS --max-time 10 -X POST \
 "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TG_CHAT_ID" -d "text=$1" >/dev/null 2>&1; return 0; }
one(){ load "$ROOT/keys.env"; load "$DATA/keys.live.env"
  echo "[$(date -u +%FT%TZ)] harvest" >> "$LOG"
  bash "$HERE/HARVEST.sh" >> "$LOG" 2>&1
  bash "$HERE/PAYOUT.sh" >> "$LOG" 2>&1
  bash "$HERE/GATEWAY.sh" start >> "$LOG" 2>&1
  printf '{"ts":"%s","pid":%s,"interval":%s,"status":"alive"}\n' "$(date -u +%FT%TZ)" "$$" "$INT" > "$DATA/heartbeat.json"
  A="$(cat "$DATA/.added" 2>/dev/null || echo 0)"
  [ "${A:-0}" -gt 0 ] && tg "CineHub: +$A قيد ربح | available=$(python3 -c "import json;print(json.load(open('$DATA/treasury.json'))['available_usd'])" 2>/dev/null)"; }
case "${1:-run}" in
  once) one;;
  install-cron) (crontab -l 2>/dev/null | grep -v AGENT-MONEY; printf '*/5 * * * * cd %s && bash money/AGENT-MONEY.sh once >> logs/agent-money.log 2>&1\n' "$ROOT") | crontab - 2>/dev/null && echo "cron مثبت";;
  *) echo $$ > "$DATA/agent.pid"; echo "agent بدأ (pid $$)"; trap 'exit 0' INT TERM; while true; do one; sleep "$INT"; done;;
esac
