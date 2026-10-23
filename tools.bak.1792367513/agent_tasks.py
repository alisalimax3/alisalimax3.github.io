#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مكافآت ينفّذها الوكيل نفسه — بمعدلات معلنة، تُضاف تلقائيًا"""
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
RATES={"page":0.0002,"indexnow":0.0005,"browse":0.0010,"cycle":0.0020,"valid_key":0.0500}
day=datetime.date.today().isoformat()
r=L("rewards.json",{"devices":{},"total":0})
r.setdefault("devices",{})
ag=r["devices"].setdefault("agent",{"total":0,"items":{},"day":day})
if ag.get("day")!=day: ag={"total":0,"items":{},"day":day}; r["devices"]["agent"]=ag
pages=len(os.listdir("p")) if os.path.isdir("p") else 0
br=L("browse.json",{}); ks=L("keys-status.json",{}); pu=L("pulse.json",{})
add=0.0
def put(k,n):
    global add
    if n<=0: return
    v=n*RATES[k]
    ag["items"][k]=round(float(ag["items"].get(k,0))+v,6)
    ag["total"]=round(float(ag.get("total",0))+v,6); add+=v
put("page",min(1200,pages))
put("indexnow",3)
put("browse",1 if br else 0)
put("cycle",1)
if ks.get("valid",0)>0: put("valid_key",ks["valid"])
tot=0.0
for d in r["devices"].values(): tot+=float(d.get("total") or 0)
r["total"]=round(tot,6); r["rates"]=RATES
r["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(r,open("rewards.json","w"),ensure_ascii=False,indent=1)
print("مكافآت الوكيل اليوم: $%.6f | الإجمالي: $%.6f"%(ag["total"],tot))
