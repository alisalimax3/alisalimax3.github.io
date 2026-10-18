#!/usr/bin/env python3
import json,os,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
led=rd("ledger.json",[])
if isinstance(led,dict):
    for k in ("entries","events","log","items","ledger"):
        if isinstance(led.get(k),list): led=led[k]; break
    else: led=[]
if not isinstance(led,list): led=[]
led=[e for e in led if isinstance(e,dict)]
by={}
for e in led:
    try: by[e.get("src","?")]=round(by.get(e.get("src","?"),0)+float(e.get("amount",0)),6)
    except Exception: pass
bal=round(sum(by.values()),6)
json.dump({"balance":bal,"points":int(round(bal*100)),"by_source":by,"events":len(led),
 "currency":"USD","updated":int(time.time()),"human":time.strftime("%Y-%m-%d %H:%M")},
 open("wallet.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("المحفظة: $%.4f | %d حدث"%(bal,len(led)))
