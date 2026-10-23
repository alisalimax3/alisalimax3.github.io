#!/usr/bin/env python3
"""يستخرج أي مبلغ أرباح من رد JSON لأي شبكة إعلانية."""
import json,sys
p=sys.argv[1]
try: d=json.load(open(p))
except Exception: print("0.000000"); sys.exit()
MK={"revenue","earnings","income","amount","profit","payout","paid","balance","value","sum","total","estimated"}
cand=[]
def walk(o):
    if isinstance(o,dict):
        for k,v in o.items():
            if isinstance(v,(dict,list)): walk(v)
            elif k.lower() in MK:
                try: cand.append((k.lower(),float(str(v).replace(",",""))))
                except Exception: pass
    elif isinstance(o,list):
        for i in o: walk(i)
walk(d)
leaf=[v for k,v in cand if k not in ("total","sum")]
tot=sum(leaf) if leaf else sum(v for _,v in cand)
print("%.6f"%tot)
