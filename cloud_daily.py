import glob,html,time,os,json,re,urllib.request
B="https://alkazmybwhwr-dot.github.io"
try: d=json.load(open("earnings-daily.json"))
except: d={"days":[]}
try: w=json.load(open("wallet.json"))
except: w={"balance":0}
t=time.strftime("%Y-%m-%d")
if not d["days"] or d["days"][-1].get("date")!=t: d["days"].append({"date":t,"balance":w.get("balance",0)})
d["days"]=d["days"][-400:]; json.dump(d,open("earnings-daily.json","w"),ensure_ascii=False,indent=2)
urls=[]
for f in sorted(glob.glob("*.html")+glob.glob("b/*.html")):
    if os.path.basename(f)=="404.html": continue
    urls.append(B+"/"+f.replace(os.sep,"/"))
it="".join('<item><title>%s</title><link>%s</link><guid>%s</guid></item>'%(html.escape(u.split('/')[-1]),u,u) for u in urls)
open("rss.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>CineHub 3099</title><link>%s/</link><description>أفلام وأرباح</description>%s</channel></rss>'%(B,it))
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"".join('<url><loc>%s</loc><lastmod>%s</lastmod></url>'%(u,t) for u in urls)+"</urlset>")
print("sitemap+rss:",len(urls))
if time.gmtime().tm_hour==6:
    k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
    if k and urls:
        data=json.dumps({"host":B.split("//")[1],"key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":urls[:900]}).encode()
        for ep in ["https://api.indexnow.org/indexnow","https://yandex.com/indexnow"]:
            try:
                r=urllib.request.Request(ep,data=data,headers={"Content-Type":"application/json; charset=utf-8"})
                print(ep.split('/')[2],urllib.request.urlopen(r,timeout=30).status)
            except Exception as e: print(ep.split('/')[2],e)
