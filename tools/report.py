#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
t=L("treasury.json",{}); p=L("pulse.json",{}); led=L("ledger.json",{})
r=["# تقرير CineHub 3099 — "+datetime.date.today().isoformat(),"",
   "الرصيد: $%.6f"%(t.get("balance") or 0),"","## الفروع"]
for k,v in (t.get("buckets") or {}).items(): r.append("- %s: $%.6f"%(k,v))
r+=["","الدورات: %s"%p.get("cycle",0),"القيود: %s"%(len(led.get("entries",[])) if isinstance(led,dict) else 0)]
open("report.md","w",encoding="utf-8").write("\n".join(r)); print("report ok")
