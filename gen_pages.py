#!/usr/bin/env python3
import json, urllib.request, html, os
KEY="8265bd1679663a7ea12ac168da84d2e8"
SITE="https://alisalimax3.github.io"; IMG="https://image.tmdb.org/t/p/w300"
os.makedirs("b",exist_ok=True)
def get(u,d=None):
    h={"User-Agent":"cinehub","Accept":"application/json"}
    b=json.dumps(d).encode() if d else None
    if b: h["Content-Type"]="application/json"
    with urllib.request.urlopen(urllib.request.Request(u,data=b,headers=h),timeout=40) as r:
        return json.loads(r.read())
def esc(s): return html.escape(str(s or ""),quote=True)

TPL = """<!DOCTYPE html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>__T__ | CineHub 3099</title>
<meta name="description" content="__D__">
<meta property="og:title" content="__T__"><meta property="og:description" content="__D__">
<meta property="og:type" content="website"><meta property="og:url" content="__URL__">
<link rel="canonical" href="__URL__"><link rel="manifest" href="__S__/manifest.json">
<script type="application/ld+json">__LD__</script>
<style>
body{margin:0;background:#0b0d14;color:#e9ecf5;font:15px/1.6 system-ui,Tahoma,sans-serif}
.w{max-width:1050px;margin:0 auto;padding:20px 14px 50px}
h1{font-size:22px;margin:8px 0}.d{opacity:.7;font-size:13.5px;margin-bottom:16px}
nav a{color:#8ea2ff;text-decoration:none;margin-left:12px;font-size:13px}
.g{display:grid;gap:11px;grid-template-columns:repeat(auto-fill,minmax(126px,1fr))}
.c{color:inherit;text-decoration:none;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden}
.c:hover{border-color:#6c7cff}
.th{position:relative;aspect-ratio:2/3;background:#12141f;display:flex;align-items:center;justify-content:center;font-size:26px}
.th img{width:100%;height:100%;object-fit:cover}
.k,.r{position:absolute;font-style:normal;font-size:10px;padding:3px 6px;border-radius:6px;background:rgba(0,0,0,.75);color:#fff}
.k{top:5px;right:5px}.r{bottom:5px;left:5px;color:#ffd166}
.c b{display:block;font-size:12px;padding:7px 8px 0;line-height:1.3}
.c i{font-style:normal;font-size:10.5px;opacity:.55;padding:0 8px 8px;display:block}
</style></head><body><div class="w">
<nav>__NAV__</nav><h1>__T__</h1><p class="d">__D__</p>
<div class="g">__CARDS__</div>
<p style="margin-top:26px;font-size:12px;opacity:.5">CineHub 3099</p>
</div>
<div style="text-align:center;padding:12px"><a href="__S__/revenue.html" style="color:#8ea2ff;font-size:12px">الأرباح</a></div>
</body></html>"""

PAGES=[]; NAVLINKS=[]
def page(slug,title,desc,items,pre):
    cards=""
    for it in items:
        cards+=('<a class="c" href="%s/?w=%s%s"><div class="th">%s<em class="k">%s</em>%s</div><b>%s</b><i>%s</i></a>')%(
            SITE,pre,esc(it["id"]),
            ('<img loading="lazy" src="%s" alt="%s">'%(esc(it["img"]),esc(it["t"]))) if it.get("img") else "<span>▶</span>",
            esc(it.get("k","")), ('<em class="r">★ %s</em>'%esc(it["r"])) if it.get("r") else "",
            esc(it["t"]), esc(it.get("y","")))
    nav='<a href="%s/">الرئيسية</a>'%SITE + "".join('<a href="%s/b/%s.html">%s</a>'%(SITE,s,n) for s,n in NAVLINKS)
    ld=json.dumps({"@context":"https://schema.org","@type":"ItemList","name":title,"numberOfItems":len(items),
        "itemListElement":[{"@type":"ListItem","position":i+1,"name":x["t"],"url":SITE+"/?w="+pre+x["id"]}
        for i,x in enumerate(items)]},ensure_ascii=False)
    doc=TPL
    for k,v in (("__T__",esc(title)),("__D__",esc(desc)),("__URL__",SITE+"/b/"+slug+".html"),
                ("__S__",SITE),("__LD__",ld),("__NAV__",nav),("__CARDS__",cards)):
        doc=doc.replace(k,v)
    open("b/%s.html"%slug,"w",encoding="utf-8").write(doc); PAGES.append(slug)

def rows(res,kind,yk="release_date"):
    out=[]
    for x in res:
        out.append({"id":str(x["id"]),"t":x.get("title") or x.get("name") or "",
          "y":(x.get(yk) or "")[:4],"img":IMG+x["poster_path"] if x.get("poster_path") else "",
          "k":kind,"r":("%.1f"%x["vote_average"]) if x.get("vote_average") else ""})
    return [r for r in out if r["t"]][:24]

# أفلام حسب السنة
for y in (2026,2025,2024,2023,2022):
    r=get("https://api.themoviedb.org/3/discover/movie?api_key=%s&language=ar&sort_by=popularity.desc&primary_release_year=%d"%KEY % y) if False else \
      get("https://api.themoviedb.org/3/discover/movie?api_key={}&language=ar&sort_by=popularity.desc&primary_release_year={}".format(KEY,y))
    page("movies-%d"%y,"أفلام %d — الأكثر مشاهدة"%y,"أفضل أفلام %d مترجمة مع مشاهدة مباشرة بلا تسجيل."%y,
         rows(r.get("results",[]),"فيلم"),"m")
    NAVLINKS.append(("movies-%d"%y,"أفلام %d"%y))
# أعلى تقييم
r=get("https://api.themoviedb.org/3/movie/top_rated?api_key={}&language=ar".format(KEY))
page("top-rated","أفضل الأفلام تقييمًا","أعلى الأفلام تقييمًا على الإطلاق — مشاهدة مباشرة.",rows(r.get("results",[]),"فيلم"),"m")
NAVLINKS.append(("top-rated","الأعلى تقييمًا"))
# تصنيفات
for gid,gn in ((28,"أكشن"),(35,"كوميدي"),(27,"رعب"),(16,"أنيميشن"),(878,"خيال علمي")):
    r=get("https://api.themoviedb.org/3/discover/movie?api_key={}&language=ar&with_genres={}&sort_by=popularity.desc".format(KEY,gid))
    page("genre-%d"%gid,"أفلام %s"%gn,"أفضل أفلام %s مترجمة — مشاهدة مباشرة."%gn,rows(r.get("results",[]),"فيلم"),"m")
    NAVLINKS.append(("genre-%d"%gid,gn))
# مسلسلات
r=get("https://api.themoviedb.org/3/tv/popular?api_key={}&language=ar".format(KEY))
page("tv-popular","أشهر المسلسلات","أشهر المسلسلات العالمية مع مشاهدة مباشرة.",rows(r.get("results",[]),"مسلسل","first_air_date"),"t")
NAVLINKS.append(("tv-popular","مسلسلات"))
# أنمي
q='{Page(perPage:24){media(type:ANIME,sort:POPULARITY_DESC){id idMal title{english romaji} coverImage{large} averageScore startDate{year}}}}'
r=get("https://graphql.anilist.co",{"query":q})
an=[{"id":str(a["id"]),"t":(a["title"].get("english") or a["title"].get("romaji") or ""),
     "y":str((a.get("startDate") or {}).get("year") or ""),"img":(a.get("coverImage") or {}).get("large") or "",
     "k":"أنمي","r":"%.1f"%(a["averageScore"]/10) if a.get("averageScore") else ""} for a in r["data"]["Page"]["media"]]
page("anime-popular","أشهر الأنمي","أشهر الأنمي مترجم — مشاهدة مباشرة بلا تسجيل.",an,"a")
NAVLINKS.append(("anime-popular","أنمي"))

print("✓ %d صفحة في b/"%len(PAGES))
u=["","index.html","revenue.html","partners.html"]+["b/%s.html"%s for s in PAGES]
sm='<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
for x in u: sm+="<url><loc>%s/%s</loc></url>\n"%(SITE,x)
sm+="</urlset>\n"
open("sitemap.xml","w",encoding="utf-8").write(sm)
open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n"%SITE)
print("✓ sitemap · robots")
