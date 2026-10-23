#!/usr/bin/env bash
# نشر على القنوات: تيليجرام (محتوى + إباحة + رابط smartlink) وIndexNow
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
B="${PUBLIC_URL:-http://127.0.0.1:${PORT:-8787}}"
post(){ [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || return 1
 curl -sS --max-time 12 -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d "chat_id=$1" --data-urlencode "text=$2" -d disable_web_page_preview=false >/dev/null 2>&1; }
pick(){ python3 - "$ROOT" "$DATA" <<'PY'
import json,os,sys,glob
root,data=sys.argv[1],sys.argv[2]; q=os.path.join(data,"post-queue.json"); items=[]
if os.path.exists(q): items=json.load(open(q))
if not items:
    for n in ("titles.json","films.json","movies.json","catalog.json","adult-meta.json"):
        p=os.path.join(root,n)
        if not os.path.exists(p): continue
        try: d=json.load(open(p))
        except Exception: continue
        for v in (d.values() if isinstance(d,dict) else d):
            if isinstance(v,dict):
                t=v.get("title") or v.get("name")
                if t: items.append({"title":t,"path":v.get("slug") or v.get("url") or ""})
            elif isinstance(v,str) and len(v)<120: items.append({"title":v,"path":""})
        if items: break
    if not items:
        for f in sorted(glob.glob(os.path.join(root,"*.html"))):
            b=os.path.basename(f)
            if b not in ("404.html","register.html","gate.html"): items.append({"title":b[:-5],"path":b})
    json.dump(items,open(q,"w"),ensure_ascii=False,indent=1)
pi=os.path.join(data,"post-index.json"); i=json.load(open(pi))["i"] if os.path.exists(pi) else 0
it=items[i%len(items)]; json.dump({"i":i+1},open(pi,"w")); print(it["title"]+"|"+str(it.get("path","")))
PY
}
CH="${TG_CHANNEL_ID:-${TG_CHAT_ID:-}}"
if [ "${1:-loop}" = "once" ]; then R="$(pick)"; T="${R%%|*}"; P="${R##*|}"
  post "$CH" "🎬 $T
${B}/${P}
${ADULT_SMARTLINK:+🔥 $ADULT_SMARTLINK}
#CineHub" && echo "  ✔ نُشر: $T" || echo "  ℹ لا قناة (أضف TG_CHANNEL_ID)"
  bash "$HERE/TRAFFIC.sh"; exit 0; fi
echo $$ > "$DATA/autopost.pid"; echo "قنوات: بدأ"
while true; do R="$(pick)"; T="${R%%|*}"; P="${R##*|}"
  post "$CH" "🎬 $T
${B}/${P}
${ADULT_SMARTLINK:+🔥 $ADULT_SMARTLINK}
#CineHub" >/dev/null 2>&1
  echo "[$(date -u +%FT%TZ)] $T" >> "$ROOT/logs/channels.log"
  bash "$HERE/TRAFFIC.sh" >> "$ROOT/logs/channels.log" 2>&1
  sleep "${AUTOPOST_INTERVAL:-1800}"; done
