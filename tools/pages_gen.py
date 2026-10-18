#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""صفحات long-tail لكل عنصر + sitemap + robots + IndexNow"""
import os,re,json,random,urllib.request,urllib.parse,html as H
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
OUT="p"; SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io")
LIMIT=int(os.environ.get("PAGES_LIMIT","200"))
KIND=["فيلم كلاسيكي","فيلم قصير","وثائقي","رسوم متحركة","فيلم نوار","تحفة صامتة","مغامرات","دراما","كوميديا","خيال علمي"]
def slug(s):
    s=re.sub(r"[^\w\s-]","",s,flags=re.U).strip().lower()
    return (re.sub(r"[\s_]+","-",s)[:60] or "item")
def load():
    bag=[]
    for f in ("films.json","catalog.json","library.json","registry.json"):
        if not os.path.exists(f): continue
        try: d=json.load(open(f,encoding="utf-8"))
        except Exception: continue
        if isinstance(d,list): bag+=d
        elif isinstance(d,dict):
            for k in ("items","films","list","entities","results"):
                if isinstance(d.get(k),list): bag+=d[k]
    seen=set(); out=[]
    for x in bag:
        if not isinstance(x,dict): continue
        t=(x.get("title") or x.get("name") or "").strip()
        if not t: continue
        s=slug(t)
        if s in seen: continue
        seen.add(s); out.append((s,t,x))
    return out
TPL="""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t} — مشاهدة مجانية | CineHub 3099</title>
<meta name="description" content="{d}"><link rel="canonical" href="{site}/p/{s}.html">
<script type="application/ld+json">{{"@context":"https://schema.org","@type":"Movie","name":{tj},"genre":{kj},"inLanguage":"ar"}}</script>
<style>body{{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:16px;line-height:1.8}}
a{{color:#4cc2ff}}.box{{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:12px;margin:12px 0}}
.btn{{display:inline-block;background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border-radius:10px;padding:9px 14px;text-decoration:none;margin:4px}}
.ad{{border:1px dashed rgba(255,255,255,.15);border-radius:10px;padding:10px;text-align:center;color:#8ea3b8;font-size:13px}}</style>
</head><body><h1>{t}</h1><p>{d}</p>
<div class="ad">إعلان — {n1}</div>
<p><a class="btn" href="../auto.html">▶ شاهد واقبض</a><a class="btn" href="../index.html">الرئيسية</a><a class="btn" href="../sites.html">90 ألف موقع</a></p>
<div class="box"><b>النوع:</b> {k} · <b>الحقوق:</b> ملك عام / مرخّص · <b>المصدر:</b> {src}</div>
<div class="ad">إعلان — {n2}</div><h3>مشاهدات مقترحة</h3><ul>{rel}</ul></body></html>"""
def main():
    it=load()
    if not it: print("لا عناصر"); return
    os.makedirs(OUT,exist_ok=True); take=it[:LIMIT]; urls=[]
    for i,(s,t,x) in enumerate(take):
        k=KIND[i%len(KIND)]
        d="مشاهدة %s مجانًا داخل CineHub 3099 — %s قانوني، مع أرباح مباشرة وسحب لبنك الكريمي."%(t,k)
        rel="".join('<li><a href="%s.html">%s</a></li>'%(take[(i+j*7)%len(take)][0],H.escape(take[(i+j*7)%len(take)][1])) for j in range(1,7))
        open(os.path.join(OUT,s+".html"),"w",encoding="utf-8").write(TPL.format(
            t=H.escape(t),s=s,d=H.escape(d),k=k,kj=json.dumps(k,ensure_ascii=False),
            tj=json.dumps(t,ensure_ascii=False),site=SITE,src=H.escape(str(x.get("source") or "Archive / Public Domain")),
            n1="Adsterra" if i%2 else "Monetag", n2="Linkvertise" if i%2 else "BitLabs", rel=rel))
        urls.append("%s/p/%s.html"%(SITE,s))
    open("sitemap.xml","w",encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+"".join("  <url><loc>%s</loc></url>\n"%u for u in [SITE+"/"]+urls)+"</urlset>\n")
    open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n"%SITE)
    kp="indexnow-key.txt"
    key=open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
    open(kp,"w").write(key); open(key+".txt","w").write(key)
    try:
        r=urllib.request.Request("https://api.indexnow.org/indexnow",
            data=json.dumps({"host":SITE.replace("https://",""),"key":key,"keyLocation":SITE+"/"+key+".txt","urlList":urls[:10000]}).encode(),
            headers={"Content-Type":"application/json; charset=utf-8"})
        print("indexnow",urllib.request.urlopen(r,timeout=30).status)
    except Exception as e: print("indexnow skip",e)
    print("pages",len(urls))
main()
