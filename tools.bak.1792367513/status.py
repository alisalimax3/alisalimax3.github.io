#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
st={"engine":"live","updated":datetime.datetime.now(datetime.timezone.utc).isoformat()}
for f,k in (("revenue.json","revenue"),("ledger.json","ledger"),("registry.json","registry")):
    try: st[k]=json.load(open(f,encoding="utf-8"))
    except Exception: pass
json.dump(st,open("status.json","w"),ensure_ascii=False,indent=1); print("status ok")
