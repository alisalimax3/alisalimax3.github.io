#!/usr/bin/env bash
# تعليق حقيقي: يسجّل في التطبيق + ينشر في مجموعة تيليجرام
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
TXT="${1:-}"; [ -n "$TXT" ] || { echo 'الاستخدام: bash money/COMMENT.sh "نص التعليق"'; exit 0; }
python3 - "$DATA" "$TXT" <<'PY'
import json,os,sys,datetime,hashlib
d,txt=sys.argv[1],sys.argv[2]; p=os.path.join(d,"comments.json")
c=json.load(open(p)) if os.path.exists(p) else {"items":[]}
c["items"].append({"id":hashlib.sha1((txt+str(datetime.datetime.utcnow())).encode()).hexdigest()[:10],
 "text":txt,"at":datetime.datetime.utcnow().isoformat()+"Z"})
json.dump(c,open(p,"w"),ensure_ascii=False,indent=2); print("  ✔ سُجّل تعليق ("+str(len(c['items']))+" إجمالًا)")
PY
CH="${TG_GROUP_ID:-${TG_CHAT_ID:-}}"
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "$CH" ] && curl -sS --max-time 12 -X POST \
 "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CH" --data-urlencode "text=💬 $TXT" >/dev/null 2>&1
echo "  ✔ نُشر في تيليجرام"
