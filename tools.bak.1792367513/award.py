#!/usr/bin/env python3
import json,os,sys,time
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
led.append({"src":sys.argv[1],"amount":round(float(sys.argv[2]),6),
            "note":(sys.argv[3] if len(sys.argv)>3 else ""),"at":int(time.time())})
json.dump(led[-5000:],open("ledger.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("+ $%.6f ← %s"%(float(sys.argv[2]),sys.argv[1]))
