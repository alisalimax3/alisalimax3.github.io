#!/usr/bin/env bash
# يجدّد ADSENSE_ACCESS_TOKEN تلقائيًا كل ساعة (يحل مشكلة انتهاء صلاحية OAuth)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
[ -n "${GOOGLE_REFRESH_TOKEN:-}" ] || exit 0
[ -n "${GOOGLE_CLIENT_ID:-}" ] || exit 0
T="$(curl -sS --max-time 20 -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$GOOGLE_CLIENT_ID" -d "client_secret=${GOOGLE_CLIENT_SECRET:-}" \
  -d "refresh_token=$GOOGLE_REFRESH_TOKEN" -d grant_type=refresh_token 2>/dev/null \
  | python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))' 2>/dev/null)"
[ -n "$T" ] || { echo "  ✗ تجديد توكن جوجل فشل"; exit 1; }
if grep -q '^ADSENSE_ACCESS_TOKEN=' "$ROOT/keys.env"; then
  sed -i "s|^ADSENSE_ACCESS_TOKEN=.*|ADSENSE_ACCESS_TOKEN=$T|" "$ROOT/keys.env"
else echo "ADSENSE_ACCESS_TOKEN=$T" >> "$ROOT/keys.env"; fi
echo "  ✔ جُدّد توكن جوجل"
