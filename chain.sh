#!/data/data/com.termux/files/usr/bin/bash
python3 - <<'PY'
import json,urllib.request,os
RPC=["https://mainnet.base.org","https://base.llamarpc.com","https://base-rpc.publicnode.com"]
T={"USDC":("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6),
   "USDT":("0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6),
   "VVV": ("0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf",18),
   "DIEM":("0xf4d97f2da56e8c3098f3a8d538db630a2606a024",18)}
def rpc(m,p):
    for u in RPC:
        try:
            b=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
            r=urllib.request.Request(u,data=b,headers={"Content-Type":"application/json"})
            with urllib.request.urlopen(r,timeout=20) as x:
                j=json.loads(x.read())
                if "result" in j: return j["result"]
        except Exception: continue
    return None
w={}
try: w=json.load(open("wallet.json"))
except Exception: pass
a=(w.get("address") or "").strip()
print("═══ محفظة: %s ═══"%(a or "غير محددة"))
if not a or not a.startswith("0x"):
    print("✗ لم تُحدَّد — نفّذ:  bash wallet.sh 0xعنوانك"); raise SystemExit
h=rpc("eth_getBalance",[a,"latest"])
print("ETH (Base) : %.6f"%(int(h,16)/1e18) if h else "ETH        : تعذّر الاتصال")
for n,(c,d) in T.items():
    data="0x70a08231"+a[2:].lower().rjust(64,"0")
    v=rpc("eth_call",[{"to":c,"data":data},"latest"])
    print("%-10s : %s"%(n, ("%.6f"%(int(v,16)/10**d)) if v else "—"))
print("مصدر الأرقام: شبكة Base مباشرة — لا تقدير.")
PY
