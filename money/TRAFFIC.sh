#!/usr/bin/env bash
# IndexNow حقيقي (Bing + Yandex) لكل صفحات الموقع — يسرّع الفهرسة ويزيد الزيارات
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
K="${INDEXNOW_KEY:-$(cat "$ROOT/indexnow-key.txt" 2>/dev/null | tr -d ' \n')}"
H="${PUBLIC_URL:-}"
[ -n "$K" ] || { echo "  ℹ لا يوجد INDEXNOW_KEY"; exit 0; }
[ -n "$H" ] || { echo "  ℹ أضف PUBLIC_URL في keys.env (مثال: https://yourdomain.com)"; exit 0; }
printf '%s' "$K" > "$ROOT/$K.txt"
python3 - "$ROOT" "$H" "$K" <<'PY'
import glob,os,sys,json,urllib.request
root,host,key=sys.argv[1],sys.argv[2].rstrip("/"),sys.argv[3]
urls=[f"{host}/{os.path.basename(f)}" for f in glob.glob(os.path.join(root,"*.html")) if os.path.basename(f)!="404.html"]
body=json.dumps({"host":host.split("//")[-1],"key":key,"keyLocation":f"{host}/{key}.txt","urlList":urls[:1000]}).encode()
for ep in ("https://api.indexnow.org/indexnow","https://www.bing.com/indexnow"):
    try:
        r=urllib.request.urlopen(urllib.request.Request(ep,data=body,headers={"content-type":"application/json; charset=utf-8"}),timeout=20)
        print(f"  ✔ {ep} -> HTTP {r.status} ({len(urls)} رابط)")
    except Exception as e: print(f"  ✗ {ep} -> {e}")
PY
