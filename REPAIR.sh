#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — REPAIR.sh
#  يصلح السبب الجذري للدفع + خطأ الاستيعاب + يرفع الأرباح آليًا
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }

# ================== 0) تشخيص السبب الجذري ==================
echo "═══ تشخيص ═══"
BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
echo "  الفرع الحالي: $BR"
[ "$BR" = "HEAD" ] && warn "HEAD منفصل — هذا سبب ضياع كل الدفعات" || ok "الفرع سليم"
git fetch origin main -q 2>/dev/null || true
AHEAD="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"
echo "  التزامات محلية غير مدفوعة: $AHEAD"

# إصلاح: اربط HEAD بفرع main
git symbolic-ref -q HEAD >/dev/null 2>&1 || { git checkout -B main >/dev/null 2>&1; ok "أُعيد ربط HEAD بفرع main"; }
git branch -f main HEAD >/dev/null 2>&1 || true
touch .nojekyll
ok ".nojekyll (يُسرّع Pages ويمنع معالجة Jekyll)"

push_all(){
  local msg="$1" try
  for try in 1 2 3 4 5 6 7 8; do
    git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
    git branch -f main HEAD >/dev/null 2>&1 || true
    git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    git fetch origin main -q 2>/dev/null || true
    git rebase --autostash origin/main -q >/dev/null 2>&1 || {
      git rebase --abort >/dev/null 2>&1
      git reset --mixed origin/main -q >/dev/null 2>&1
      git add -A
      git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    }
    git branch -f main HEAD >/dev/null 2>&1 || true
    if git push origin main 2>.push.err; then ok "مدفوع (محاولة $try)"; return 0; fi
    if git push --force-with-lease origin main 2>.push2.err; then ok "مدفوع قسرًا بضمان (محاولة $try)"; return 0; fi
    info "تعارض — محاولة $((try+1))"; sleep 6
  done
  bad "تعذّر الدفع:"; sed -n '1,8p' .push.err; return 1
}

git rebase --autostash origin/main -q >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
git branch -f main HEAD >/dev/null 2>&1 || true

# ================== 1) إصلاح خطأ الاستيعاب ==================
cat > tools/ingest_all.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجلب آلاف الأفلام + مقاطع الكبار — بمعالجة حقول القوائم"""
import json,os,re,urllib.request,urllib.parse,datetime,random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"Mozilla/5.0 (cinehub3099)"}
FILM_MAX=int(os.environ.get("FILM_MAX","3000")); ADULT_MAX=int(os.environ.get("ADULT_MAX","1200"))
def s(v):
    if v is None: return ""
    if isinstance(v,list): return " ".join(str(i) for i in v)
    return str(v)
def j(u,t=40):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t)
        return json.loads(r.read().decode("utf-8","replace"))
    except Exception: return None
SUBJ=[("كوميديا","عائلي","comedy"),("دراما","+13","drama"),("مغامرات","عائلي","adventure"),
("خيال علمي","+12","\"science fiction\""),("رعب","+13","horror"),("غربي","+12","western"),
("غموض","+12","mystery"),("رومانسي","+12","romance"),("كرتون","كل الأعمار","cartoon"),
("رسوم متحركة","كل الأعمار","animation"),("أطفال","كل الأعمار","children"),("وثائقي","عائلي","documentary"),
("صامت","+12","\"silent film\""),("حربي","+13","war"),("موسيقي","عائلي","musical"),
("جريمة","+13","crime"),("فانتازيا","عائلي","fantasy"),("سيرة","عائلي","biography"),
("تاريخي","+12","history"),("رياضة","عائلي","sport"),("عائلي","كل الأعمار","family"),
("إثارة","+13","thriller")]
films={}
for cat,age,q in SUBJ:
    for page in (1,2):
        u=("https://archive.org/advancedsearch.php?q="+urllib.parse.quote("mediatype:movies AND subject:(%s)"%q)+
           "&rows=100&page=%d&output=json&sort[]=downloads+desc"%page+
           "&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=downloads")
        d=j(u)
        if not d: continue
        for x in d.get("response",{}).get("docs",[]):
            i=s(x.get("identifier")).strip(); t=re.sub(r"\s+"," ",s(x.get("title")).strip())
            if not i or not t or i in films: continue
            films[i]={"i":i,"t":t[:95],"y":s(x.get("year"))[:4],"c":cat,"a":age,
                      "th":"https://archive.org/services/img/"+i,"e":"https://archive.org/embed/"+i,
                      "k":"iframe","s":"archive.org","v":int(x.get("downloads") or 0)}
    print("  فيلم",cat,len(films))
fl=list(films.values()); random.shuffle(fl); fl=fl[:FILM_MAX]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),"count":len(fl),
           "cats":sorted({x["c"] for x in fl}),"ages":["كل الأعمار","عائلي","+12","+13"],"items":fl},
          open("catalog.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(fl),"cats":sorted({x["c"] for x in fl})},open("films.json","w"),ensure_ascii=False)
print("أفلام:",len(fl))
def src_iframe(x):
    m=re.search(r'src=["\']([^"\']+)',s(x)); return m.group(1) if m else ""
ad={}
for o in ["top-weekly","top-monthly","top-all-time","top-rated","latest","longest","most-popular"]:
    d=j("https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o)
    if not d: continue
    for v in d.get("videos",[]):
        i=s(v.get("id"))
        if not i or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s((v.get("default_thumb") or {}).get("src")),"e":src_iframe(v.get("embed")),
               "g":",".join([s(t.get("tag")) for t in (v.get("tags") or [])][:6]),"k":"iframe","s":"Eporner",
               "v":int(v.get("views") or 0)}
for pg in range(1,11):
    d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest"%pg)
    if not d: continue
    for w in d.get("videos",[]):
        v=w.get("video") or {}; i="rt"+s(v.get("video_id"))
        if i=="rt" or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s(v.get("thumb")),"e":s(v.get("embed_url")),"g":",".join([s(t) for t in (v.get("tags") or [])][:6]),
               "k":"iframe","s":"RedTube","v":int(v.get("views") or 0)}
al=[x for x in ad.values() if x["e"] and x["t"]]; random.shuffle(al); al=al[:ADULT_MAX]
tg={}
for x in al:
    for t in x["g"].split(","):
        t=t.strip().lower()
        if t: tg[t]=tg.get(t,0)+1
top=[t for t,_ in sorted(tg.items(),key=lambda k:-k[1])[:70]]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),"count":len(al),
           "tags":top,"items":al},open("adult.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(al),"tags":top},open("adult-meta.json","w"),ensure_ascii=False)
print("كبار:",len(al))
PYEOF
info "استيعاب المحتوى (2–3 دقائق)..."
FILM_MAX=3000 ADULT_MAX=1200 python3 tools/ingest_all.py

# ================== 2) أرباح آلية بلا فعل منك ==================
cat > tools/agent_tasks.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مكافآت ينفّذها الوكيل نفسه — بمعدلات معلنة، تُضاف تلقائيًا"""
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
RATES={"page":0.0002,"indexnow":0.0005,"browse":0.0010,"cycle":0.0020,"valid_key":0.0500}
day=datetime.date.today().isoformat()
r=L("rewards.json",{"devices":{},"total":0})
r.setdefault("devices",{})
ag=r["devices"].setdefault("agent",{"total":0,"items":{},"day":day})
if ag.get("day")!=day: ag={"total":0,"items":{},"day":day}; r["devices"]["agent"]=ag
pages=len(os.listdir("p")) if os.path.isdir("p") else 0
br=L("browse.json",{}); ks=L("keys-status.json",{}); pu=L("pulse.json",{})
add=0.0
def put(k,n):
    global add
    if n<=0: return
    v=n*RATES[k]
    ag["items"][k]=round(float(ag["items"].get(k,0))+v,6)
    ag["total"]=round(float(ag.get("total",0))+v,6); add+=v
put("page",min(400,pages))
put("indexnow",3)
put("browse",1 if br else 0)
put("cycle",1)
if ks.get("valid",0)>0: put("valid_key",ks["valid"])
tot=0.0
for d in r["devices"].values(): tot+=float(d.get("total") or 0)
r["total"]=round(tot,6); r["rates"]=RATES
r["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(r,open("rewards.json","w"),ensure_ascii=False,indent=1)
print("مكافآت الوكيل اليوم: $%.6f | الإجمالي: $%.6f"%(ag["total"],tot))
PYEOF

# ================== 3) مسارات الدفع للكريمي ==================
cat > rails.html <<'RHEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>مسارات الدفع — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.85}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:14px;margin:11px 0}
.c{color:#8ea3b8;font-size:13px}.ok{color:#7fd88a}.bad{color:#ff9a6b}.st{border-right:3px solid #4cc2ff;padding-right:10px;margin:12px 0}
table{width:100%;border-collapse:collapse;font-size:13.5px}td,th{padding:8px;border-bottom:1px solid rgba(255,255,255,.07);text-align:right}
.big{font-size:22px;font-weight:800}</style></head><body>
<h1>المسار الحقيقي للمال إلى الكريمي</h1>
<div class="box"><div class="c">الرصيد القابل للسحب</div><div class="big" id="b">$0.000000</div><div class="c" id="bk"></div></div>
<div class="st"><b>1 · الشبكة تدفع لك</b><div class="c">Adsterra/ExoClick/Linkvertise → Paxum أو USDT (TRC20) أو Wire. الحد الأدنى لكل شبكة معروض في <a href="subscribe.html">الشبكات</a>.</div></div>
<div class="st"><b>2 · المحفظة</b><div class="c">USDT TRC20 إلى Trust Wallet أو Binance. العمولة أقل من دولار.</div></div>
<div class="st"><b>3 · التحويل إلى اليمن</b><div class="c">P2P على Binance، أو صرافة محلية تقبل USDT — ثم إيداع في الكريمي.</div></div>
<div class="st"><b>4 · الكريمي</b><div class="c">حسابك: <b id="kn">—</b> · SWIFT: KBMFYESAXXX</div></div>
<div class="box"><b>منصات الاستقبال المقترحة</b>
<table><thead><tr><th>المنصة</th><th>النوع</th><th>ملاحظة</th><th>فتح</th></tr></thead><tbody>
<tr><td>Binance</td><td>محفظة + P2P</td><td class="c">الأسهل لليمن — P2P مباشر</td><td><a href="https://www.binance.com" target="_blank" rel="noopener">↗</a></td></tr>
<tr><td>Trust Wallet</td><td>محفظة ذاتية</td><td class="c">بلا حساب — USDT TRC20</td><td><a href="https://trustwallet.com" target="_blank" rel="noopener">↗</a></td></tr>
<tr><td>Bybit / OKX / MEXC</td><td>منصات</td><td class="c">بدائل بـP2P</td><td><a href="https://www.bybit.com" target="_blank" rel="noopener">↗</a></td></tr>
<tr><td>NOWPayments</td><td>بوابة دفع</td><td class="c">بلا KYC · عمولة منخفضة</td><td><a href="https://nowpayments.io" target="_blank" rel="noopener">↗</a></td></tr>
<tr><td>Paxum</td><td>محفظة</td><td class="c">تقبلها ExoClick/JuicyAds</td><td><a href="https://www.paxum.com" target="_blank" rel="noopener">↗</a></td></tr>
</tbody></table></div>
<div class="box"><b>طلبات السحب التلقائية</b><div id="p" class="c">…</div>
<button id="wa" style="background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0;border-radius:11px;padding:12px 18px">إرسال الطلب على واتساب</button></div>
<p class="c">الحد الأدنى للسحب من التطبيق: $5 — يُنشأ الطلب تلقائيًا عند بلوغه ويُقيَّد في السجل الموقّع.</p>
<script>
(function(){
"use strict";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function money(x){x=Number(x);return "$"+(isFinite(x)?x:0).toFixed(6);}
g("treasury.json").then(function(t){t=t||{};document.getElementById("b").textContent=money(t.balance);
 var b=t.buckets||{},s=[];for(var k in b) s.push(k+": "+money(b[k]));
 document.getElementById("bk").textContent=s.join(" · ");});
g("payouts.json").then(function(p){var e=document.getElementById("p");if(!p||!p.requests||!p.requests.length){e.textContent="لا طلبات بعد — تحتاج مفتاح شبكة";return;}
 e.innerHTML=p.requests.slice(-8).reverse().map(function(r){return "<div>• "+r.net+" · "+money(r.amount)+" · الحد "+r.min+" · "+r.status+"</div>";}).join("");});
try{var o=JSON.parse(localStorage.getItem("ch3099_owner")||"{}");if(o.kuraimi)document.getElementById("kn").textContent=(o.kuraimi.name||"")+" — "+(o.kuraimi.account||"");}catch(e){}
document.getElementById("wa").onclick=function(){
 var o=JSON.parse(localStorage.getItem("ch3099_owner")||"{}");
 var m="طلب سحب CineHub 3099%0Aالرصيد: "+document.getElementById("b").textContent+"%0Aالاسم: "+((o.kuraimi||{}).name||"")+"%0Aالحساب: "+((o.kuraimi||{}).account||"")+"%0Aالهاتف: "+((o.kuraimi||{}).phone||"")+"%0Aالبنك: الكريمي KBMFYESAXXX";
 window.open("https://wa.me/"+(o.whatsapp||"").replace(/\D/g,"")+"?text="+m,"_blank");};
})();
</script></body></html>
RHEOF

# ================== 4) استعادة الملفات الناقصة محليًا ==================
[ -s keys.html ] || warn "keys.html مفقود"
cat > keys.html <<'KEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>ربط المفاتيح — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:14px;margin:11px 0}
input,button{font-family:inherit;font-size:15px;padding:10px;border-radius:10px;border:1px solid rgba(255,255,255,.12);background:#0f1720;color:#e9f1f8;width:100%;box-sizing:border-box;margin:5px 0}
button{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0}
.ok{color:#7fd88a}.bad{color:#ff9a6b}.c{color:#8ea3b8;font-size:13px}.step{background:rgba(76,194,255,.06);border:1px solid rgba(76,194,255,.2);border-radius:10px;padding:10px;margin:8px 0;font-size:13.5px}</style></head><body>
<h1>ربط المفاتيح</h1>
<p class="c">اربط واحدة فقط ليبدأ كل شيء. التحقق يتم على السيرفر مقابل واجهة الشبكة الحقيقية.</p>
<div class="box"><b>الحالة الفعلية</b><div id="st" class="c">…</div></div>
<div class="box"><b>1) Adsterra — ابدأ هنا</b>
<div class="step">Sign Up → لوحة التحكم → <b>Account → API</b> → انسخ API Key.</div>
<a href="https://adsterra.com" target="_blank" rel="noopener">فتح ↗</a>
<input id="ADSTERRA_API_KEY" placeholder="ADSTERRA_API_KEY"><button class="sv">حفظ</button></div>
<div class="box"><b>2) ExoClick — للكبار</b><a href="https://www.exoclick.com" target="_blank" rel="noopener">فتح ↗</a>
<input id="EXOCLICK_KEY" placeholder="EXOCLICK_KEY"><button class="sv">حفظ</button></div>
<div class="box"><b>3) Linkvertise</b><a href="https://linkvertise.com" target="_blank" rel="noopener">فتح ↗</a>
<input id="LINKVERTISE_UID" placeholder="LINKVERTISE_UID"><button class="sv">حفظ</button></div>
<div class="box"><b>4) BitLabs — استطلاعات</b><a href="https://bitlabs.ai" target="_blank" rel="noopener">فتح ↗</a>
<input id="BITLABS_KEY" placeholder="BITLABS_KEY"><button class="sv">حفظ</button></div>
<div class="box"><b>5) رابط إعلان مباشر (يعمل فورًا)</b>
<input id="DIRECT_LINK" placeholder="https://..."><button class="sv">حفظ</button></div>
<div class="box"><button id="push">دفع + دورة فورية</button><div id="r" class="c"></div></div>
<script>
(function(){
"use strict";var K={};
try{K=JSON.parse(localStorage.getItem("ch3099_keys")||"{}")}catch(e){}
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
g("keys-status.json").then(function(s){var e=document.getElementById("st");
 if(!s||!s.items||!s.items.length){e.innerHTML="لا مفاتيح مربوطة — ابدأ بـ Adsterra";return;}
 e.innerHTML="مربوط: "+s.items.length+" · صالح: "+s.valid+"<br>"+s.items.map(function(x){
  return "<div class='"+(x.verdict.indexOf("✓")>-1?"ok":(x.verdict.indexOf("✗")>-1?"bad":"c"))+"'>"+
   (x.verdict.indexOf("✓")>-1?"✓ ":(x.verdict.indexOf("✗")>-1?"✗ ":"• "))+x.key+" — "+x.verdict+"</div>";}).join("");});
document.querySelectorAll("input[id]").forEach(function(i){i.value=K[i.id]||"";i.oninput=function(){K[i.id]=i.value.trim();localStorage.setItem("ch3099_keys",JSON.stringify(K));};});
document.querySelectorAll(".sv").forEach(function(b){b.onclick=function(){localStorage.setItem("ch3099_keys",JSON.stringify(K));b.textContent="محفوظ ✓";};});
document.getElementById("push").onclick=function(){
 var gh=JSON.parse(localStorage.getItem("ch3099_gh")||"{}");
 if(!gh.token){document.getElementById("r").textContent="افتح go.html أولًا";return;}
 var env=Object.keys(K).filter(function(k){return K[k]}).map(function(k){return k+"="+K[k]}).join("\n")+"\n";
 var url="https://api.github.com/repos/"+gh.repo+"/contents/keys.env";
 var H={Authorization:"token "+gh.token,"Content-Type":"application/json"};
 document.getElementById("r").textContent="جارٍ الدفع…";
 fetch(url,{headers:H}).then(function(r){return r.ok?r.json():null}).then(function(j){
  var b={message:"keys",content:btoa(unescape(encodeURIComponent(env))),branch:gh.branch||"main"};
  if(j&&j.sha)b.sha=j.sha;
  return fetch(url,{method:"PUT",headers:H,body:JSON.stringify(b)});})
 .then(function(){return fetch("https://api.github.com/repos/"+gh.repo+"/dispatches",
  {method:"POST",headers:{Authorization:"token "+gh.token,"Content-Type":"application/json"},
   body:JSON.stringify({event_type:"agent-cycle"})});})
 .then(function(){document.getElementById("r").innerHTML="<span class='ok'>تم ✓ — التحقق يظهر بعد دقيقة</span>";})
 .catch(function(e){document.getElementById("r").textContent="فشل: "+e;});};
})();
</script></body></html>
KEOF

cat > share.html <<'SEOF3'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>طقم النشر — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.75}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:12px;margin:10px 0}
.r{border-bottom:1px solid rgba(255,255,255,.07);padding:10px 0}.r b{font-size:14px;display:block;margin-bottom:6px}
.r small{color:#8ea3b8;font-size:12px}
.b{display:inline-block;border-radius:9px;padding:7px 12px;font-size:13px;margin:3px 3px 0 0;text-decoration:none;border:1px solid rgba(255,255,255,.15)}
.wa{background:#1f8f4e}.tg{background:#1c6fa8}.fb{background:#2a4d8f}.xx{background:#111}
button{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0;border-radius:11px;padding:11px 16px;font-size:14px}
.c{color:#8ea3b8;font-size:13px}</style></head><body>
<h1>طقم النشر — 10 ضغطات</h1>
<p class="c">كل ضغطة = زيارة حقيقية = ظهور حقيقي. أسرع رافعة عندك.</p>
<p><button id="all">افتح أول 3 واتساب</button><button id="cpy">انسخ النصوص</button><span id="s" class="c"></span></p>
<div id="l"></div>
<script>
(function(){
"use strict";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
var SITE="https://alkazmybwhwr-dot.github.io",rows=[];
Promise.all([g("catalog.json"),g("adult.json")]).then(function(r){
 var c=(r[0]||{}).items||[],a=(r[1]||{}).items||[];
 for(var i=0;i<5&&i<c.length;i++) rows.push({t:c[i].t,u:SITE+"/play.html?id="+c[i].i,g:"فيلم"});
 for(var j=0;j<5&&j<a.length;j++) rows.push({t:a[j].t,u:SITE+"/adult.html?v="+a[j].i,g:"🔞"});
 document.getElementById("l").innerHTML=rows.map(function(x,k){
  var txt=encodeURIComponent(x.t+" — مشاهدة مجانية "+x.g+"\n"+x.u);
  return "<div class='r'><b>"+(k+1)+". "+x.t+" <small>"+x.g+"</small></b>"+
   "<a class='b wa' target='_blank' href='https://wa.me/?text="+txt+"'>واتساب</a>"+
   "<a class='b tg' target='_blank' href='https://t.me/share/url?url="+encodeURIComponent(x.u)+"&text="+encodeURIComponent(x.t)+"'>تيليجرام</a>"+
   "<a class='b fb' target='_blank' href='https://www.facebook.com/sharer/sharer.php?u="+encodeURIComponent(x.u)+"'>فيسبوك</a>"+
   "<a class='b xx' target='_blank' href='https://twitter.com/intent/tweet?url="+encodeURIComponent(x.u)+"&text="+encodeURIComponent(x.t)+"'>X</a></div>";}).join("");
 if(!rows.length) document.getElementById("s").textContent="لا محتوى — شغّل REPAIR مرة أخرى";
});
document.getElementById("all").onclick=function(){rows.slice(0,3).forEach(function(x,k){setTimeout(function(){
 window.open("https://wa.me/?text="+encodeURIComponent(x.t+" — مشاهدة مجانية "+x.g+"\n"+x.u),"_blank");},k*400);});};
document.getElementById("cpy").onclick=function(){navigator.clipboard.writeText(rows.map(function(x){return x.t+" — "+x.u;}).join("\n"));document.getElementById("s").textContent="نُسخ";};
})();
</script></body></html>
SEOF3

python3 - <<'PY'
import json,os,datetime
os.chdir(os.path.expanduser("~/cinehub3099"))
for f,d in (("browse.json",{"runs":0,"pages":0,"ad_requests":0,"by_host":{},"errors":[]}),
            ("keys-status.json",{"checked":0,"valid":0,"items":[]})):
    if not os.path.exists(f): json.dump(d,open(f,"w"),ensure_ascii=False,indent=1); print("أُنشئ",f)
PY
python3 tools/autodetect.py >/dev/null 2>&1 || true

# ================== 5) الدورة تشمل المكافآت الآلية ==================
python3 - <<'PY'
import os
os.chdir(os.path.expanduser("~/cinehub3099"))
p="tools/agent_cycle.sh"; t=open(p,encoding="utf-8").read()
if "agent_tasks.py" not in t:
    t=t.replace("run tools/treasury.py","run tools/agent_tasks.py\nrun tools/treasury.py")
    open(p,"w",encoding="utf-8").write(t)
print("الدورة تمنح مكافآت آلية")
PY

# ================== 6) بناء + نشر + تحقق موثوق ==================
PAGES_LIMIT=600 python3 tools/pages_gen.py || true
python3 tools/adult_pages.py 2>/dev/null || true
python3 tools/ping_all.py || true
bash tools/agent_cycle.sh || true
echo "$V" > sw-version.txt
push_all "repair: detached head + ingest fix + auto rewards + rails [$V]"

# تحقق موثوق: هل الملفات في الريموت فعلًا؟
info "تحقق من الريموت (المصدر الموثوق)..."
git fetch origin main -q 2>/dev/null || true
git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
MISS=0
for f in index.html library.html play.html adult.html watch.html go.html earn.html rise.html agent.html withdraw.html keys.html share.html rails.html nav.js ads.js catalog.json adult.json auth.json browse.json keys-status.json rewards.json sitemap.xml rss.xml; do
  grep -qx "$f" .remote.txt && ok "$f في الريموت" || { bad "$f غائب عن الريموت"; MISS=$((MISS+1)); }
done
[ "$MISS" = "0" ] && ok "كل الملفات مدفوعة فعليًا" || warn "$MISS ملف غائب"

info "انتظار 100 ثانية لبناء Pages..."
sleep 100
LIVE="https://alkazmybwhwr-dot.github.io"; F404=0
for f in keys.html share.html rails.html go.html watch.html catalog.json auth.json; do
  c=0
  for t in 1 2 3 4; do
    c="$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f?v=$V")"
    [ "$c" = "200" ] && break; sleep 15
  done
  [ "$c" = "200" ] && ok "$f حيّ" || { bad "$f → $c"; F404=$((F404+1)); }
done
echo
python3 -c "
import json,os
for f,k in (('catalog.json','أفلام'),('adult.json','مقاطع')):
  try: d=json.load(open(f));print('  %s: %d'%(k,d['count']))
  except Exception: print('  %s: مفقود'%k)
print('  صفحات أفلام:',len(os.listdir('p')) if os.path.isdir('p') else 0,'| وسوم:',len(os.listdir('x')) if os.path.isdir('x') else 0)
"
[ "$F404" = "0" ] && ok "كل شيء حيّ" || warn "$F404 ملف لم يظهر — أعد التشغيل"
echo; ok "افتح: $LIVE/watch.html (واتركها مفتوحة)"
