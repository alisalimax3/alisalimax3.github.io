#!/usr/bin/env python3
"""أرصدة حقيقية على شبكة Base عبر RPC عام."""
import json,os,urllib.request
RPC=os.environ.get("BASE_RPC","https://mainnet.base.org"); A=os.environ.get("WALLET_ADDRESS","")
TOK={"USDC":("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6),
     "USDT":("0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6),
     "VVV":("0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf",18)}
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
                             headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=20)).get("result")
out={"address":A,"rpc":RPC,"balances":{}}
if A:
    try: out["balances"]["ETH"]=int(rpc("eth_getBalance",[A,"latest"]),16)/1e18
    except Exception: pass
    for s,(addr,dec) in TOK.items():
        try:
            data="0x70a08231"+"0"*24+A.lower().replace("0x","")
            out["balances"][s]=int(rpc("eth_call",[{"to":addr,"data":data},"latest"]),16)/(10**dec)
        except Exception: pass
try:
    u="https://api.coingecko.com/api/v3/simple/price?ids=ethereum,venice-ai&vs_currencies=usd"
    pr=json.load(urllib.request.urlopen(u,timeout=15))
    px={"ETH":pr.get("ethereum",{}).get("usd",0),"VVV":pr.get("venice-ai",{}).get("usd",0),"USDC":1.0,"USDT":1.0}
except Exception: px={"ETH":0,"VVV":0,"USDC":1.0,"USDT":1.0}
out["prices"]=px
out["usd_total"]=round(sum(v*px.get(k,0) for k,v in out["balances"].items()),6)
print(json.dumps(out,indent=2))
