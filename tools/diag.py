#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يفحص ما هو منشور فعلًا على الموقع الحي ويكتب diag.json — بلا تخمين"""
import json,os,urllib.request,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
LIVE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
FILES=["index.html","library.html","adult.html","play.html","watch.html","go.html","earn.html",
       "rise.html","agent.html","withdraw.html","keys.html","share.html","rails.html","tower.html",
       "rewards.html","cinema.html","auto.html","surveys.html","audit.html","live-dash.html","diag.html",
       "nav.js","ads.js","authtoken.js","catalog.json","adult.json","auth.json","browse.json",
       "keys-status.json","tasks.json","rewards.json","treasury.json","revenue.json","registry.json",
       "sitemap.xml","rss.xml","robots.txt"]
def head(u):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,method="HEAD",headers={"User-Agent":"ch3099"}),timeout=20)
        return r.status
    except Exception as e:
        return getattr(e,"code",0)
res={}
for f in FILES: res[f]=head("%s/%s?d=%s"%(LIVE,f,int(datetime.datetime.now().timestamp())))
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
cat=L("catalog.json",{}); ad=L("adult.json",{}); br=L("browse.json",{}); ks=L("keys-status.json",{})
rw=L("rewards.json",{}); tr=L("treasury.json",{}); pu=L("pulse.json",{}); rg=L("registry.json",{})
out={"at":datetime.datetime.now(datetime.timezone.utc).isoformat(),
     "live":res,"ok":sum(1 for v in res.values() if v==200),"total":len(res),
     "missing":[f for f,v in res.items() if v!=200],
     "content":{"films":cat.get("count",0),"adult":ad.get("count",0),
                "film_pages":len(os.listdir("p")) if os.path.isdir("p") else 0,
                "tag_pages":len(os.listdir("x")) if os.path.isdir("x") else 0},
     "agent":{"ad_requests":br.get("ad_requests",0),"browse_runs":br.get("runs",0),
              "cycles":pu.get("cycle",0),"rewards":rw.get("total",0),
              "valid_keys":ks.get("valid",0),"keys_total":ks.get("checked",0)},
     "money":{"balance":tr.get("balance",0),"buckets":tr.get("buckets",{}),
              "platforms":rg.get("counts",{}).get("sites",0)}}
json.dump(out,open("diag.json","w"),ensure_ascii=False,indent=1)
print("حيّ %d/%d | غائب: %s"%(out["ok"],out["total"],", ".join(out["missing"][:8]) or "لا شيء"))
print("أفلام %d · كبار %d · طلبات إعلان %d · دورات %d"%(cat.get("count",0),ad.get("count",0),br.get("ad_requests",0),pu.get("cycle",0)))
