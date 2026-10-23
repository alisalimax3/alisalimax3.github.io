#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
mkdir -p "$HOME/tmp3099"
LOG="$HOME/tmp3099/daily.log"
S="https://alisalimax3.github.io"
log(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
log "── مهمة يومية ──"
python3 - <<'PY'
import json,time
p="earnings-daily.json"
try: d=json.load(open(p))
except: d={"days":[]}
try: w=json.load(open("wallet.json"))
except: w={"balance":0}
d["days"].append({"date":time.strftime("%Y-%m-%d"),"balance":w.get("balance",0)})
d["days"]=d["days"][-400:]
json.dump(d,open(p,"w"),ensure_ascii=False,indent=2)
print("  لقطة:",d["days"][-1])
PY
python3 - <<'PY'
import glob,html,time,os
urls=[]
for f in sorted(glob.glob("*.html")+glob.glob("b/*.html")):
    if os.path.basename(f)=="404.html": continue
    urls.append("https://alisalimax3.github.io/"+f.replace(os.sep,"/"))
items="".join("<item><title>%s</title><link>%s</link><guid>%s</guid></item>"%(html.escape(u.split('/')[-1]),u,u) for u in urls)
open("rss.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>CineHub 3099</title><link>https://alisalimax3.github.io/</link><description>أفلام وأرباح</description>'+items+'</channel></rss>')
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"".join("<url><loc>%s</loc><lastmod>%s</lastmod></url>"%(u,time.strftime('%Y-%m-%d')) for u in urls)+"</urlset>")
print("  sitemap+rss:",len(urls))
PY
python3 - <<'PY'
import glob,re,json,urllib.request,os
B="https://alisalimax3.github.io"
k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
if k and U:
    d=json.dumps({"host":"alisalimax3.github.io","key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
    for ep in ["https://api.indexnow.org/indexnow","https://yandex.com/indexnow"]:
        try:
            r=urllib.request.Request(ep,data=d,headers={"Content-Type":"application/json; charset=utf-8"})
            print("  ",ep.split('/')[2],urllib.request.urlopen(r,timeout=30).status)
        except Exception as e: print("  ",ep.split('/')[2],e)
else: print("  IndexNow: لا مفتاح")
PY
git add -A >/dev/null 2>&1
git commit -qm "daily $(date +%F)" >/dev/null 2>&1
bash deploy.sh main "auto $(date -u +%FT%TZ)"&1 && log "  ✓ نُشر" || log "  ⚠ فشل الدفع"
log "── انتهى ──"
