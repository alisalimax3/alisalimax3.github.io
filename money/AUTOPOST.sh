#!/usr/bin/env bash
# نشر إعلانات/محتوى تلقائيًا إلى قناة تيليجرام
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"; [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || { echo "لا يوجد بوت"; exit 0; }
CH="${TG_CHANNEL_ID:-${TG_CHAT_ID:-}}"; [ -n "$CH" ] || { echo "أضف TG_CHANNEL_ID"; exit 0; }
BASE="${PUBLIC_URL:-http://127.0.0.1:${PORT:-8787}}"
post(){ curl -sS --max-time 12 -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d "chat_id=$CH" --data-urlencode "text=$1" -d "disable_web_page_preview=false" >/dev/null 2>&1; }
next(){ python3 - "$ROOT" "$DATA" <<'PY'
import json,os,sys,glob,random
root,data=sys.argv[1],sys.argv[2]; q=os.path.join(data,"post-queue.json")
items=json.load(open(q)) if os.path.exists(q) else []
if not items:
    for name in ("titles.json","films.json","movies.json","catalog.json"):
        p=os.path.join(root,name)
        if not os.path.exists(p): continue
        try: d=json.load(open(p))
        except Exception: continue
        vals=d.values() if isinstance(d,dict) else d
        for v in vals:
            if isinstance(v,dict):
                t=v.get("title") or v.get("name")
                if t: items.append({"title":t,"path":v.get("slug") or v.get("url") or ""})
            elif isinstance(v,str) and len(v)<120: items.append({"title":v,"path":""})
        if items: break
    if not items:
        for f in glob.glob(os.path.join(root,"*.html")):
            b=os.path.basename(f)
            if b not in ("404.html","register.html","gate.html"): items.append({"title":b.replace(".html",""),"path":b})
    json.dump(items,open(q,"w"),ensure_ascii=False,indent=1)
i=json.load(open(os.path.join(data,"post-index.json")))["i"] if os.path.exists(os.path.join(data,"post-index.json")) else 0
if not items: print("|لا يوجد محتوى|"); raise SystemExit
it=items[i%len(items)]; json.dump({"i":i+1},open(os.path.join(data,"post-index.json"),"w"))
print(it["title"]+"|"+str(it.get("path","")))
PY
}
if [ "${1:-loop}" = "once" ]; then R="$(next)"; T="${R%%|*}"; P="${R##*|}"
  post "🎬 $T
${BASE}/${P}
#CineHub"; echo "  نُشر: $T"; exit 0; fi
echo $$ > "$DATA/autopost.pid"; echo "autopost بدأ"
while true; do R="$(next)"; T="${R%%|*}"; P="${R##*|}"; post "🎬 $T
${BASE}/${P}
#CineHub"; echo "[$(date -u +%FT%TZ)] $T" >> "$ROOT/logs/autopost.log"; sleep "${AUTOPOST_INTERVAL:-3600}"; done
