#!/usr/bin/env bash
# يراقب keys.env: أي تغيير => فحص + إعادة ربط + إعادة تشغيل البوابة + نشر + تنبيه
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
mkdir -p "$DATA" "$ROOT/logs"; LOG="$ROOT/logs/watch-keys.log"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
tg(){ load "$ROOT/keys.env"
 [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ] && curl -sS --max-time 10 -X POST \
  "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TG_CHAT_ID" -d "text=$1" >/dev/null 2>&1; return 0; }
echo $$ > "$DATA/watchkeys.pid"
H=""; while true; do
  load "$ROOT/keys.env"
  bash "$HERE/lib/derive.sh" >> "$LOG" 2>&1
  bash "$HERE/lib/grefresh.sh" >> "$LOG" 2>&1
  NH="$( { cat "$ROOT/keys.env"; } 2>/dev/null | md5sum | cut -d' ' -f1)"
  if [ "$NH" != "$H" ]; then
    H="$NH"; echo "[$(date -u +%FT%TZ)] تغيير في keys.env -> فحص" >> "$LOG"
    bash "$HERE/KEYCHECK.sh" >> "$LOG" 2>&1
    python3 "$HERE/lib/sites.py" >> "$LOG" 2>&1
    bash "$HERE/WIRE.sh" >> "$LOG" 2>&1
    S="$(python3 -c 'import json;print(json.load(open("'"$DATA"'/keys-status.json"))["summary"])' 2>/dev/null)"
    tg "CineHub: مفاتيح محدّثة — $S"
    bash "$HERE/PUSH-GH.sh" >> "$LOG" 2>&1
  fi
  sleep "${WATCH_INTERVAL:-600}"
done
