#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
MIN=float(os.environ.get("MIN_WITHDRAW","5"))
t=L("treasury.json",{}); bal=float(t.get("balance") or 0)
w=L("withdrawal.json",{"requests":[]})
if bal>=MIN and not [r for r in w.get("requests",[]) if r.get("status")=="pending"]:
    o=L("owner.json",{})
    req={"id":"w%d"%int(datetime.datetime.now().timestamp()),"amount":round(bal,6),
         "breakdown":t.get("buckets",{}),"status":"pending",
         "created":datetime.datetime.now(datetime.timezone.utc).isoformat(),
         "method":"Al-Kuraimi Islamic Microfinance Bank","swift":"KBMFYESAXXX",
         "to":o.get("kuraimi",{}),"whatsapp":o.get("whatsapp","")}
    w.setdefault("requests",[]).append(req)
    json.dump(w,open("withdrawal.json","w"),ensure_ascii=False,indent=1)
    print("WITHDRAW",req["id"],req["amount"])
else: print("balance %.6f / min %.2f"%(bal,MIN))
