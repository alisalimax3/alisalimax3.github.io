#!/usr/bin/env bash
# يشتق آليًا: عنوان المحفظة من المفتاح الخاص، chat_id من البوت، مالك GitHub من الرمز
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"; load "$ROOT/.env"
add(){ grep -q "^$1=" "$ROOT/keys.env" 2>/dev/null || printf '%s=%s\n' "$1" "$2" >> "$ROOT/keys.env"; }
if [ -n "${WALLET_PRIVATE_KEY:-}" ] && [ -z "${WALLET_ADDRESS:-}" ]; then
  A="$(cd "$ROOT" && node -e 'try{console.log(new (require("ethers").Wallet)(process.env.WALLET_PRIVATE_KEY).address)}catch(e){}' 2>/dev/null)"
  [ -n "$A" ] && { add WALLET_ADDRESS "$A"; echo "  ✔ اشتُق عنوان المحفظة: $A"; }; fi
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -z "${TG_CHAT_ID:-}" ]; then
  C="$(curl -sS --max-time 12 "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates" 2>/dev/null | python3 -c '
import json,sys
try: r=json.load(sys.stdin).get("result",[])
except Exception: r=[]
for u in reversed(r):
    c=(u.get("message") or u.get("channel_post") or {}).get("chat") or {}
    if c.get("id"): print(c["id"]); break' 2>/dev/null)"
  [ -n "$C" ] && { add TG_CHAT_ID "$C"; echo "  ✔ اشتُق chat_id: $C (أرسل رسالة للبوت أولًا إن كان فارغًا)"; }; fi
if [ -n "${GITHUB_TOKEN:-}" ] && [ -z "${GITHUB_OWNER:-}" ]; then
  O="$(curl -sS --max-time 12 -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("login",""))' 2>/dev/null)"
  [ -n "$O" ] && { add GITHUB_OWNER "$O"; echo "  ✔ مالك GitHub: $O"; }; fi
if [ -n "${PUBLIC_URL:-}" ] && [ -z "${PUBLIC_URL:-}" ]; then :; fi
echo "  الاشتقاق انتهى"
