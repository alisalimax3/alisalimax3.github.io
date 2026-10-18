#!/usr/bin/env python3
import os,json,random,urllib.request,datetime,html
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io"); host=SITE.replace("https://","")
urls=[SITE+"/"]
for d in ("p","x"):
    if os.path.isdir(d): urls+=[SITE+"/%s/%s"%(d,f) for f in sorted(os.listdir(d))[:600] if f.endswith(".html")]
kp="indexnow-key.txt"
key=open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
open(kp,"w").write(key); open(key+".txt","w").write(key)
body=json.dumps({"host":host,"key":key,"keyLocation":SITE+"/"+key+".txt","urlList":urls[:10000]}).encode()
for ep in ("https://api.indexnow.org/indexnow","https://yandex.com/indexnow","https://search.seznam.cz/indexnow"):
    try:
        r=urllib.request.Request(ep,data=body,headers={"Content-Type":"application/json; charset=utf-8"})
        print("indexnow",ep.split("/")[2],urllib.request.urlopen(r,timeout=30).status)
    except Exception as e: print("skip",str(e)[:40])
try:
    cat=json.load(open("catalog.json",encoding="utf-8"))["items"][:60]
except Exception: cat=[]
try:
    ad=json.load(open("adult.json",encoding="utf-8"))["items"][:30]
except Exception: ad=[]
now=datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
it="".join('<item><title>%s</title><link>%s</link><guid>%s</guid><pubDate>%s</pubDate><description>%s</description></item>'%(
 html.escape(x["t"]),SITE+"/play.html?id="+x["i"],SITE+"/play.html?id="+x["i"],now,html.escape(x.get("c") or "فيلم")) for x in cat)
it+="".join('<item><title>%s</title><link>%s</link><guid>%s</guid><pubDate>%s</pubDate><description>للكبار</description></item>'%(
 html.escape(x["t"]),SITE+"/adult.html?v="+x["i"],SITE+"/adult.html?v="+x["i"],now) for x in ad)
open("rss.xml","w",encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title><link>%s</link><description>أفلام + كبار</description>%s</channel></rss>'%(SITE,it))
open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\nSitemap: %s/sitemap-x.xml\n"%(SITE,SITE))
print("urls",len(urls),"| rss",len(cat)+len(ad))
