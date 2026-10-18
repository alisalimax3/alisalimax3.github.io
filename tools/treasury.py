#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
def pick(d):
    if not isinstance(d,dict): return 0.0
    for k in ("total","amount","balance","usd","earnings","revenue","pending"):
        if d.get(k) is not None:
            try: return round(float(d[k]),6)
            except Exception: pass
    return 0.0
SRC={"ads":"revenue.json","rewards":"rewards.json","commissions":"commissions.json","gifts":"gifts.json",
     "surveys":"surveys.json","links":"links.json","referral":"refs.json"}
b={k:pick(L(f,{})) for k,f in SRC.items()}
t=round(sum(b.values()),6)
json.dump({"buckets":b,"balance":t,"withdrawable":t,"min":5.0,
           "updated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("treasury.json","w"),ensure_ascii=False,indent=1)
print("treasury",t)
