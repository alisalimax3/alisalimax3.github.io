#!/usr/bin/env python3
import json, urllib.request, html, os
KEY="8265bd1679663a7ea12ac168da84d2e8"
SITE="https://alisalimax3.github.io"; IMG="https://image.tmdb.org/t/p/w300"
L=[("en","en-US","Popular Movies","Popular TV","Watch free, no signup"),
   ("es","es-ES","Películas Populares","Series Populares","Ver gratis, sin registro"),
   ("fr","fr-FR","Films Populaires","Séries Populaires","Regarder gratuitement"),
   ("id","id-ID","Film Populer","Serial Populer","Nonton gratis tanpa daftar"),
   ("tr","tr-TR","Popüler Filmler","Popüler Diziler","Ücretsiz izle, kayıt yok"),
   ("pt","pt-BR","Filmes Populares","Séries Populares","Assista grátis, sem cadastro")]
def get(u):
    h={"User-Agent":"cinehub","Accept":"application/json"}
    with urllib.request.urlopen(urllib.request.Request(u,headers=h),timeout=40) as r: return json.loads(r.read())
def esc(s): return html.escape(str(s or ""),quote=True)
ALT="".join('<link rel="alternate" hreflang="%s" href="%s/%s/">'%(c,SITE,d if d!="en" else "en") for d,c,_,_,_ in L)
ALT+='<link rel="alternate" hreflang="ar" href="%s/">'%SITE
ALT+='<link rel="alternate" hreflang="x-default" href="%s/">'%SITE

for d,code,mv,tv,sub in L:
    os.makedirs(d,exist_ok=True)
    r=get("https://api.themoviedb.org/3/movie/popular?api_key={}&language={}".format(KEY,code))
    cards=""
    for x in r.get("results",[])[:18]:
        if not x.get("poster_path"): continue
        cards+='<a class="c" href="%s/?w=m%d"><div class="th"><img loading="lazy" src="%s%s" alt="%s"></div><b>%s</b></a>'%(
            SITE,x["id"],IMG,x["poster_path"],esc(x.get("title","")),esc(x.get("title","")))
    nav="".join('<a href="%s/%s/">%s</a>'%(SITE,dd,cc.upper()) for dd,cc,_,_,_ in L)
    doc='''<!DOCTYPE html><html lang="__L__" dir="ltr"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>__T__ | CineHub 3099</title>
<meta name="description" content="__S__ — CineHub 3099">
<link rel="canonical" href="__U__">__ALT__
<meta property="og:title" content="__T__"><meta property="og:type" content="website">
<style>
body{margin:0;background:#0b0d14;color:#e9ecf5;font:15px/1.6 system-ui,Tahoma,sans-serif}
.w{max-width:1050px;margin:0 auto;padding:20px 14px 50px}
h1{font-size:22px}.g{display:grid;gap:11px;grid-template-columns:repeat(auto-fill,minmax(120px,1fr))}
.c{color:inherit;text-decoration:none;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden}
.th{aspect-ratio:2/3;background:#12141f}.th img{width:100%;height:100%;object-fit:cover}
.c b{display:block;font-size:12px;padding:7px 8px;line-height:1.3}
nav a{color:#8ea2ff;text-decoration:none;margin-right:10px;font-size:13px}
</style></head><body><div class="w">
<nav>__NAV__</nav>
<h1>__T__</h1><p style="opacity:.7">__S__</p>
<div class="g">__C__</div>
<p style="margin-top:26px;font-size:12px;opacity:.5">CineHub 3099 — movies · series · anime · live radio</p>
</div></body></html>'''
    for k,v in (("__L__",d),("__T__",esc(mv+" · CineHub 3099")),("__S__",esc(sub)),
                ("__U__",SITE+"/"+d+"/"),("__ALT__",ALT),("__NAV__",nav),("__C__",cards)):
        doc=doc.replace(k,v)
    open(d+"/index.html","w",encoding="utf-8").write(doc)
    print("  ✓ /%s/"%d)
print("✓ صفحات دولية: %d"%len(L))
