#!/usr/bin/env python3
import json,os,re,html,traceback
from collections import Counter
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
def S(v):
    if v is None: return ""
    if isinstance(v,list): return ",".join(S(x) for x in v)
    if isinstance(v,dict): return S(v.get("name") or v.get("title") or "")
    return str(v)
E=html.escape
def slug(x):
    s=re.sub(r"[^\w\s-]","",S(x),flags=re.UNICODE).strip().lower()
    return re.sub(r"\s+","-",s)[:32] or "k"
def link(x): return "m/"+x["mp"] if x.get("mp") else "play.html?id="+S(x.get("i"))
def build(field,dirn,idx,title,src,minn):
    cnt=Counter()
    for x in src:
        for k in re.split(r"[,\s]+",S(x.get(field))):
            k=k.strip().lower()
            if 2<len(k)<26 and not k.isdigit(): cnt[k]+=1
    top=[(k,v) for k,v in cnt.most_common(700) if v>=minn][:350]
    os.makedirs(dirn,exist_ok=True); used={}; items=[]; urls=[]
    for kw,v in top:
        sel=[x for x in src if kw in S(x.get(field)).lower() or kw in S(x.get("t")).lower()][:60]
        if len(sel)<minn: continue
        s=slug(kw)
        while s in used: s+="-2"
        used[s]=1; fn=s+".html"
        cards="".join('<a class=cd href="../%s"><img loading=lazy src="%s" alt="%s"><b>%s</b></a>'%(
          E(link(x)),E(x.get("th")),E(x.get("t")),E(x.get("t"))) for x in sel)
        open(dirn+"/"+fn,"w",encoding="utf-8").write(
'<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'
'<meta name="viewport" content="width=device-width,initial-scale=1">'
'<title>%s — CineHub 3099</title><meta name="description" content="%d عنوان عن %s">'
'<link rel="canonical" href="%s/%s/%s"><style>'
'body{font-family:system-ui,Tahoma;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 74px;line-height:1.7}'
'a{color:#4cc2ff;text-decoration:none}.gr{display:grid;grid-template-columns:repeat(auto-fill,minmax(122px,1fr));gap:10px}'
'.cd{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;color:inherit}'
'.cd img{width:100%%;height:165px;object-fit:cover;display:block}.cd b{display:block;font-size:12px;padding:6px;max-height:42px;overflow:hidden}'
'</style></head><body><h1>%s <span style="color:#8ea3b8;font-size:14px">· %d</span></h1><div class="gr">%s</div>'
'<p><a href="../genres.html">الأنواع</a> · <a href="../keywords.html">الكلمات</a> · <a href="../library.html">المكتبة</a></p></body></html>'%(
 E(kw),len(sel),E(kw),SITE,dirn,fn,E(kw),len(sel),cards))
        urls.append("%s/%s/%s"%(SITE,dirn,fn)); items.append({"k":kw,"f":fn,"n":len(sel)})
    json.dump({"count":len(items),"made":len(items),"items":items},open(idx+".json","w",encoding="utf-8"),ensure_ascii=False)
    open("sitemap-%s.xml"%("k" if idx=="keywords" else "g"),"w",encoding="utf-8").write(
'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
"".join("  <url><loc>%s</loc></url>\n"%u for u in urls)+"</urlset>\n")
    open(idx+".html","w",encoding="utf-8").write(
'<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'
'<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s — CineHub 3099</title><style>'
'body{font-family:system-ui,Tahoma;background:#070b10;color:#e9f1f8;margin:0;padding:14px;line-height:1.7}'
'a{color:#4cc2ff;text-decoration:none}.ch{display:flex;gap:6px;flex-wrap:wrap}'
'.ch a{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:20px;padding:7px 13px;font-size:13px}'
'.c{color:#8ea3b8;font-size:13px}</style></head><body><h1>%s <span class="c" id="n"></span></h1><div class="ch" id="ch"></div>'
'<script>fetch("%s.json?_="+Date.now()).then(function(r){return r.json()}).then(function(d){'
'document.getElementById("n").textContent="· "+d.count+" · "+d.made+" صفحة";'
'document.getElementById("ch").innerHTML=d.items.map(function(i){return "<a href=\'%s/"+encodeURIComponent(i.f)+"\'>"+i.k+"</a>";}).join("");});</script></body></html>'%(
 title,title,idx,dirn))
    print("  %s: %d صفحة"%(title,len(items)))
try:
    cat=json.load(open("catalog.json",encoding="utf-8"))
    src=[x for x in (cat.get("items") or []) if isinstance(x,dict) and x.get("ia")]
    print("  قابل للتشغيل: %d"%len(src))
    build("g","k","keywords","الكلمات المفتاحية",src,4)
    build("c","g","genres","الأنواع",src,3)
    rob="User-agent: *\nAllow: /\n"
    for f in ("sitemap.xml","sitemap-m.xml","sitemap-k.xml","sitemap-g.xml"):
        if os.path.exists(f): rob+="Sitemap: %s/%s\n"%(SITE,f)
    open("robots.txt","w",encoding="utf-8").write(rob)
except Exception: traceback.print_exc()
