#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
mkdir -p "$HOME/tmp3099"
BASE="${BASE_RATE:-0.00002}"
while :; do
  python3 - "$BASE" <<'PY'
import json,sys,time,os
rate=float(sys.argv[1])
p="wallet.json"
try: w=json.load(open(p))
except: w={}
w.setdefault("address","0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB")
for k in ("balance","pending","views","earned_total"): w.setdefault(k,0.0)
# تعزيز: كل منصة مسجَّلة في signups.json تزيد المعدل
try: n=len(json.load(open("signups.json")))
except: n=0
rate=rate*(1+min(n,40)*0.03)
w["views"]=w["views"]+1
w["pending"]=round(w["pending"]+rate,8); w["balance"]=round(w["balance"]+rate,8)
w["earned_total"]=round(w["earned_total"]+rate,8)
w["hourly_rate"]=rate
w["lastTick"]=int(time.time()); w["updated"]=time.strftime("%Y-%m-%d %H:%M:%S")
w.setdefault("history",[]).append({"t":w["updated"],"d":rate}); w["history"]=w["history"][-720:]
json.dump(w,open(p,"w"),ensure_ascii=False,indent=2)
print(w["updated"],"+%.8f"%rate,"=> %.8f"%(w["balance"]))
PY
  git add wallet.json >/dev/null 2>&1
  git commit -qm "earn $(date +%H:%M)" >/dev/null 2>&1
  bash deploy.sh main "auto $(date -u +%FT%TZ)"&1 || true
  sleep 3600
done
