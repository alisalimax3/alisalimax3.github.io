#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; P="${PORT:-8787}"
python3 - "$DATA" "$ROOT" "$P" <<'PY'
import json,os,sys,datetime,urllib.request
d,root,port=sys.argv[1],sys.argv[2],sys.argv[3]
def g(n,f="{}"):
    p=os.path.join(d,n); return json.load(open(p)) if os.path.exists(p) else json.loads(f)
def svc(n):
    p=os.path.join(d,n+".pid")
    try:
        pid=int(open(p).read().strip()); os.kill(pid,0)
        if n=="gateway":
            try: urllib.request.urlopen(f"http://127.0.0.1:{port}/api/status",timeout=3); return f"يعمل ({pid}) ✔ يستجيب"
            except Exception: return f"يعمل ({pid}) ✗ لا يستجيب"
        return f"يعمل ({pid})"
    except Exception: return "متوقف"
ks=g("keys-status.json",'{"summary":{},"keys":[]}'); s=ks.get("summary",{})
tr=g("treasury.json",'{}'); st=g("sites.json"); cm=g("comments.json",'{"items":[]}')
rev=[k["id"] for k in ks["keys"] if k["status"]=="LIVE" and k.get("revenue_source")]
B="\033[1m"; Z="\033[0m"
print(f"\n{B}================ لوحة CineHub ================{Z}")
print(f"  البوابة          : {svc('gateway')}")
print(f"  الوكيل (حصد/سحب) : {svc('agent')}")
print(f"  مراقب المفاتيح   : {svc('watchkeys')}")
print(f"  النشر التلقائي   : {svc('autopost')}")
print(f"  بوت المشاهدة     : {svc('watchbot')}")
print(f"  مفاتيح حيّة      : {s.get('live',0)} | لوحة فقط: {s.get('set',0)} | ناقصة: {s.get('missing',0)}")
print(f"  مصادر ربح حيّة   : {len(rev)} {rev}")
print(f"  أرباح مسجّلة     : ${tr.get('lifetime_usd',0)}")
print(f"  قابل للسحب       : ${tr.get('available_usd',0)} / حد ${tr.get('threshold_usd',10)}")
print(f"  رصيد on-chain    : ${tr.get('onchain_usd',0)}")
print(f"  مواقع مسجّلة     : {sum(1 for v in st.values() if v.get('status') in ('registered','key_set','live'))}/{len(st)}")
print(f"  تعليقات          : {len(cm.get('items',[]))}")
print(f"{B}=============================================={Z}\n")
PY
