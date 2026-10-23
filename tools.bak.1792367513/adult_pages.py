#!/usr/bin/env python3
import json,os,re,html as H
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
SITE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
if not os.path.exists("adult.json"): print("لا adult.json"); raise SystemExit
d=json.load(open("adult.json",encoding="utf-8"))
os.makedirs("x",exist_ok=True)
def slug(s): return (re.sub(r"[^\w\s-]","",s).strip().lower().replace(" ","-")[:40] or "tag")
urls=[]
for t in d.get("tags",[])[:60]:
    it=[x for x in d["items"] if t in x["g"]][:24]
    if not it: continue
    s=slug(t)
    cards="".join("<a class='c' href='../adult.html?v=%s'><img loading='lazy' src='%s'><b>%s</b></a>"%(H.escape(x["i"]),x["th"],H.escape(x["t"])) for x in it)
    open("x/%s.html"%s,"w",encoding="utf-8").write(
"""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%s — فيديو للكبار | CineHub 3099</title>
<meta name="description" content="%d فيديو %s مجانًا — مشاهدة مباشرة وأرباح حقيقية.">
<link rel="canonical" href="%s/x/%s.html">
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px;line-height:1.7}
a{color:#4cc2ff}.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:10px}
.c{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;text-decoration:none;color:inherit}
.c img{width:100%;height:95px;object-fit:cover;display:block}.c b{display:block;font-size:12px;padding:6px}
.ad{border:1px dashed rgba(255,255,255,.2);border-radius:12px;padding:12px;text-align:center;color:#8ea3b8;margin:12px 0}</style>
</head><body><h1>%s</h1><div class="ad">إعلان</div><div class="g">%s</div>
<p><a href="../adult.html">كل فيديو الكبار</a> · <a href="../index.html">الرئيسية</a></p></body></html>"""%(H.escape(t),len(it),H.escape(t),SITE,s, H.escape(t),cards))
    urls.append("%s/x/%s.html"%(SITE,s))
open("sitemap-x.xml","w",encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+"".join("  <url><loc>%s</loc></url>\n"%u for u in urls)+"</urlset>\n")
open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\nSitemap: %s/sitemap-x.xml\n"%(SITE,SITE))
print("صفحات وسوم:",len(urls))
