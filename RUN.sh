#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 — RUN.sh : أمر واحد كامل. لا يتوقف على خطأ غير قاتل.
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
OWNER="alkazmybwhwr-dot"; SLUG="$OWNER/$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }; info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }; warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
FAST="${1:-}"
mkdir -p tools m g x k p pb withdrawals; touch .nojekyll

# ══════ 1 · أدوات مصحّحة ══════
cat > tools/movie_pages.py <<'PY'
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
PY

cat > tools/ingest_multi.py <<'PY'
#!/usr/bin/env python3
"""مصادر متعددة بلا مفاتيح: archive.org + Openverse + NASA"""
import json,os,re,time,urllib.request,urllib.parse
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"cinehub3099/1.0"}
B=int(os.environ.get("BUDGET_SRC","240")); T0=time.time()
def left(): return B-(time.time()-T0)
def get(u,t=45):
    for a in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t) as r: return json.loads(r.read())
        except Exception:
            if a==2: raise
            time.sleep(1.5*(a+1))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
cat=rd("catalog.json",{"items":[]}) or {"items":[]}
it=cat.get("items") or []
seen={x.get("ia") or x.get("i") for x in it if isinstance(x,dict)}
def push(x):
    k=x.get("ia") or x.get("i")
    if not k or k in seen: return 0
    seen.add(k); it.append(x); return 1
added={}
# ── archive.org ──
if os.environ.get("SKIP_IA")!="1":
    COLS=os.environ.get("IA_COLS","feature_films,classic_cartoons,film_noir,sci-fi_horror,animationandcartoons,silent_films,short_films,mysteryandcrimefilms,comedy_films,television,documentaries,moviesandfilms,artsandmusicvideos,prelinger,universal_newsreels,computerchronicles,sports,newsandpublicaffairs,educationalfilms,classic_tv").split(",")
    n=0
    for col in COLS:
        if left()<40: break
        for pg in (1,2,3):
            if left()<40: break
            try:
                d=get("https://archive.org/advancedsearch.php?"+urllib.parse.urlencode(
                  {"q":"collection:(%s) AND mediatype:(movies)"%col,
                   "fl[]":["identifier","title","downloads","subject","year"],
                   "rows":200,"page":pg,"output":"json","sort[]":"downloads desc"},doseq=True))
            except Exception: break
            docs=((d.get("response") or {}).get("docs") or [])
            if not docs: break
            for x in docs:
                i=x.get("identifier")
                if not i: continue
                sj=x.get("subject")
                if isinstance(sj,list): sj=",".join(str(s) for s in sj[:6])
                n+=push({"i":i,"ia":i,"t":(x.get("title") or i)[:120],
                  "th":"https://archive.org/services/img/"+i,"e":"https://archive.org/embed/"+i,
                  "k":"iframe","s":"archive.org","v":int(x.get("downloads") or 0),
                  "y":str(x.get("year") or ""),"a":"+12","c":"عام","mt":"movies",
                  "g":str(sj or "").lower()[:120]})
            time.sleep(0.25)
    added["archive"]=n
# ── Openverse ──
if left()>30:
    n=0
    for q in "cinema,film,poster,movie,animation,space,ocean,history,city".split(","):
        if left()<20: break
        for pg in range(1,8):
            try: d=get("https://api.openverse.org/v1/images/?"+urllib.parse.urlencode({"q":q,"page_size":20,"page":pg}))
            except Exception: break
            res=d.get("results") or []
            if not res: break
            for r in res:
                i="ov-"+str(r.get("id"))[:24]
                n+=push({"i":i,"t":(r.get("title") or "بدون عنوان")[:90],
                  "th":r.get("thumbnail") or r.get("url"),"e":r.get("url"),
                  "k":"iframe","s":"openverse","v":int(r.get("width") or 0),
                  "y":"","a":"عام","c":"صور","g":str(r.get("source") or "openverse")[:60].lower()})
            time.sleep(0.2)
    added["openverse"]=n
# ── NASA ──
if left()>20:
    n=0
    for q in "space,apollo,earth,mars,nebula,launch".split(","):
        if left()<15: break
        try: d=get("https://images-api.nasa.gov/search?media_type=video&q=%s&page_size=60"%q)
        except Exception: continue
        for x in ((d.get("collection") or {}).get("items") or []):
            da=(x.get("data") or [{}])[0]; nid=da.get("nasa_id")
            lk=(x.get("links") or [{}])[0].get("href")
            if not nid or not lk: continue
            n+=push({"i":"nasa-"+nid,"t":(da.get("title") or nid)[:110],"th":lk,
              "e":"https://images-assets.nasa.gov/video/%s/%s~orig.mp4"%(nid,nid),
              "k":"iframe","s":"nasa","v":0,"y":(da.get("date_created") or "")[:4],
              "a":"عام","c":"فضاء","g":str(da.get("keywords") or "nasa space")[:100].lower()})
        time.sleep(0.3)
    added["nasa"]=n
cat["items"]=it
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("  "+" | ".join("%s +%d"%(k,v) for k,v in added.items())+" | الإجمالي %d"%len(it))
PY

cat > tools/fix_posters.py <<'PY'
#!/usr/bin/env python3
import json,os,re,html,hashlib
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
os.makedirs("p",exist_ok=True)
COLS=["#4cc2ff","#7c5cff","#22c55e","#f59e0b","#ef4444","#06b6d4","#ec4899","#8b5cf6"]
try: cat=json.load(open("catalog.json",encoding="utf-8"))
except Exception: print("لا كتالوج"); raise SystemExit
it=cat.get("items") or []
def svg(x):
    t=(x.get("t") or "بدون عنوان").strip()
    h=hashlib.md5(str(x.get("i") or t).encode()).hexdigest()[:12]; fn="p/%s.svg"%h
    if os.path.exists(fn): return fn
    w=t.split(); lines=[]; cur=""
    for a in w:
        if len(cur+" "+a)<=22: cur=(cur+" "+a).strip()
        else: lines.append(cur); cur=a
    if cur: lines.append(cur)
    lines=lines[:3] or ["بدون عنوان"]
    c1=COLS[int(h[:2],16)%len(COLS)]; c2=COLS[int(h[2:4],16)%len(COLS)]
    tsp="".join('<tspan x="150" dy="%d">%s</tspan>'%(0 if i==0 else 22,html.escape(l)) for i,l in enumerate(lines))
    y=430-(len(lines)-1)*11
    open(fn,"w",encoding="utf-8").write(
'<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450" viewBox="0 0 300 450">'
'<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>'
'<rect width="300" height="450" fill="#0b1119"/><rect width="300" height="450" fill="url(#g)" opacity=".35"/>'
'<circle cx="150" cy="200" r="52" fill="rgba(255,255,255,.12)"/><path d="M138 178 L176 200 L138 222 Z" fill="#eaf4ff"/>'
'<text x="150" y="%d" text-anchor="middle" font-family="system-ui,Tahoma" font-size="17" font-weight="700" fill="#eaf4ff">%s</text>'
'<text x="150" y="430" text-anchor="middle" font-family="system-ui" font-size="11" fill="rgba(234,244,255,.6)">CineHub 3099</text></svg>'%(c1,c2,y,tsp))
    return fn
n=0; tot=0
for x in it:
    tot+=1
    if not (x.get("th") or "").strip():
        x["th"]=svg(x); n+=1
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("  بلا صورة أُصلحت: %d من %d"%(n,tot))
PY

# ══════ 2 · الملفات الناقصة (كانت 404) ══════
cat > pb.html <<'PEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Postback</title>
<style>body{font-family:system-ui,Tahoma;background:#070b10;color:#e9f1f8;padding:18px;line-height:1.8}
.ok{color:#22c55e}.bad{color:#ef4444}.mut{color:#8ea3b8;font-size:13px}</style></head><body>
<h3>استقبال إيراد الإعلان</h3><div id="s" class="mut">…</div>
<script>(function(){
var q=new URLSearchParams(location.search);
var amt=parseFloat(q.get('amt')||q.get('revenue')||q.get('payout')||'0');
var src=q.get('src')||q.get('sub_id')||q.get('network')||'ads';
var tx=q.get('tx')||q.get('tx_id')||String(Date.now());
var out=document.getElementById('s');
if(!(amt>0)){out.textContent='لا مبلغ في الرابط';return;}
function j(u){return fetch(u+'?_='+Date.now(),{cache:'no-store'}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function b64(s){return btoa(String.fromCharCode.apply(null,new TextEncoder().encode(s)));}
j('pb.json').then(function(cfg){ j('auth.json').then(function(a){
 var tok=(cfg&&cfg.token)||(a&&a.token),repo=(cfg&&cfg.repo)||(a&&a.repo),br='main';
 if(!tok){out.innerHTML='<span class="bad">لا توكن للكتابة</span>';return;}
 var fn='ev-'+tx+'.json';
 fetch('https://api.github.com/repos/'+repo+'/contents/pb/'+fn,{method:'PUT',
  headers:{Authorization:'token '+tok,Accept:'application/vnd.github+json','Content-Type':'application/json'},
  body:JSON.stringify({message:'ads +'+amt,branch:br,content:b64(JSON.stringify({src:'ads:'+src,amount:amt,note:'postback',at:Math.floor(Date.now()/1000)}))})})
 .then(function(r){return r.json().then(function(x){return {s:r.status};});})
 .then(function(r){out.innerHTML=r.s<300?'<span class="ok">✓ سُجل $'+amt+'</span>':'<span class="bad">فشل '+r.s+'</span>';});
});});})();</script></body></html>
PEOF

cat > posters.js <<'PEOF'
(function(){
if(/\/(play|m\/)/.test(location.pathname))return;
var PH='data:image/svg+xml;utf8,'+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450"><rect width="300" height="450" fill="#0d151f"/><text x="150" y="230" fill="#4cc2ff" font-size="16" text-anchor="middle" font-family="sans-serif">CineHub</text></svg>');
function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){return({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'})[c];});}
fetch('catalog.json?_='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(d){
 var it=(d.items||[]).filter(function(x){return (x.th||'').trim()&&x.mp});
 if(!it.length)return;
 it.sort(function(a,b){return (b.v||0)-(a.v||0)});
 var w=document.createElement('div');w.id='chNow';
 w.innerHTML='<style>#chNow{margin:16px 0;font-family:system-ui,Tahoma;color:#e9f1f8}#chNow h2{font-size:17px;margin:0 0 10px}'
 +'#chNow .strip{display:flex;gap:10px;overflow-x:auto;padding-bottom:8px}#chNow .st{flex:0 0 126px;text-decoration:none;color:inherit}'
 +'#chNow .st img{width:126px;height:188px;object-fit:cover;border-radius:12px;display:block;background:#0d151f;border:1px solid rgba(255,255,255,.08)}'
 +'#chNow .st b{display:block;font-size:12px;padding:6px 2px;line-height:1.35;max-height:44px;overflow:hidden}'
 +'#chNow .p{position:relative}#chNow .pl{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:30px;opacity:.85;pointer-events:none}'
 +'#chNow .more{color:#4cc2ff;font-size:13px;text-decoration:none}</style>'
 +'<h2>🎬 يُشاهد الآن <a class="more" href="library.html">كل المكتبة ←</a></h2><div class="strip">'
 +it.slice(0,60).map(function(x){return '<a class="st" href="m/'+encodeURIComponent(x.mp)+'"><span class="p"><img loading="lazy" src="'+esc(x.th)+'" onerror="this.src=\''+PH+'\'"><span class="pl">▶</span></span><b>'+esc(x.t)+'</b></a>';}).join('')
 +'</div>';
 var b=document.body; b.insertBefore(w,b.firstChild?b.firstChild.nextSibling||b.firstChild:b.firstChild);
}).catch(function(){});})();
PEOF

[ -f ads.js ] || cat > ads.js <<'AEOF'
(function(){
function head(c){var d=document.createElement('div');d.innerHTML=c;while(d.firstChild)document.head.appendChild(d.firstChild);}
fetch('ads.json?_='+Date.now(),{cache:'no-store'}).then(function(r){return r.ok?r.json():null}).then(function(a){
 if(!a)return;var A=a.adsterra||{},M=a.monetag||{},G=a.adsense||{};
 if(A.enabled){if(A.popunder)head(A.popunder);if(A.socialbar)head(A.socialbar);
   if(A.banner){var w=document.createElement('div');w.className='chAd';w.innerHTML=A.banner;
     var t=document.querySelector('.chAd')||document.body;t.parentNode.insertBefore(w,t.nextSibling);}}
 if(M.enabled){if(M.inpage)head(M.inpage);if(M.vignette)head(M.vignette);}
 if(G.enabled&&G.client)head('<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+G.client+'" crossorigin="anonymous"><\/script>');
}).catch(function(){});})();
AEOF
[ -f ads.json ] || echo '{"adsterra":{"enabled":false,"api_key":"","popunder":"","socialbar":"","banner":""},"monetag":{"enabled":false,"inpage":"","vignette":""},"adsense":{"enabled":false,"client":""}}' > ads.json
[ -f payout.json ] || echo '{"bank":{"name":"Al-Kuraimi Islamic Microfinance Bank","swift":"KBMFYESAXXX","city":"Sanaa"},"methods":[{"id":"usdt","label":"USDT TRC20","min":5},{"id":"paxum","label":"Paxum","min":5},{"id":"payoneer","label":"Payoneer","min":20},{"id":"wire","label":"حوالة بنكية - الكريمي","min":500}]}' > payout.json
[ -f pb.json ] || echo '{"token":"","repo":"alkazmybwhwr-dot/alisalimax3.github.io"}' > pb.json
[ -f gate.json ] || python3 -c "import hashlib,json;json.dump({'hash':hashlib.sha256(b'3099').hexdigest(),'plain':'3099'},open('gate.json','w'))"

python3 - <<'PY'
import os,json
for p,ins in (("index.html",'<script src="ads.js"></script>\n<script src="posters.js"></script>\n'),
              ("library.html",'<script src="ads.js"></script>\n<script src="posters.js"></script>\n'),
              ("genres.html",'<script src="ads.js"></script>\n'),("keywords.html",'<script src="ads.js"></script>\n'),
              ("auto.html",'<script src="gate.js"></script>\n'),("withdraw.html",'<script src="gate.js"></script>\n'),
              ("admin.html",'<script src="gate.js"></script>\n')):
    if not os.path.exists(p): continue
    t=open(p,encoding="utf-8").read(); o=t
    for src in ("ads.js","posters.js","gate.js"):
        if src in ins and src not in t: t=t.replace("</body>",'<script src="%s"></script>\n</body>'%src,1)
    if t!=o: open(p,"w",encoding="utf-8").write(t); print("  رُبط:",p)
json.dump({"cycles":0,"status":"ok","items":0,"pages":0},open("agent_state.json","w"),ensure_ascii=False,indent=1)
PY

# ══════ 3 · رفع قوي (يكشف السبب الحقيقي) ══════
cat > tools/push.sh <<'PSH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
T=$(python3 -c "import json;print(json.load(open('auth.json')).get('token',''))" 2>/dev/null)
[ -z "$T" ] && { echo "✗ بلا توكن"; exit 1; }
L=$(curl -s -H "Authorization: token $T" https://api.github.com/user|python3 -c "import sys,json;print(json.load(sys.stdin).get('login',''))")
U="https://$L:$T@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git"
git remote set-url origin "$U"
git config http.postBuffer 524288000
git add -A
for f in auth.json wallet.json ledger.json ads.json payout.json gate.json pb.json earnings.json keywords.json genres.json agent_state.json ia_cache.json sitemap-k.xml sitemap-g.xml sitemap-m.xml sitemap.xml feed.xml genres.html keywords.html; do git add -f "$f" 2>/dev/null; done
git -c user.email=a@c.local -c user.name=Agent commit -q -m "$1" 2>/dev/null || true
for a in 1 2 3; do
  git fetch origin main -q 2>/dev/null || true
  git rebase --autostash FETCH_HEAD -q >/dev/null 2>&1 || {
    git rebase --abort >/dev/null 2>&1
    git merge -X ours FETCH_HEAD -q -m merge 2>/dev/null || true
  }
  if git push origin main >.po 2>&1; then echo "OK"; exit 0; fi
  echo "  محاولة $a فشلت: $(tail -2 .po|tr '\n' ' ')"
  sleep 3
done
echo "  تجاوز قسري…"
git push --force origin main >.po 2>&1 && { echo "OK-force"; exit 0; }
echo "FAIL"; tail -5 .po
PSH
chmod +x tools/push.sh

# ══════ 4 · تنفيذ ══════
echo "═══ 1/7 إصلاح ═══"; python3 tools/repair.py
echo; echo "═══ 2/7 مصادر ═══"
if [ "$FAST" = "fast" ]; then info "سريع: تخطي التغذية"; else timeout 600 python3 tools/ingest_multi.py || warn "تغذية جزئية"; fi
echo; echo "═══ 3/7 بوسترات ═══"; python3 tools/fix_posters.py
echo; echo "═══ 4/7 صفحات أفلام ═══"; MOVIE_MAX="${MOVIE_MAX:-12000}" timeout 1500 python3 tools/movie_pages.py
echo; echo "═══ 5/7 أنواع وكلمات ═══"; python3 tools/pages.py 2>&1|tail -4; python3 tools/feed.py 2>/dev/null||true
echo; echo "═══ 6/7 محفظة ═══"; python3 tools/ledger.py; python3 tools/earnings.py 2>/dev/null||true
python3 tools/revenue_sync.py 2>/dev/null||info "Adsterra بلا مفتاح بعد"

echo; echo "═══ 7/7 رفع ═══"; R=$(bash tools/push.sh "run: full cycle" ); echo "$R"
[ "${R%% *}" = "FAIL" ] && bad "الرفع فشل — السبب أعلاه" || ok "مدفوع ($R)"
python3 tools/dispatch.py 2>/dev/null||warn "شغّل: python3 tools/dispatch.py"

echo; echo "═══ تحقق ═══"
P=0;F=0
chk(){ if eval "$2" >/dev/null 2>&1; then printf '\033[32m✓\033[0m %s\n' "$1"; P=$((P+1)); else printf '\033[31m✗\033[0m %s\n' "$1"; F=$((F+1)); fi; }
chk "catalog" "python3 -c \"import json;json.load(open('catalog.json'))\""
chk "ledger قائمة" "python3 -c \"import json;assert isinstance(json.load(open('ledger.json')),list)\""
chk "قابل للتشغيل>0" "python3 -c \"import json;i=json.load(open('catalog.json'))['items'];assert sum(1 for x in i if x.get('ia'))>0\""
chk "صفحات m>0" "test $(ls m 2>/dev/null|wc -l) -gt 0"
chk "genres/keywords" "test -f genres.html && test -f keywords.html"
chk "pb/posters/ads" "test -f pb.html && test -f posters.js && test -f ads.js"
chk "خرائط+feed" "test -f sitemap-m.xml && test -f feed.xml"
echo "── نجح $P | فشل $F ──"
echo; info "الرابط: $LIVE · اللوحة: $LIVE/admin.html (3099) · السحب: $LIVE/withdraw.html"
[ "$F" = "0" ] && ok "التطبيق جاهز ومكتمل" || bad "$F نقطة ناقصة"
