import json,sys,os,urllib.request
RPC=["https://base.llamarpc.com","https://base-rpc.publicnode.com","https://1rpc.io/base",
     "https://base.blockpi.network/v1/rpc/public","https://base.drpc.org","https://mainnet.base.org"]
TOK={"USDC":("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6),
     "USDT":("0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6),
     "VVV":("0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf",18),
     "DIEM":("0xf4d97f2da56e8c3098f3a8d538db630a2606a024",18)}
def rpc(m,p):
    b=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(); e=None
    for u in RPC:
        try:
            r=urllib.request.Request(u,data=b,headers={"Content-Type":"application/json","User-Agent":"cinehub"})
            j=json.loads(urllib.request.urlopen(r,timeout=15).read().decode())
            if "result" in j: return j["result"]
            e=j.get("error")
        except Exception as x: e=x
    raise RuntimeError(e)
w=sys.argv[1] if len(sys.argv)>1 else ""
json.dump({"address":w},open("wallet.json","w"))
pad=w.lower()[2:].rjust(64,"0")
print("=== محفظة: %s ==="%w)
for s,(a,d) in TOK.items():
    try: print("%-6s: %s"%(s,int(rpc("eth_call",[{"to":a,"data":"0x70a08231"+pad},"latest"]),16)/10**d))
    except Exception as x: print("%-6s: تعذّر (%s)"%(s,str(x)[:40]))
try: print("ETH   : %s"%(int(rpc("eth_getBalance",[w,"latest"]),16)/1e18))
except Exception as x: print("ETH   : تعذّر")
print("المصدر: Base مباشرة — لا تقدير")
