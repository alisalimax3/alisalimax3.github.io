#!/usr/bin/env python3
"""حل حقيقي للكابتشا عبر 2Captcha (reCAPTCHA v2/v3 + Turnstile)."""
import sys,os,time,json,urllib.request,urllib.parse
K=os.environ.get("CAPTCHA_API_KEY","")
def post(u,p):
    r=urllib.request.Request(u,data=urllib.parse.urlencode(p).encode(),
        headers={"content-type":"application/x-www-form-urlencoded"})
    return urllib.request.urlopen(r,timeout=45).read().decode()
def solve(sitekey,pageurl,kind="recaptcha",action=None):
    if not K: return {"ok":False,"error":"no_CAPTCHA_API_KEY"}
    p={"key":K,"pageurl":pageurl,"json":1}
    if kind=="turnstile": p.update({"method":"turnstile","sitekey":sitekey})
    else:
        p.update({"method":"userrecaptcha","googlekey":sitekey})
        if kind=="recaptcha_v3": p.update({"version":"v3","action":action or "verify","min_score":"0.7"})
    r=json.loads(post("https://2captcha.com/in.php",p))
    if r.get("status")!=1: return {"ok":False,"error":r.get("request")}
    cid=r["request"]
    for i in range(40):
        time.sleep(5)
        g=json.loads(post("https://2captcha.com/res.php",{"key":K,"action":"get","id":cid,"json":1}))
        if g.get("status")==1: return {"ok":True,"token":g["request"],"id":cid,"seconds":(i+1)*5}
        if g.get("request")!="CAPCHA_NOT_READY": return {"ok":False,"error":g.get("request")}
    return {"ok":False,"error":"timeout"}
def balance():
    if not K: return None
    try: return json.loads(post("https://2captcha.com/res.php",{"key":K,"action":"getbalance","json":1})).get("request")
    except Exception: return None
if __name__=="__main__":
    c=sys.argv[1] if len(sys.argv)>1 else "balance"
    if c=="balance": print(json.dumps({"ok":True,"balance":balance()}))
    elif c=="solve": print(json.dumps(solve(sys.argv[2],sys.argv[3],sys.argv[4] if len(sys.argv)>4 else "recaptcha")))
