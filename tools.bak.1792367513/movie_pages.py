#!/usr/bin/env python3
import json,os,re,html,hashlib
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
SITE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
CAP=int(os.environ.get("MOVIE_MAX","12000"))
try: cat=json.load(open("catalog.json",encoding="utf-8"))
except Exception: print("لا كتالوج"); raise SystemExit
IT=[x for x in (cat.get("items") or []) if isinstance(x,dict) and x.get("ia") and (x.get("th") or "").strip()]
if not IT: print("لا عناصر قابلة للتشغيل"); raise SystemExit
IT.sort(key=lambda x:-(x.get("v") or 0)); IT=IT[:CAP]
os.makedirs("m",exist_ok=True)
byg=defaultdict(list)
for x in IT:
    for g in re.split(r"[,\s]+",(str(x.get("g") or "")+" "+str(x.get("c") or "")))[:5]:
        if len(g)>2: byg[g.lower()].append(x)
def esc(s): return html.escape(str(s or ""))
used=set()
for x in IT:
    b=re.sub(r"[^A-Za-z0-9._-]","_",str(x["i"]))[:44]
    mp=b+"-"+hashlib.md5(str(x["i"]).encode()).hexdigest()[:6]+".html"
    while mp in used: mp="x"+mp
    used.add(mp); x["mp"]=mp
def render(x):
    t=x.get("t") or x["ia"]; th=x["th"]; mp=x["mp"]
    e=x.get("e") or ("https://archive.org/embed/"+x["ia"])
    gl=[g for g in re.split(r"[,\s]+",str(x.get("g") or "")) if len(g)>2][:6]
    rel=[]
    for g in gl[:2]:
        for y in byg.get(g.lower(),[]):
            if y["i"]!=x["i"] and y not in rel and len(rel)<8: rel.append(y)
    for y in IT[:80]:
        if y["i"]!=x["i"] and y not in rel and len(rel)<8: rel.append(y)
    desc=(x.get("d") or "مشاهدة %s اونلاين مجانًا بجودة عالية بدون تسجيل"%t)[:280]
    ld={"@context":"https://schema.org","@type":"Movie","name":t,"image":th,"url":SITE+"/m/"+mp,
        "inLanguage":"ar","genre":gl or ["أفلام"],"description":desc,"datePublished":str(x.get("y") or ""),
        "video":{"@type":"VideoObject","name":t,"thumbnailUrl":th,"embedUrl":e,"uploadDate":"2024-01-01"}}
    relh="".join('<a class=cd href="%s"><img loading=lazy src="%s" alt="%s"><b>%s</b></a>'%(
      esc(y["mp"]),esc(y.get("th")),esc(y.get("t")),esc(y.get("t"))) for y in rel)
    gh="".join('<a class=tag href="../g/%s.html">%s</a>'%(
      esc(re.sub(r"[^\w\s-]","",g,flags=re.UNICODE).strip().lower().replace(" ","-")),esc(g)) for g in gl)
    return mp, f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(t)} — مشاهدة اونلاين | CineHub 3099</title>
<meta name="description" content="{esc(desc[:150])}">
<link rel="canonical" href="{SITE}/m/{mp}">
<meta property="og:type" content="video.movie"><meta property="og:title" content="{esc(t)}">
<meta property="og:image" content="{esc(th)}"><meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{json.dumps(ld,ensure_ascii=False)}</script>
<style>
body{{font-family:system-ui,Tahoma;background:#070b10;color:#e9f1f8;margin:0;padding:12px 12px 90px;line-height:1.7}}
a{{color:#4cc2ff;text-decoration:none}}.wrap{{max-width:900px;margin:auto}}
.pl{{position:relative;width:100%;aspect-ratio:16/9;background:#000;border-radius:14px;overflow:hidden;border:1px solid rgba(255,255,255,.1)}}
.pl iframe{{width:100%;height:100%;border:0}}.head{{display:flex;gap:12px;margin:14px 0}}
.head img{{width:118px;height:176px;object-fit:cover;border-radius:12px;flex:0 0 auto}}
h1{{font-size:19px;margin:0 0 6px}}.mut{{color:#8ea3b8;font-size:13px}}
.tag{{display:inline-block;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:20px;padding:5px 11px;font-size:12px;margin:3px}}
.sh{{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}}.sh a{{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.1);border-radius:10px;padding:9px 13px;font-size:13px}}
.gr{{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px}}
.cd{{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;color:inherit}}
.cd img{{width:100%;height:165px;object-fit:cover;display:block}}.cd b{{display:block;font-size:12px;padding:6px;max-height:42px;overflow:hidden}}
</style></head><body><div class="wrap">
<div class="pl"><iframe src="{esc(e)}" allowfullscreen loading="lazy" title="{esc(t)}"></iframe></div>
<div class="head"><img src="{esc(th)}" alt="{esc(t)}">
<div><h1>{esc(t)}</h1><div class="mut">{esc(x.get("y") or "")} · مشاهدة مباشرة · مجانًا</div>
<div>{gh}</div><div class="sh">
<a href="https://wa.me/?text={esc(t)}%20{SITE}/m/{mp}" target="_blank" rel="noopener">واتساب</a>
<a href="https://t.me/share/url?url={SITE}/m/{mp}&text={esc(t)}" target="_blank" rel="noopener">تلغرام</a>
<a href="https://www.facebook.com/sharer/sharer.php?u={SITE}/m/{mp}" target="_blank" rel="noopener">فيسبوك</a>
<a href="https://twitter.com/intent/tweet?url={SITE}/m/{mp}&text={esc(t)}" target="_blank" rel="noopener">X</a>
<a href="../library.html">المكتبة</a></div></div></div>
<div class="chAd"></div><h2 style="font-size:16px">مقترحات مشابهة</h2><div class="gr">{relh}</div>
</div><script src="../ads.js"></script></body></html>'''
jobs=[]; urls=[]; skip=0
for x in IT:
    urls.append(SITE+"/m/"+x["mp"])
    if os.path.exists("m/"+x["mp"]) and os.path.getsize("m/"+x["mp"])>900: skip+=1; continue
    jobs.append(x)
def work(x):
    mp,h=render(x); open("m/"+mp,"w",encoding="utf-8").write(h); return mp
if jobs:
    with ThreadPoolExecutor(10) as ex: list(ex.map(work,jobs))
open("sitemap-m.xml","w",encoding="utf-8").write(
'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
"".join("  <url><loc>%s</loc></url>\n"%u for u in urls)+"</urlset>\n")
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("صفحات: %d موجودة | %d جديدة | إجمالي %d"%(skip,len(jobs),len(urls)))
