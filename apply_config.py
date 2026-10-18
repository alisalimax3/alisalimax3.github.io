import json,re,os,hashlib,sys
E={}
for line in open("config.env",encoding="utf-8"):
    m=re.match(r'^\s*([A-Z_]+)\s*=\s*"(.*)"\s*$',line)
    if m: E[m.group(1)]=m.group(2)
def rw(f,fn):
    if not os.path.exists(f): return
    s=open(f,encoding="utf-8").read(); n=fn(s)
    if n!=s: open(f,"w",encoding="utf-8").write(n)
# ads
def a(s):
    d=json.loads(s)
    d["banners"]["top"]["key"]=E.get("ADSTERRA_TOP_KEY","") or d["banners"]["top"]["key"]
    d["banners"]["mid"]["key"]=E.get("ADSTERRA_MID_KEY","") or d["banners"]["mid"]["key"]
    d["banners"]["side"]["key"]=E.get("ADSTERRA_SIDE_KEY","") or d["banners"]["side"]["key"]
    d["banners"]["mobile"]["key"]=E.get("ADSTERRA_MOBILE_KEY","") or d["banners"]["mobile"]["key"]
    d["socialbar_src"]=E.get("ADSTERRA_SOCIALBAR_SRC","") or d["socialbar_src"]
    d["popunder_src"]=E.get("ADSTERRA_POPUNDER_SRC","") or d["popunder_src"]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("ads-config.json",a)
# revenue
def r(s):
    d=json.loads(s); d["smartlink"]=E.get("ADSTERRA_SMARTLINK","") or d.get("smartlink","")
    d["cpx_app"]=E.get("CPX_APP_ID","")
    for o in d["offerwalls"]:
        if o["id"]=="cpx" and E.get("CPX_APP_ID"): o["enabled"]=True
        if o["id"]=="adgate" and E.get("ADGATE_URL"): o["src"]=E["ADGATE_URL"]; o["enabled"]=True
        if o["id"]=="bitlabs" and E.get("BITLABS_URL"): o["src"]=E["BITLABS_URL"]; o["enabled"]=True
    for af in d["affiliates"]:
        k={"binance":"AFF_BINANCE","bybit":"AFF_BYBIT","okx":"AFF_OKX"}.get(af["id"])
        if k and E.get(k): af["url"]=E[k]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("revenue.json",r)
# kuraimi
def k(s):
    d=json.loads(s)
    d["holder"]=E.get("KURAIMI_HOLDER","") or d["holder"]
    d["account"]=E.get("KURAIMI_ACCOUNT","") or d["account"]
    d["branch"]=E.get("KURAIMI_BRANCH","") or d["branch"]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("kuraimi.json",k)
# captcha
rw("captcha.js", lambda s: re.sub(r"var SITEKEY='[^']*'","var SITEKEY='%s'"%E.get("TURNSTILE_SITEKEY","1x00000000000000000000AA"),s))
# auth: admin hash + secret
rw("auth.js", lambda s: re.sub(r"ADMIN_SHA='[0-9a-f]{64}'","ADMIN_SHA='%s'"%hashlib.sha256(E.get("ADMIN_PASSWORD","cinehub3099").encode()).hexdigest(),s))
if os.path.exists(".license-secret"):
    sec=open(".license-secret").read().strip()
    rw("auth.js", lambda s: re.sub(r"SECRET='[^']*'","SECRET='%s'"%sec,s))
# endpoint
ep=E.get("APPS_SCRIPT_URL","")
for f in ("payout.js","rev.js"):
    rw(f, lambda s: re.sub(r"localStorage\.getItem\('ch_endpoint'\)\s*\|\|\s*'[^']*'",
                           "localStorage.getItem('ch_endpoint') || '%s'"%ep, s))
# api.gs secrets
rw("api.gs", lambda s: re.sub(r"TURNSTILE_SECRET = '[^']*'","TURNSTILE_SECRET = '%s'"%E.get("TURNSTILE_SECRET",""),s))
print("  طُبّق الإعداد")
