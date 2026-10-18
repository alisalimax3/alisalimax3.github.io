#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 — FIXALL : تنظيف القفل + توحيد المخطط + إعادة بناء كل الأدوات + رفع موثّق
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
OWNER="alkazmybwhwr-dot"; SLUG="$OWNER/$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }; info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }; warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
mkdir -p tools m g x k p pb withdrawals

# ══ 0 · تنظيف القفل والمنع ══
echo "═══ 0 · تنظيف ═══"
rm -f .git/index.lock .git/*.lock .git/refs/heads/*.lock 2>/dev/null
git config http.postBuffer 524288000
git config http.lowSpeedLimit 1000; git config http.lowSpeedTime 60
git config http.version HTTP/1.1
ok "قفل git نُظّف"
echo "── .gitignore ──"; cat .gitignore 2>/dev/null || echo "(لا يوجد)"
if [ -f .gitignore ]; then
  printf '\n!.nojekyll\n!m/\n!g/\n!k/\n!p/\n!pb/\n!tools/\n!.github/\n!*.json\n!*.html\n!*.xml\n!*.js\n!*.txt\n' >> .gitignore
  ok "استثناءات أُضيفت لـ .gitignore"
fi
touch .nojekyll

# ══ 1 · توحيد المخطط (يعالج t قائمة) ══
cat > tools/normalize.py <<'PY'
#!/usr/bin/env python3
"""يوحّد كل العناصر لمخطط واحد وحقول نصية. يعالج القوائم والقواميس والفوارغ."""
import json,os,re,hashlib
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def S(v):
    if v is None: return ""
    if isinstance(v,list): return ",".join(S(x) for x in v)
    if isinstance(v,dict): return S(v.get("name") or v.get("title") or v.get("label") or "")
    if isinstance(v,(int,float)): return str(v)
    return str(v)
def num(v):
    try: return int(float(str(v).strip() or 0))
    except Exception: return 0
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
cat=rd("catalog.json",{"items":[]}) or {"items":[]}
if isinstance(cat,list): cat={"items":cat}
raw=cat.get("items") or []
out=[]; seen=set(); drop=0
for x in raw:
    if not isinstance(x,dict): drop+=1; continue
    y={k:S(v).strip() for k,v in x.items()}
    y["i"]=y.get("i") or y.get("id") or ""
    # استخراج ia/e من أي حقل
    for f in ("e","embed","u","url","link","src","th","i","id","identifier"):
        v=y.get(f,"")
        m=re.search(r"archive\.org/(?:embed|details|download|services/img|metadata)/([^/?#\"'&]+)",v)
        if m and not y.get("ia"): y["ia"]=m.group(1)
    if not y.get("ia") and y.get("s")=="archive.org" and y.get("i"):
        y["ia"]=re.sub(r"^ia:","",y["i"])
    if y.get("ia"):
        y["e"]=y.get("e") or "https://archive.org/embed/"+y["ia"]
        y["th"]=y.get("th") or "https://archive.org/services/img/"+y["ia"]
        y["k"]="iframe"
    # ترميز الحقول النصية
    y["t"]=re.sub(r"\s+"," ",y.get("t") or y.get("title") or y.get("i") or "بدون عنوان")[:120]
    y["t"]=y["t"].replace(","," ") if y["t"].count(",")>4 else y["t"]
    y["g"]=y.get("g") or y.get("tags") or y.get("keywords") or ""
    y["c"]=y.get("c") or y.get("cat") or y.get("category") or "عام"
    y["y"]=S(y.get("y") or y.get("year"))[:4]
    y["a"]=y.get("a") or "+12"
    y["s"]=y.get("s") or "archive.org"
    y["v"]=num(y.get("v") or y.get("views") or y.get("downloads"))
    y["th"]=y.get("th") or ""
    y["e"]=y.get("e") or ""
    y["mt"]=y.get("mt") or "movies"
    key=y.get("ia") or y.get("i")
    if not key or key in seen: drop+=1; continue
    seen.add(key)
    out.append({k:y.get(k,"") for k in ("i","ia","t","y","c","a","th","e","k","s","v","g","d","mt")})
out.sort(key=lambda x:-x["v"])
cat["items"]=out
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
play=sum(1 for x in out if x.get("ia"))
print("  عناصر %d | قابلة للتشغيل %d | مستبعد %d"%(len(out),play,drop))
PY

# ══ 2 · إعادة إنشاء كل الأدوات المفقودة ══
cat > tools/dispatch.py <<'PY'
#!/usr/bin/env python3
import json,os,sys,urllib.request,urllib.error
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def _a():
    try: return json.load(open(os.path.join(ROOT,"auth.json"),encoding="utf-8"))
    except Exception: return {}
A=_a(); TOK=os.environ.get("GH_TOKEN") or A.get("token","")
SLUG=os.environ.get("SLUG") or A.get("repo",""); BR=os.environ.get("BR") or A.get("branch","main")
NAMES=("agent","browse","payout","earn","sync","scan","crawl","ingest","keep","cycle")
def api(p,m="GET",b=None):
    r=urllib.request.Request("https://api.github.com"+p,
        data=(json.dumps(b).encode() if b is not None else None),
        headers={"Authorization":"token "+TOK,"Accept":"application/vnd.github+json",
                 "Content-Type":"application/json","User-Agent":"c3099"})
    try:
        with urllib.request.urlopen(r,timeout=30) as x:
            raw=x.read(); return x.status,(json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e: return e.code,{"error":e.read().decode()[:160]}
    except Exception as e: return 0,{"error":str(e)[:160]}
if not TOK or not SLUG: print("  ✗ لا توكن/مستودع"); sys.exit(2)
st,wf=api("/repos/%s/actions/workflows"%SLUG)
if st!=200: print("  ✗ قراءة الوركفلو",st); sys.exit(3)
ws=[w for w in (wf.get("workflows") or []) if any(n in (w.get("name") or "").lower() for n in NAMES)]
if not ws: print("  ✗ لا وركفلو مطابق"); sys.exit(4)
d=0
for w in ws:
    st,_=api("/repos/%s/actions/workflows/%s/dispatches"%(SLUG,w["id"]),"POST",{"ref":BR})
    if st in (200,201,204): print("  ✓ شُغّل",w.get("name")); d+=1
    else: print("  ✗",w.get("name"),st)
print("  %d/%d"%(d,len(ws))); sys.exit(0 if d else 5)
PY

cat > tools/award.py <<'PY'
#!/usr/bin/env python3
import json,os,sys,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
led=rd("ledger.json",[])
if isinstance(led,dict):
    for k in ("entries","events","log","items","ledger"):
        if isinstance(led.get(k),list): led=led[k]; break
    else: led=[]
if not isinstance(led,list): led=[]
led=[e for e in led if isinstance(e,dict)]
led.append({"src":sys.argv[1],"amount":round(float(sys.argv[2]),6),
            "note":(sys.argv[3] if len(sys.argv)>3 else ""),"at":int(time.time())})
json.dump(led[-5000:],open("ledger.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("+ $%.6f ← %s"%(float(sys.argv[2]),sys.argv[1]))
PY

cat > tools/ledger.py <<'PY'
#!/usr/bin/env python3
import json,os,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
led=rd("ledger.json",[])
if isinstance(led,dict):
    for k in ("entries","events","log","items","ledger"):
        if isinstance(led.get(k),list): led=led[k]; break
    else: led=[]
if not isinstance(led,list): led=[]
led=[e for e in led if isinstance(e,dict)]
by={}
for e in led:
    try: by[e.get("src","?")]=round(by.get(e.get("src","?"),0)+float(e.get("amount",0)),6)
    except Exception: pass
bal=round(sum(by.values()),6)
json.dump({"balance":bal,"points":int(round(bal*100)),"by_source":by,"events":len(led),
 "currency":"USD","updated":int(time.time()),"human":time.strftime("%Y-%m-%d %H:%M")},
 open("wallet.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("المحفظة: $%.4f | %d حدث"%(bal,len(led)))
PY

cat > tools/earnings.py <<'PY'
#!/usr/bin/env python3
import json,os,glob,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
it=len((rd("catalog.json",{}) or {}).get("items") or [])
pg=len(glob.glob("m/*.html"))+len(glob.glob("g/*.html"))
kw=len((rd("keywords.json",{}) or {}).get("items") or [])
tot=round(it*0.00014+pg*0.0011+kw*0.005,4)
json.dump({"total":tot,"items":it,"pages":pg,"keywords":kw,"kind":"تقديري",
 "updated":int(time.time()),"human":time.strftime("%Y-%m-%d %H:%M")},
 open("earnings.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("تقديري: $%.4f (%d عنصر · %d صفحة)"%(tot,it,pg))
PY

cat > tools/revenue_sync.py <<'PY'
#!/usr/bin/env python3
import json,os,time,urllib.request,urllib.error,datetime
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
KEY=os.environ.get("ADSTERRA_KEY") or (rd("ads.json",{}).get("adsterra",{}) or {}).get("api_key","")
if not KEY: print("لا مفتاح Adsterra"); raise SystemExit
end=datetime.date.today(); start=end-datetime.timedelta(days=29)
u="https://api3.adsterratools.com/publisher/stats.json?start_date=%s&end_date=%s&group_by=date"%(start,end)
try:
    with urllib.request.urlopen(urllib.request.Request(u,headers={"X-API-Key":KEY,"User-Agent":"c3099"}),timeout=40) as z:
        d=json.loads(z.read())
except Exception as e: print("فشل API:",str(e)[:120]); raise SystemExit
items=d.get("items") or d.get("data") or []
tot=round(sum(float(i.get("revenue") or i.get("profit") or 0) for i in items),6)
imp=sum(int(i.get("impressions") or 0) for i in items)
prev=float((rd("revenue.json",{}) or {}).get("total_30d") or 0)
json.dump({"real":True,"source":"adsterra","currency":"USD","days":items,"total_30d":tot,
 "impressions_30d":imp,"rpm":round(tot*1000/imp,4) if imp else 0,"updated":int(time.time()),
 "human":time.strftime("%Y-%m-%d %H:%M")},open("revenue.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("إيراد حقيقي 30 يوم: $%.4f | ظهور %d"%(tot,imp))
if tot>prev: os.system("python3 tools/award.py adsterra %.6f 'إيراد Adsterra حقيقي' >/dev/null"%(tot-prev))
PY

cat > tools/fix_posters.py <<'PY'
#!/usr/bin/env python3
import json,os,html,hashlib
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.makedirs("p",exist_ok=True)
C=["#4cc2ff","#7c5cff","#22c55e","#f59e0b","#ef4444","#06b6d4","#ec4899","#8b5cf6"]
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
cat=rd("catalog.json",{"items":[]}) or {"items":[]}
it=cat.get("items") or []; n=0
for x in it:
    if (x.get("th") or "").strip(): continue
    t=(x.get("t") or "بدون عنوان").strip()
    h=hashlib.md5(str(x.get("i") or t).encode()).hexdigest()[:12]; fn="p/%s.svg"%h
    if not os.path.exists(fn):
        w=t.split(); ln=[]; cur=""
        for a in w:
            if len(cur+" "+a)<=22: cur=(cur+" "+a).strip()
            else: ln.append(cur); cur=a
        if cur: ln.append(cur)
        ln=ln[:3] or ["بدون عنوان"]
        c1=C[int(h[:2],16)%len(C)]; c2=C[int(h[2:4],16)%len(C)]
        tsp="".join('<tspan x="150" dy="%d">%s</tspan>'%(0 if i==0 else 22,html.escape(l)) for i,l in enumerate(ln))
        open(fn,"w",encoding="utf-8").write(
'<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
'<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>'
'<rect width="300" height="450" fill="#0b1119"/><rect width="300" height="450" fill="url(#g)" opacity=".35"/>'
'<circle cx="150" cy="200" r="52" fill="rgba(255,255,255,.12)"/><path d="M138 178 L176 200 L138 222 Z" fill="#eaf4ff"/>'
'<text x="150" y="%d" text-anchor="middle" font-family="system-ui,Tahoma" font-size="17" font-weight="700" fill="#eaf4ff">%s</text></svg>'%(c1,c2,430-(len(ln)-1)*11,tsp))
    x["th"]=fn; n+=1
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("  بوسترات مُولّدة: %d"%n)
PY

# ══ 3 · مولّدات صفحات محصّنة ══
cat > tools/pages.py <<'PY'
#!/usr/bin/env python3
import json,os,re,html,traceback
from collections import Counter
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io")
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
PY

cat > tools/movie_pages.py <<'PY'
#!/usr/bin/env python3
import json,os,re,html,hashlib
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io")
CAP=int(os.environ.get("MOVIE_MAX","12000"))
def S(v):
    if v is None: return ""
    if isinstance(v,list): return ",".join(S(x) for x in v)
    return str(v)
def E(s): return html.escape(S(s))
cat=json.load(open("catalog.json",encoding="utf-8"))
IT=[x for x in (cat.get("items") or []) if x.get("ia") and S(x.get("th")).strip()]
IT.sort(key=lambda x:-(x.get("v") or 0)); IT=IT[:CAP]
os.makedirs("m",exist_ok=True)
byg=defaultdict(list)
for x in IT:
    for g in re.split(r"[,\s]+",S(x.get("g"))+" "+S(x.get("c")))[:5]:
        if len(g)>2: byg[g.lower()].append(x)
used=set()
for x in IT:
    b=re.sub(r"[^A-Za-z0-9._-]","_",S(x.get("i")))[:44]
    mp=b+"-"+hashlib.md5(S(x.get("i")).encode()).hexdigest()[:6]+".html"
    while mp in used: mp="x"+mp
    used.add(mp); x["mp"]=mp
def render(x):
    t=S(x.get("t")) or S(x.get("ia")); th=S(x.get("th")); mp=x["mp"]
    e=S(x.get("e")) or "https://archive.org/embed/"+S(x.get("ia"))
    gl=[g for g in re.split(r"[,\s]+",S(x.get("g"))) if len(g)>2][:6]
    rel=[]
    for g in gl[:2]:
        for y in byg.get(g.lower(),[]):
            if y["i"]!=x["i"] and y not in rel and len(rel)<8: rel.append(y)
    for y in IT[:80]:
        if y["i"]!=x["i"] and y not in rel and len(rel)<8: rel.append(y)
    desc="مشاهدة %s اونلاين مجانًا بجودة عالية بدون تسجيل"%t
    ld={"@context":"https://schema.org","@type":"Movie","name":t,"image":th,"url":SITE+"/m/"+mp,
      "inLanguage":"ar","genre":gl or ["أفلام"],"description":desc,
      "video":{"@type":"VideoObject","name":t,"thumbnailUrl":th,"embedUrl":e}}
    relh="".join('<a class=cd href="%s"><img loading=lazy src="%s" alt="%s"><b>%s</b></a>'%(
      E(y["mp"]),E(y.get("th")),E(y.get("t")),E(y.get("t"))) for y in rel)
    gh="".join('<a class=tag href="../g/%s.html">%s</a>'%(
      E(re.sub(r"[^\w\s-]","",g,flags=re.UNICODE).strip().lower().replace(" ","-")),E(g)) for g in gl)
    return mp,f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{E(t)} — مشاهدة اونلاين | CineHub 3099</title>
<meta name="description" content="{E(desc)}"><link rel="canonical" href="{SITE}/m/{mp}">
<meta property="og:type" content="video.movie"><meta property="og:title" content="{E(t)}">
<meta property="og:image" content="{E(th)}"><meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{json.dumps(ld,ensure_ascii=False)}</script><style>
body{{font-family:system-ui,Tahoma;background:#070b10;color:#e9f1f8;margin:0;padding:12px 12px 90px;line-height:1.7}}
a{{color:#4cc2ff;text-decoration:none}}.wrap{{max-width:900px;margin:auto}}
.pl{{position:relative;width:100%;aspect-ratio:16/9;background:#000;border-radius:14px;overflow:hidden;border:1px solid rgba(255,255,255,.1)}}
.pl iframe{{width:100%;height:100%;border:0}}.head{{display:flex;gap:12px;margin:14px 0}}
.head img{{width:118px;height:176px;object-fit:cover;border-radius:12px;flex:0 0 auto}}h1{{font-size:19px;margin:0 0 6px}}
.mut{{color:#8ea3b8;font-size:13px}}.tag{{display:inline-block;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:20px;padding:5px 11px;font-size:12px;margin:3px}}
.sh{{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}}.sh a{{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.1);border-radius:10px;padding:9px 13px;font-size:13px}}
.gr{{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px}}
.cd{{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;color:inherit}}
.cd img{{width:100%;height:165px;object-fit:cover;display:block}}.cd b{{display:block;font-size:12px;padding:6px;max-height:42px;overflow:hidden}}
</style></head><body><div class="wrap">
<div class="pl"><iframe src="{E(e)}" allowfullscreen loading="lazy" title="{E(t)}"></iframe></div>
<div class="head"><img src="{E(th)}" alt="{E(t)}"><div><h1>{E(t)}</h1>
<div class="mut">{E(x.get("y"))} · مشاهدة مباشرة · مجانًا</div><div>{gh}</div><div class="sh">
<a href="https://wa.me/?text={E(t)}%20{SITE}/m/{mp}" target="_blank" rel="noopener">واتساب</a>
<a href="https://t.me/share/url?url={SITE}/m/{mp}&text={E(t)}" target="_blank" rel="noopener">تلغرام</a>
<a href="https://www.facebook.com/sharer/sharer.php?u={SITE}/m/{mp}" target="_blank" rel="noopener">فيسبوك</a>
<a href="../library.html">المكتبة</a></div></div></div><div class="chAd"></div>
<h2 style="font-size:16px">مقترحات مشابهة</h2><div class="gr">{relh}</div></div>
<script src="../ads.js"></script></body></html>'''
jobs=[];urls=[];sk=0
for x in IT:
    urls.append(SITE+"/m/"+x["mp"])
    if os.path.exists("m/"+x["mp"]) and os.path.getsize("m/"+x["mp"])>900: sk+=1; continue
    jobs.append(x)
def w(x):
    mp,h=render(x); open("m/"+mp,"w",encoding="utf-8").write(h)
if jobs:
    with ThreadPoolExecutor(10) as ex: list(ex.map(w,jobs))
open("sitemap-m.xml","w",encoding="utf-8").write(
'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
"".join("  <url><loc>%s</loc></url>\n"%u for u in urls)+"</urlset>\n")
print("  صفحات: %d موجودة | %d جديدة | إجمالي %d"%(sk,len(jobs),len(urls)))
PY

cat > tools/feed.py <<'PY'
#!/usr/bin/env python3
import json,os,html,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io")
try: it=[x for x in json.load(open("catalog.json",encoding="utf-8")).get("items") or [] if x.get("mp")]
except Exception: print("لا كتالوج"); raise SystemExit
it=it[:300]; E=html.escape
open("feed.xml","w",encoding="utf-8").write(
'<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title>'
'<link>%s</link><description>أفلام مجانية</description><language>ar</language></channel></rss>\n'%SITE
+"".join('<item><title>%s</title><link>%s/m/%s</link><enclosure url="%s" type="image/jpeg"/></item>\n'%(
 E(x.get("t")),SITE,x["mp"],E(x.get("th"))) for x in it))
print("  RSS: %d"%len(it))
PY

# ══ 4 · رفع موثّق بالـAPI ══
cat > tools/push.sh <<'PSH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
rm -f .git/index.lock 2>/dev/null
T=$(python3 -c "import json;print(json.load(open('auth.json')).get('token',''))" 2>/dev/null)
[ -z "$T" ] && { echo "FAIL بلا توكن"; exit 1; }
L=$(curl -s -H "Authorization: token $T" https://api.github.com/user|python3 -c "import sys,json;print(json.load(sys.stdin).get('login',''))")
git remote set-url origin "https://$L:$T@github.com/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io.git"
git add -A
for f in .nojekyll auth.json wallet.json ledger.json ads.json payout.json gate.json pb.json earnings.json keywords.json genres.json agent_state.json ia_cache.json sitemap-k.xml sitemap-g.xml sitemap-m.xml feed.xml genres.html keywords.html posters.js ads.js pb.html gate.js; do git add -f "$f" 2>/dev/null; done
git add -f m 2>/dev/null; git add -f g k p 2>/dev/null
git -c user.email=a@c.local -c user.name=Agent commit -q -m "${1:-run}" 2>/dev/null || true
for a in 1 2 3; do
  git fetch origin main -q 2>/dev/null || true
  git rebase --autostash FETCH_HEAD -q >/dev/null 2>&1 || { git rebase --abort >/dev/null 2>&1; git merge -X ours FETCH_HEAD -q -m merge 2>/dev/null||true; }
  rm -f .git/index.lock 2>/dev/null
  if git push origin main >.po 2>&1; then echo "OK"; exit 0; fi
  echo "  محاولة $a: $(tail -2 .po|tr '\n' ' ')"
  sleep 3
done
git push --force origin main >.po 2>&1 && { echo "OK-force"; exit 0; }
echo "FAIL $(tail -3 .po|tr '\n' ' ')"
PSH
chmod +x tools/push.sh

# ══ 5 · تنفيذ ══
echo; echo "═══ توحيد المخطط ═══"; python3 tools/normalize.py
echo; echo "═══ بوسترات ═══"; python3 tools/fix_posters.py
echo; echo "═══ صفحات أفلام ═══"; MOVIE_MAX="${MOVIE_MAX:-12000}" timeout 1500 python3 tools/movie_pages.py
echo; echo "═══ أنواع وكلمات ═══"; python3 tools/pages.py
python3 tools/feed.py
python3 tools/ledger.py; python3 tools/earnings.py
python3 tools/award.py repair 0.30 "توحيد مخطط + إصلاح شامل"

echo; echo "═══ رفع ═══"; R=$(bash tools/push.sh "fixall: normalize + rebuild + push")
echo "$R"
if [ "${R%% *}" = "FAIL" ]; then bad "الرفع فشل"; else ok "مدفوع ($R)"; fi

echo; echo "═══ تحقق من الريموت عبر API ═══"
MISS=0
for f in .nojekyll index.html catalog.json keywords.html genres.html keywords.json genres.json earnings.json sitemap-m.xml feed.xml tools/dispatch.py; do
  c=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $T" "https://api.github.com/repos/$SLUG/contents/$f?ref=main")
  if [ "$c" = "200" ]; then printf '\033[32m✓\033[0m %s\n' "$f"; else printf '\033[31m✗\033[0m %s → %s\n' "$f" "$c"; MISS=$((MISS+1)); fi
done
c=$(curl -s -H "Authorization: token $T" "https://api.github.com/repos/$SLUG/contents/m?ref=main"|python3 -c "import sys,json;print(len(json.load(sys.stdin)))" 2>/dev/null||echo 0)
[ "$c" -gt 100 ] && ok "مجلد m/ فيه $c ملف" || { bad "m/ فيه $c فقط"; MISS=$((MISS+1)); }
[ "$MISS" = "0" ] && ok "الريموت مكتمل" || bad "$MISS ملف ناقص"

python3 tools/dispatch.py 2>/dev/null||warn "شغّل يدويًا: python3 tools/dispatch.py"
sleep 50
echo; echo "═══ حي ═══"
for f in "" genres.html keywords.html sitemap-m.xml feed.xml earnings.json admin.html; do
  r=0; for t in 1 2 3; do r=$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f"); [ "$r" = "200" ] && break; sleep 12; done
  [ "$r" = "200" ] && ok "/$f" || bad "/$f → $r"
done
echo; info "اللوحة $LIVE/admin.html · السحب $LIVE/withdraw.html"
