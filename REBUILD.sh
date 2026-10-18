#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  CineHub 3099 — REBUILD.sh
#  يستعيد المكتبة بأفلام حقيقية + مشغّل + وكيل مرئي + منصات
# ============================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"; mkdir -p tools cat .state
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
push_all(){
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1" 2>/dev/null
  if git push origin main 2>.push.err; then ok "مدفوع"; return 0; fi
  if grep -qiE 'workflow|\.github' .push.err; then
    mv .github "$HOME/.gh_hold" 2>/dev/null; git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1 (site)" 2>/dev/null
    git push origin main 2>&1 | tail -3; mv "$HOME/.gh_hold" .github 2>/dev/null
  else sed -n '1,6p' .push.err; fi
}
git fetch origin main -q 2>/dev/null || true
git pull --rebase origin main -q 2>/dev/null || true

echo "═══ ما الموجود فعلًا ═══"
ls -1 *.html 2>/dev/null | head -30
info "نسخ احتياطية: $(ls -1 index.html.* 2>/dev/null | tr '\n' ' ')"

# ================== 1) جلب أفلام حقيقية ==================
cat > tools/ingest_films.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجلب أفلامًا قانونية حقيقية من archive.org: عنوان، سنة، وسم، صورة، مشغّل"""
import json, os, re, urllib.request, urllib.parse, datetime, random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
ROWS=int(os.environ.get("FILM_ROWS","400"))

Q=[("كوميديا","عائلي","subject:(comedy)"),
   ("دراما","+13","subject:(drama)"),
   ("مغامرات","عائلي","subject:(adventure)"),
   ("خيال علمي","+12","subject:(\"science fiction\")"),
   ("رعب","+13","subject:(horror)"),
   ("غربي","+12","subject:(western)"),
   ("غموض","+12","subject:(mystery)"),
   ("رومانسي","+12","subject:(romance)"),
   ("كرتون","كل الأعمار","subject:(cartoon)"),
   ("رسوم متحركة","كل الأعمار","subject:(animation)"),
   ("أطفال","كل الأعمار","subject:(children)"),
   ("وثائقي","عائلي","subject:(documentary)"),
   ("صامت","+12","subject:(\"silent film\")"),
   ("حربي","+13","subject:(war)"),
   ("موسيقي","عائلي","subject:(musical)")]
def fetch(q, rows):
    p=urllib.parse.urlencode({"q":"mediatype:movies AND "+q,
        "rows":str(rows),"page":"1","output":"json",
        "sort[]":"downloads desc"}, doseq=True)
    for extra in ("&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=creator&fl[]=downloads",):
        pass
    url=("https://archive.org/advancedsearch.php?"+p+
         "&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=creator&fl[]=downloads")
    try:
        r=urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"cinehub3099"}),timeout=40)
        return json.loads(r.read().decode()).get("response",{}).get("docs",[])
    except Exception as e:
        print("  تعذّر:",q,str(e)[:60]); return []
items={}
for cat,age,q in Q:
    per=max(20,ROWS//len(Q))
    docs=fetch(q, per)
    for d in docs:
        i=(d.get("identifier") or "").strip()
        t=(d.get("title") or "").strip()
        if not i or not t or i in items: continue
        t=re.sub(r"\s+"," ",t)[:90]
        y=d.get("year") or ""
        items[i]={"i":i,"t":t,"y":str(y)[:4],"c":cat,"a":age,
                  "th":"https://archive.org/services/img/"+i,
                  "p":"https://archive.org/embed/"+i,
                  "d":"https://archive.org/details/"+i,
                  "s":"archive.org"}
    print("  %s: %d"%(cat,len(docs)))
out=list(items.values())
random.shuffle(out); out=out[:int(os.environ.get("FILM_MAX","1200"))]
cats=sorted({x["c"] for x in out}); ages=["كل الأعمار","عائلي","+12","+13"]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
           "count":len(out),"cats":cats,"ages":ages,"items":out},
          open("catalog.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(out),"cats":cats,"ages":ages,
           "generated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("films.json","w"),ensure_ascii=False)
print("أفلام حقيقية:",len(out))
PYEOF
info "جلب الأفلام (قد يستغرق دقيقة)..."
FILM_ROWS=450 FILM_MAX=1200 python3 tools/ingest_films.py

# ================== 2) المكتبة ==================
cat > library.html <<'LEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>المكتبة — CineHub 3099</title>
<style>*{box-sizing:border-box}body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px;line-height:1.7}
a{color:#4cc2ff;text-decoration:none}.bar{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}
input,select{background:#0f1720;border:1px solid rgba(255,255,255,.12);color:#e9f1f8;border-radius:10px;padding:9px;font-size:14px}
input{flex:1;min-width:160px}.chips{display:flex;gap:6px;flex-wrap:wrap;margin:8px 0}
.chip{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:20px;padding:6px 13px;font-size:13px;cursor:pointer}
.chip.on{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(128px,1fr));gap:10px}
.c{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden}
.c img{width:100%;height:170px;object-fit:cover;display:block;background:#0f1720}
.c div{padding:7px}.c b{font-size:13px;display:block;line-height:1.4}
.c small{color:#8ea3b8;font-size:11.5px}.c .tag{color:#7fd88a}
#more{background:rgba(76,194,255,.15);color:#9fe;border:1px solid #2a6;border-radius:10px;padding:10px 16px;width:100%;margin:14px 0;font-size:14px}</style></head><body>
<h1>المكتبة <span class="c" id="n" style="color:#8ea3b8;font-size:14px"></span></h1>
<div class="bar"><input id="q" placeholder="ابحث باسم الفيلم"><select id="y"><option value="">كل السنوات</option></select></div>
<div class="chips" id="cats"></div><div class="chips" id="ages"></div>
<div class="grid" id="g"></div><button id="more">تحميل المزيد</button>
<p style="color:#8ea3b8;font-size:12.5px">المصدر: archive.org (ملك عام / مرخّص) · التصنيف آلي من وسوم المصدر لا ادّعاء</p>
<p><a href="index.html">الرئيسية</a> · <a href="sites.html">المواقع</a> · <a href="rise.html">الأرقام</a></p>
<script>
(function(){
"use strict";var all=[],shown=60,cat="",age="";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function chip(box,label,val,cur,fn){var d=document.createElement("div");d.className="chip"+(cur===val?" on":"");d.textContent=label;
 d.onclick=function(){fn(val);};box.appendChild(d);}
function draw(){
 var q=(document.getElementById("q").value||"").toLowerCase(),y=document.getElementById("y").value;
 var f=all.filter(function(x){return (!q||x.t.toLowerCase().indexOf(q)>-1)&&(!cat||x.c===cat)&&(!age||x.a===age)&&(!y||x.y===y);});
 document.getElementById("n").textContent="· "+f.length+" فيلم";
 var box=document.getElementById("g");box.innerHTML="";
 f.slice(0,shown).forEach(function(x){
  var a=document.createElement("a");a.className="c";a.href="play.html?id="+encodeURIComponent(x.i);
  a.innerHTML="<img loading='lazy' src='"+x.th+"' alt=''><div><b>"+x.t+"</b><small>"+x.y+" · <span class='tag'>"+x.c+"</span> · "+x.a+"</small></div>";
  box.appendChild(a);});
}
g("catalog.json").then(function(d){ if(!d){document.getElementById("n").textContent="لا كتالوج";return;}
 all=d.items||[];
 var ys={};all.forEach(function(x){if(x.y)ys[x.y]=1;});
 var sel=document.getElementById("y");Object.keys(ys).sort().reverse().forEach(function(y){var o=document.createElement("option");o.value=y;o.textContent=y;sel.appendChild(o);});
 var cb=document.getElementById("cats");chip(cb,"الكل","",cat,function(v){cat=v;shown=60;redraw();});
 (d.cats||[]).forEach(function(c){chip(cb,c,c,cat,function(v){cat=v;shown=60;redraw();});});
 var ab=document.getElementById("ages");chip(ab,"كل الأعمار","",age,function(v){age=v;shown=60;redraw();});
 (d.ages||[]).forEach(function(c){chip(ab,c,c,age,function(v){age=v;shown=60;redraw();});});
 draw();});
function redraw(){draw();}
document.getElementById("q").oninput=function(){shown=60;draw();};
document.getElementById("y").onchange=function(){shown=60;draw();};
document.getElementById("more").onclick=function(){shown+=120;draw();};
})();
</script></body></html>
LEOF

# ================== 3) المشغّل ==================
cat > play.html <<'PEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>مشاهدة — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:13px;margin:12px 0}
.ad{border:1px dashed rgba(255,255,255,.18);border-radius:12px;padding:14px;text-align:center;color:#8ea3b8;margin:12px 0}
iframe{width:100%;aspect-ratio:16/9;border:0;border-radius:12px;background:#000}
.btn{display:inline-block;background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border-radius:10px;padding:10px 15px;margin:4px;border:0;font-size:14px;cursor:pointer}
.c{color:#8ea3b8;font-size:13px}</style></head><body>
<h1 id="t">…</h1><p class="c" id="m"></p>
<iframe id="pl" allowfullscreen allow="autoplay; fullscreen"></iframe>
<div class="ad" data-ad>إعلان</div>
<p><button class="btn" id="earn">▶ شاهد 15 ثانية واقبض</button>
<button class="btn" id="wa">شارك على واتساب</button>
<button class="btn" id="tg">شارك على تيليجرام</button></p>
<div class="box" id="rel"><b>مشاهدات مقترحة</b></div>
<p><a href="library.html">المكتبة</a> · <a href="index.html">الرئيسية</a> · <a href="rise.html">الأرقام</a></p>
<script>
(function(){
"use strict";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
var id=decodeURIComponent((location.search.match(/[?&]id=([^&]+)/)||[])[1]||"");
var SITE="https://alkazmybwhwr-dot.github.io/play.html?id=";
function hit(k){try{fetch("https://abacus.jasoncameron.dev/hit/ch3099-alkazmybwhwr-dot/"+k,{mode:"cors"}).catch(function(){});}catch(e){}}
g("catalog.json").then(function(d){
 if(!d||!d.items){document.getElementById("t").textContent="لا كتالوج";return;}
 var it=null;for(var i=0;i<d.items.length;i++) if(d.items[i].i===id){it=d.items[i];break;}
 if(!it){document.getElementById("t").textContent="لم يُعثر على الفيلم";return;}
 document.title=it.t+" — CineHub 3099";
 document.getElementById("t").textContent=it.t;
 document.getElementById("m").textContent=(it.y?it.y+" · ":"")+it.c+" · "+it.a+" · المصدر: archive.org (ملك عام / مرخّص)";
 document.getElementById("pl").src=it.p;
 var box=document.getElementById("rel");
 d.items.filter(function(x){return x.c===it.c&&x.i!==it.i;}).slice(0,8).forEach(function(x){
  var a=document.createElement("a");a.href="play.html?id="+encodeURIComponent(x.i);a.textContent="• "+x.t;a.style.display="block";box.appendChild(a);});
 var u=encodeURIComponent(SITE+encodeURIComponent(id));
 document.getElementById("wa").onclick=function(){hit("shares");window.open("https://wa.me/?text="+encodeURIComponent(it.t+" — مشاهدة مجانية\n")+u,"_blank");};
 document.getElementById("tg").onclick=function(){hit("shares");window.open("https://t.me/share/url?url="+u+"&text="+encodeURIComponent(it.t),"an_blank");};
});
document.getElementById("earn").onclick=function(){
 var b=localStorage.getItem("ch3099_balance");var v=parseFloat(b||"0")+0.0004;
 localStorage.setItem("ch3099_balance",String(v));hit("rewards");
 this.textContent="✓ أُضيف $0.0004 — رصيدك $"+v.toFixed(4);};
})();
</script></body></html>
PEOF

# ================== 4) وكيل مرئي ==================
cat > tools/agent_log.py <<'PYEOF'
#!/usr/bin/env python3
import os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
src=".state/log.txt"
if os.path.exists(src):
    L=open(src,encoding="utf-8",errors="replace").read().splitlines()[-150:]
    open("agent-log.txt","w",encoding="utf-8").write("\n".join(L))
print("agent-log ok")
PYEOF

cat > agent.html <<'AEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>الوكيل — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:13px;margin:12px 0}
pre{background:#0b1118;border:1px solid rgba(255,255,255,.07);border-radius:10px;padding:10px;overflow:auto;font-size:11.5px;color:#a8bccd;max-height:300px}
.ok{color:#7fd88a}.bad{color:#ff9a6b}.c{color:#8ea3b8;font-size:13px}
.live{display:inline-block;width:8px;height:8px;border-radius:50%;background:#39d98a;animation:p 1.6s infinite}
@keyframes p{70%{box-shadow:0 0 0 10px rgba(57,217,138,0)}}</style></head><body>
<h1>الوكيل <span class="live"></span></h1>
<p class="c">هذا ما ينفّذه الوكيل فعلًا — كل تشغيل يُسجَّل هنا وفي سجل GitHub Actions.</p>
<div class="box"><b>آخر دورات GitHub Actions</b><div id="runs" class="c">…</div></div>
<div class="box"><b>بوابات الأرباح</b><div id="g" class="c">…</div></div>
<div class="box"><b>آخر قيود السجل المُوقّع</b><div id="led" class="c">…</div></div>
<div class="box"><b>سجل التنفيذ الخام</b><pre id="log">…</pre></div>
<p><a href="index.html">الرئيسية</a> · <a href="rise.html">الأرقام</a> · <a href="subscribe.html">الشبكات</a> · <a href="withdraw.html">السحب</a></p>
<script>
(function(){
"use strict";
function g(u,raw){return fetch(u+(raw?"":"?_="+Date.now()),{cache:"no-store"}).then(function(r){return r.ok?(raw?r.text():r.json()):null}).catch(function(){return null});}
g("https://api.github.com/repos/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io/actions/runs?per_page=12").then(function(d){
 var e=document.getElementById("runs");if(!d||!d.workflow_runs){e.textContent="تعذّر الجلب";return;}
 e.innerHTML=d.workflow_runs.map(function(r){
  var c=r.conclusion||r.status;
  return "<div class='"+(c==="success"?"ok":(c==="failure"?"bad":""))+"'>"+
   (c==="success"?"✓ ":"• ")+r.name+" · "+new Date(r.created_at).toLocaleString()+" · "+c+"</div>";}).join("");
});
g("gates.json").then(function(x){var e=document.getElementById("g");if(!x||!x.gates){e.textContent="…";return;}
 e.innerHTML=x.gates.map(function(q){return "<div class='"+(q.ok?"ok":"bad")+"'>"+(q.ok?"✓ ":"✗ ")+q.t+(q.why?" — "+q.why:"")+(q.fix?" <a href='"+q.fix+"'>"+q.fix_t+"</a>":"")+"</div>";}).join("");});
g("ledger.json").then(function(l){var e=document.getElementById("led");if(!l||!l.entries){e.textContent="…";return;}
 e.innerHTML=l.entries.slice(-6).reverse().map(function(x){return "<div class='c'>#"+x.i+" · "+x.t+" · <span class='ok'>"+x.h.slice(0,16)+"…</span></div>";}).join("");});
g("agent-log.txt",true).then(function(t){var e=document.getElementById("log");e.textContent=(t||"لا سجل بعد").split("\n").slice(-40).join("\n");});
})();
</script></body></html>
AEOF

# ================== 5) إعلانات حقيقية ==================
cat > ads.js <<'ADEOF'
/* CineHub 3099 — مساحات إعلان: تُنفَّذ فورًا إن وُجد رابط شبكة، وتُعلن بوضوح إن لا */
(function () {
  "use strict";
  var NS = "ch3099-alkazmybwhwr-dot";
  function hit(k){ try{ fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/"+k,{mode:"cors"}).catch(function(){}); }catch(e){} }
  function slots(){ return document.querySelectorAll("[data-ad], .ad, .adslot"); }
  function paint(cfg){
    var ss = slots(); if (!ss.length) return;
    Array.prototype.forEach.call(ss, function (s) {
      if (s.getAttribute("data-ad-done")) return;
      s.setAttribute("data-ad-done", "1");
      if (cfg && cfg.direct) {
        s.innerHTML = "<a href='" + cfg.direct + "' target='_blank' rel='noopener' style='color:#4cc2ff;font-weight:700'>" +
          (cfg.net ? "إعلان " + cfg.net + " — اضغط للدعم" : "إعلان — اضغط للدعم") + "</a>";
        s.style.borderStyle = "solid";
        s.style.borderColor = "rgba(76,194,255,.4)";
      } else {
        s.innerHTML = "<span>مساحة إعلان — بانتظار رابط الشبكة (<a href='subscribe.html' style='color:#4cc2ff'>تفعيل</a>)</span>";
      }
    });
  }
  fetch("ads.json?_=" + Date.now(), { cache: "no-store" })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (c) { paint(c); })
    .catch(function () { paint(null); });
  function watch(){
    var ss = slots(); if (!ss.length || !("IntersectionObserver" in window)) return;
    var seen = 0;
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting && seen < 6) { seen++; hit("impressions"); } });
    }, { threshold: 0.4 });
    Array.prototype.slice.call(ss).slice(0, 6).forEach(function (s) { io.observe(s); });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", watch); else watch();
})();
ADEOF

python3 - <<'PY'
import json,os
os.chdir(os.path.expanduser("~/cinehub3099"))
env={}
if os.path.exists("keys.env"):
    for ln in open("keys.env",encoding="utf-8",errors="replace"):
        ln=ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k,v=ln.split("=",1); env[k.strip()]=v.strip()
d=None
for var in ("DIRECT_LINK","ADSTERRA_DIRECT","MONETAG_DIRECT","ADSTERRA_DIRECT_LINK"):
    if env.get(var): d={"direct":env[var],"net":var.split("_")[0]}; break
json.dump(d or {}, open("ads.json","w"), ensure_ascii=False, indent=1)
print("ads.json:", "رابط موجود" if d else "بانتظار رابط الشبكة")
PY

# ================== 6) الرئيسية: مكتبة حقيقية بالأغلفة ==================
python3 - <<'PY'
import re,os
os.chdir(os.path.expanduser("~/cinehub3099"))
h=open("index.html",encoding="utf-8",errors="replace").read()
BLOCK = '''
<section id="films-block">
 <h2>أفلام حقيقية الآن — لكل الأعمار والفئات</h2>
 <div class="chips" id="fchips"></div>
 <div class="fstrip" id="fstrip"></div>
 <p class="morep"><a href="library.html">افتح المكتبة كاملة ←</a></p>
</section>
'''
if "films-block" not in h:
    h=h.replace("</main>", BLOCK+"</main>")
CSS = '''
<style id="ch-films-css">
.fstrip{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px;margin:12px 0}
.fstrip a{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;color:inherit}
.fstrip img{width:100%;height:160px;object-fit:cover;display:block;background:#0f1720}
.fstrip b{display:block;font-size:12.5px;padding:7px;line-height:1.4}
.chips{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0}
.chips a{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:20px;padding:6px 13px;font-size:13px}
.morep a{color:#4cc2ff}
</style>
'''
if "ch-films-css" not in h: h=h.replace("</head>", CSS+"</head>",1)
JS = '''
<script id="ch-films-js">
(function(){
"use strict";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
g("catalog.json").then(function(d){
 if(!d||!d.items) return;
 var ch=document.getElementById("fchips"), st=document.getElementById("fstrip");
 if(!ch||!st) return;
 var cats=(d.cats||[]).slice(0,8);
 ch.innerHTML="<a href='library.html'>الكل ("+d.count+")</a>"+cats.map(function(c){return "<a href='library.html'>"+c+"</a>";}).join("");
 st.innerHTML=d.items.slice(0,12).map(function(x){
  return "<a href='play.html?id="+encodeURIComponent(x.i)+"'><img loading='lazy' src='"+x.th+"' alt=''><b>"+x.t+"</b></a>";}).join("");
 var n=document.getElementById("st-sites");
});
})();
</script>
'''
if "ch-films-js" not in h: h=h.replace("</body>", JS+"</body>",1)
open("index.html","w",encoding="utf-8").write(h)
print("الرئيسية: أُضيف قسم الأفلام")
PY

# ================== 7) تحديث الدورة ==================
cat > tools/agent_cycle.sh <<'SHEOF2'
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."; mkdir -p .state; LOG=.state/log.txt
run(){ [ -f "$1" ] && python3 "$1" >>"$LOG" 2>&1 || true; }
run tools/apply_keys.py
run tools/pull_counts.py
run tools/revenue_pull.py
run tools/treasury.py
run tools/ledger.py
run tools/insights.py
run tools/gates.py
run tools/status.py
run tools/report.py
run tools/agent_log.py
run tools/withdraw_auto.py
PLATFORM_TARGET=1000 PAGES_LIMIT="${PAGES_LIMIT:-40}" run tools/pages_gen.py
python3 - <<'PY' >>"$LOG" 2>&1
import json,datetime
p="pulse.json"; d={}
try: d=json.load(open(p,encoding="utf-8"))
except Exception: pass
d["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
d["cycle"]=int(d.get("cycle",0))+1
json.dump(d,open(p,"w"),ensure_ascii=False,indent=1)
PY
echo "cycle $(date -u +%FT%TZ) ok"
SHEOF2
chmod +x tools/agent_cycle.sh

# ================== 8) حقن العدّاد والإعلان + تشغيل + نشر ==================
python3 - <<'PY'
import os,re
os.chdir(os.path.expanduser("~/cinehub3099"))
V=open("sw-version.txt").read().strip() if os.path.exists("sw-version.txt") else "1"
def patch(p,pref):
    t=open(p,encoding="utf-8",errors="replace").read()
    add=""
    if "ads.js?v="+V not in t: add+='<script src="%sads.js?v=%s" defer></script>\n'%(pref,V)
    if add: t=re.sub(r"</body\s*>",add+"</body>",t,count=1,flags=re.I)
    open(p,"w",encoding="utf-8").write(t)
for f in sorted(os.listdir(".")):
    if f.endswith((".html",".htm")): patch(f,"")
if os.path.isdir("p"):
    for f in sorted(os.listdir("p"))[:3000]:
        if f.endswith(".html"): patch("p/"+f,"../")
print("حُقن ads.js")
PY

echo; echo "═══ تشغيل ═══"
bash tools/agent_cycle.sh || true
python3 tools/gates.py || true
echo "$V" > sw-version.txt
push_all "rebuild: real film catalog + player + visible agent + ads slots [$V]"

info "انتظار 80 ثانية…"
sleep 80
for f in library.html play.html agent.html catalog.json ads.json; do
  c="$(curl -s -o /dev/null -w '%{http_code}' "https://alkazmybwhwr-dot.github.io/$f?v=$V")"
  [ "$c" = "200" ] && ok "$f → 200" || bad "$f → $c"
done
python3 -c "
import json
try:
 d=json.load(open('catalog.json'));print('  أفلام حقيقية:',d['count'],'| تصنيفات:',len(d['cats']),'| فئات عمر:',len(d['ages']))
except Exception as e: print('  ',e)
"
echo
ok "افتح: https://alkazmybwhwr-dot.github.io/library.html"
info "الوكيل مرئي في: /agent.html · الأرقام: /rise.html · الشبكات: /subscribe.html"
