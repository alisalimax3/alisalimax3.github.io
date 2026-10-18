import json,time
p="wallet.json"
try: w=json.load(open(p))
except: w={}
w.setdefault("address","0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB")
for k in ("balance","pending","views","earned_total"): w.setdefault(k,0.0)
try: n=len(json.load(open("signups.json")))
except: n=0
rate=0.00002*(1+min(n,40)*0.03)
w["views"]=w["views"]+1
w["pending"]=round(w["pending"]+rate,8); w["balance"]=round(w["balance"]+rate,8)
w["earned_total"]=round(w["earned_total"]+rate,8); w["hourly_rate"]=rate
w["lastTick"]=int(time.time()); w["updated"]=time.strftime("%Y-%m-%d %H:%M:%S")
w.setdefault("history",[]).append({"t":w["updated"],"d":rate}); w["history"]=w["history"][-720:]
json.dump(w,open(p,"w"),ensure_ascii=False,indent=2)
print(w["updated"],"+%.8f"%rate,"=>","%.8f"%w["balance"])
