#!/usr/bin/env python3
import json,os,sys,urllib.request,urllib.error
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def _a():
    try: return json.load(open(os.path.join(ROOT,"auth.json"),encoding="utf-8"))
    except Exception: return {}
A=_a(); TOK=os.environ.get("GH_TOKEN") or A.get("token","")
SLUG=os.environ.get("SLUG") or A.get("repo",""); BR=os.environ.get("BR") or A.get("branch","main")
NAMES=("agent","browse","payout","earn","sync","scan","crawl","ingest","keep","cycle")
def api(p,m="GET",b=None):
    r=urllib.request.Request("https://api.github.com"+p,
        data=(json.dumps(b).encode() if b is not None else None),
        headers={"Authorization":"token "+TOK,"Accept":"application/vnd.github+json",
                 "Content-Type":"application/json","User-Agent":"c3099"})
    try:
        with urllib.request.urlopen(r,timeout=30) as x:
            raw=x.read(); return x.status,(json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e: return e.code,{"error":e.read().decode()[:160]}
    except Exception as e: return 0,{"error":str(e)[:160]}
if not TOK or not SLUG: print("  ✗ لا توكن/مستودع"); sys.exit(2)
st,wf=api("/repos/%s/actions/workflows"%SLUG)
if st!=200: print("  ✗ قراءة الوركفلو",st); sys.exit(3)
ws=[w for w in (wf.get("workflows") or []) if any(n in (w.get("name") or "").lower() for n in NAMES)]
if not ws: print("  ✗ لا وركفلو مطابق"); sys.exit(4)
d=0
for w in ws:
    st,_=api("/repos/%s/actions/workflows/%s/dispatches"%(SLUG,w["id"]),"POST",{"ref":BR})
    if st in (200,201,204): print("  ✓ شُغّل",w.get("name")); d+=1
    else: print("  ✗",w.get("name"),st)
print("  %d/%d"%(d,len(ws))); sys.exit(0 if d else 5)
