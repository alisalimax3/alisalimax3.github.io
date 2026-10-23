#!/usr/bin/env python3
"""دفتر أرباح: append-only + سلسلة hash + منع التكرار."""
import json,os,sys,hashlib,time,datetime
P=os.path.abspath(os.environ.get("LEDGER",os.path.join(os.path.dirname(__file__),"..","data","ledger.json")))
def load():
    if not os.path.exists(P): return {"chain":[],"keys":[],"total":0.0}
    try:
        d=json.load(open(P)); d.setdefault("chain",[]); d.setdefault("keys",[]); d.setdefault("total",0.0); return d
    except Exception: return {"chain":[],"keys":[],"total":0.0}
def save(d):
    os.makedirs(os.path.dirname(P),exist_ok=True); t=P+".tmp"
    json.dump(d,open(t,"w"),indent=2,ensure_ascii=False); os.replace(t,P)
def canon(r):
    return "|".join([str(r["ts"]),r["net"],r["date"],"%.6f"%r["amount"],r["currency"],"%.6f"%r["usd"],r["source"],r.get("uid","-")])
def H(prev,c): return hashlib.sha256((prev+"|"+c).encode()).hexdigest()
def keyof(e): return e.get("key") or "%s|%s"%(e["net"],e["date"])
def append(entries):
    d=load(); ks=set(d["keys"]); added=[]
    for e in entries:
        k=keyof(e)
        if k in ks: continue
        prev=d["chain"][-1]["hash"] if d["chain"] else "0"*64
        r={"ts":int(time.time()),"net":e["net"],"date":e["date"],"amount":round(float(e["amount"]),6),
           "currency":e.get("currency","USD"),"usd":round(float(e.get("usd",e["amount"])),6),
           "source":e.get("source","api"),"uid":e.get("uid","-"),"prev":prev}
        r["hash"]=H(prev,canon(r)); d["chain"].append(r); ks.add(k)
        d["total"]=round(d["total"]+r["usd"],6); added.append(r)
    d["keys"]=sorted(ks); save(d); return added
def verify():
    d=load(); prev="0"*64
    for r in d["chain"]:
        if r["prev"]!=prev: return False,r["ts"]
        if H(prev,canon(r))!=r["hash"]: return False,r["ts"]
        prev=r["hash"]
    return True,len(d["chain"])
def stats(days=30):
    d=load(); cut=(datetime.date.today()-datetime.timedelta(days=days)).isoformat(); per={}; tot=0.0
    for r in d["chain"]:
        if r["date"]>=cut: per[r["net"]]=round(per.get(r["net"],0)+r["usd"],6); tot=round(tot+r["usd"],6)
    return {"window_days":days,"total":tot,"per_network":per,"lifetime":d["total"],"entries":len(d["chain"])}
if __name__=="__main__":
    c=sys.argv[1] if len(sys.argv)>1 else "stats"
    if c=="append": print(json.dumps({"added":len(append(json.load(sys.stdin)))}))
    elif c=="verify":
        o,n=verify(); print(json.dumps({"chain_ok":o,"entries":n})); sys.exit(0 if o else 1)
    elif c=="stats": print(json.dumps(stats(int(sys.argv[2]) if len(sys.argv)>2 else 30)))
    else: print(json.dumps(load()))
