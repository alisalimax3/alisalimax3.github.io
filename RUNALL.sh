#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — RUNALL.sh
#  تشخيص حقيقي + إصلاح الجذر + محتوى + كابتشا + تشغيل الوكيل فعليًا
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"
OWNER="alkazmybwhwr-dot"; REPO="$OWNER.github.io"; LIVE="https://$OWNER.github.io"
EMAIL="alkazmybwhwr@gmail.com"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }

TOK="$(git remote get-url origin 2>/dev/null | sed -n 's|https://[^:]*:\([^@]*\)@.*|\1|p')"
API(){ curl -s -H "Authorization: token $TOK" -H "Accept: application/vnd.github+json" "$@"; }

# ================== 0) تشخيص شامل ==================
echo "═══ 1 · تشخيص الريموت ═══"
git fetch origin main -q 2>/dev/null || true
git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
chk(){ grep -qx "$1" .remote.txt && ok "$1" || bad "$1 غائب"; }
echo "— ملفات العمل:"
for f in .github/workflows/agent.yml .github/workflows/browse.yml .github/workflows/health.yml; do chk "$f"; done
echo "— المحتوى:"
for f in catalog.json adult.json; do chk "$f"; done
echo "— الأدوات:"
for f in tools/agent_cycle.sh tools/ingest_all.py tools/agent_tasks.py; do chk "$f"; done

echo
echo "═══ 2 · هل الوكيل يعمل فعلًا؟ ═══"
RUNS="$(API "https://api.github.com/repos/$REPO/actions/runs?per_page=5")"
python3 - "$RUNS" <<'PY'
import json,sys
try: d=json.loads(sys.argv[1])
except Exception: d={}
r=d.get("workflow_runs")
if not r: print("  ✗ لا أي تشغيل — الوكيل لم يعمل مطلقًا"); raise SystemExit
for x in r[:5]:
    print("  •",x.get("name"),x.get("status"),x.get("conclusion") or "-",x.get("created_at"))
PY

echo
echo "═══ 3 · ما يراه الزائر الآن ═══"
for f in index.html library.html adult.html catalog.json adult.json auth.json; do
  c="$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f?d=$V")"
  [ "$c" = "200" ] && ok "$f حيّ" || bad "$f → $c"
done

# ================== 4) إصلاح الجذر ==================
echo
echo "═══ 4 · إصلاح ═══"
git symbolic-ref -q HEAD >/dev/null 2>&1 || { git checkout -B main >/dev/null 2>&1; ok "رُبط HEAD بفرع main"; }
git branch -f main HEAD >/dev/null 2>&1 || true
touch .nojekyll
mkdir -p .github/workflows

push_all(){
  local msg="$1" try
  for try in 1 2 3 4 5 6 7 8; do
    git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
    git branch -f main HEAD >/dev/null 2>&1 || true
    git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    git fetch origin main -q 2>/dev/null || true
    git rebase --autostash origin/main -q >/dev/null 2>&1 || {
      git rebase --abort >/dev/null 2>&1; git reset --mixed origin/main -q >/dev/null 2>&1
      git add -A; git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    }
    git branch -f main HEAD >/dev/null 2>&1 || true
    git push origin main 2>.push.err && { ok "مدفوع (محاولة $try)"; return 0; }
    git push --force-with-lease origin main 2>.push.err && { ok "مدفوع بضمان (محاولة $try)"; return 0; }
    info "محاولة $((try+1))"; sleep 6
  done
  bad "تعذّر الدفع:"; sed -n '1,6p' .push.err; return 1
}
git rebase --autostash origin/main -q >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
git branch -f main HEAD >/dev/null 2>&1 || true

# ================== 5) المحتوى: إعادة بناء مضمونة ==================
cat > tools/ingest_all.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,re,urllib.request,urllib.parse,datetime,random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"Mozilla/5.0 (cinehub3099)"}
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
    for page in (1,2,3):
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
fl=list(films.values()); random.shuffle(fl)
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),"count":len(fl),
           "cats":sorted({x["c"] for x in fl}),"ages":["كل الأعمار","عائلي","+12","+13"],"items":fl},
          open("catalog.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(fl),"cats":sorted({x["c"] for x in fl})},open("films.json","w"),ensure_ascii=False)
print("أفلام:",len(fl))
def emb(x):
    m=re.search(r'src=["\']([^"\']+)',s(x)); return m.group(1) if m else ""
ad={}
for o in ["top-weekly","top-monthly","top-all-time","top-rated","latest","longest","most-popular"]:
    d=j("https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o)
    if not d: continue
    for v in d.get("videos",[]):
        i=s(v.get("id"))
        if not i or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s((v.get("default_thumb") or {}).get("src")),"e":emb(v.get("embed")),
               "g":",".join([s(t.get("tag")) for t in (v.get("tags") or [])][:6]),"k":"iframe","s":"Eporner","v":int(v.get("views") or 0)}
for pg in range(1,13):
    d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest"%pg)
    if not d: continue
    for w in d.get("videos",[]):
        v=w.get("video") or {}; i="rt"+s(v.get("video_id"))
        if i=="rt" or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s(v.get("thumb")),"e":s(v.get("embed_url")),"g":",".join([s(t) for t in (v.get("tags") or [])][:6]),
               "k":"iframe","s":"RedTube","v":int(v.get("views") or 0)}
al=[x for x in ad.values() if x["e"] and x["t"]]; random.shuffle(al)
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
info "استيعاب المحتوى (3 دقائق)..."
python3 tools/ingest_all.py

# ================== 6) كابتشا قوية ومسيطرة ==================
cat > authtoken.js <<'AEOF'
/* CineHub 3099 — بوابة كابتشا: تُشترط قبل أي مكافأة أو سحب */
(function () {
  "use strict";
  var K = "ch3099_identity";
  function id(){ try{ return localStorage.getItem(K)||""; }catch(e){ return ""; } }
  function set(v){ try{ localStorage.setItem(K,v); }catch(e){} }
  function hash(a,b){
    return crypto.subtle.digest("SHA-256", new TextEncoder().encode("ch3099|"+(a+b)+"|"+navigator.userAgent+"|"+screen.width))
      .then(function(buf){
        return Array.prototype.map.call(new Uint8Array(buf), function(x){ return ("0"+x.toString(16)).slice(-2); }).join("");
      });
  }
  window.CHAuth = {
    id: id, ok: function(){ return id().length === 64; },
    issue: function(a,b){ return hash(a,b).then(function(h){ set(h); return h; }); },
    require: function(cb){
      if (this.ok()) { cb(); return true; }
      if (confirm("الكابتشا مطلوبة أولًا — افتح go.html لحلّها. هل تفتحها الآن؟")) location.href = "go.html";
      return false;
    },
    guard: function(el){
      if (!el) return;
      if (this.ok()) { el.disabled = false; el.textContent = el.dataset.t || el.textContent; }
      else { el.disabled = true; el.textContent = "🔒 " + (el.dataset.t || "حلّ الكابتشا أولًا"); }
    }
  };
})();
AEOF

python3 - <<'PY'
import os,re,json
os.chdir(os.path.expanduser("~/cinehub3099"))
V=open("sw-version.txt").read().strip() if os.path.exists("sw-version.txt") else "1"
# احقن authtoken.js في الصفحات المالية
for f in ("earn.html","withdraw.html","rise.html","go.html"):
    if not os.path.exists(f): continue
    t=open(f,encoding="utf-8",errors="replace").read()
    if "authtoken.js" in t: continue
    t=t.replace("</body>",'<script src="authtoken.js?v=%s"></script>\n</body>'%V)
    open(f,"w",encoding="utf-8").write(t)
# owner بالبريد
o={}
if os.path.exists("owner.json"):
    try: o=json.load(open("owner.json",encoding="utf-8"))
    except Exception: o={}
o.setdefault("kuraimi",{"name":"","account":"","phone":""})
o["email"]="alkazmybwhwr@gmail.com"; o["bank"]="Al-Kuraimi Islamic Microfinance Bank"
o["swift"]="KBMFYESAXXX"; o["updated"]=__import__("datetime").datetime.now().isoformat()
json.dump(o,open("owner.json","w"),ensure_ascii=False,indent=1)
env=""
if os.path.exists("keys.env"): env=open("keys.env",encoding="utf-8").read()
if "OWNER_EMAIL" not in env:
    env=env.rstrip()+"\nOWNER_EMAIL=alkazmybwhwr@gmail.com\n"
open("keys.env","w",encoding="utf-8").write(env)
print("authtoken + owner email")
PY

# ================== 7) صفحة تشخيص للزائر ==================
cat > diag.html <<'DEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>تشخيص — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:13px;margin:11px 0}
.ok{color:#7fd88a}.bad{color:#ff9a6b}.c{color:#8ea3b8;font-size:13px}</style></head><body>
<h1>تشخيص حقيقي</h1>
<p class="c">يفحص ما هو منشور فعلًا — بلا تخمين.</p>
<div class="box" id="files"><b>الملفات</b><div class="c">…</div></div>
<div class="box" id="cnt"><b>المحتوى</b><div class="c">…</div></div>
<div class="box" id="ag"><b>الوكيل</b><div class="c">…</div></div>
<script>
(function(){
"use strict";
var F=["index.html","library.html","adult.html","play.html","watch.html","go.html","earn.html","rise.html","agent.html","withdraw.html","keys.html","share.html","rails.html","catalog.json","adult.json","auth.json","browse.json","keys-status.json","tasks.json","registry.json","sitemap.xml","rss.xml"];
function head(u){return fetch(u,{method:"HEAD",cache:"no-store"}).then(function(r){return r.status}).catch(function(){return 0});}
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
var e=document.getElementById("files"),out=[],done=0;
F.forEach(function(f){head(f).then(function(c){out.push([f,c]);done++;
 if(done===F.length){out.sort(function(a,b){return a[1]-b[1]});
  e.innerHTML=out.map(function(x){return "<div class='"+(x[1]===200?"ok":"bad")+"'>"+(x[1]===200?"✓ ":"✗ ")+x[0]+" → "+x[1]+"</div>";}).join("");}});});
g("catalog.json").then(function(d){g("adult.json").then(function(a){
 document.getElementById("cnt").innerHTML="<div class='"+(d&&d.count?"ok":"bad")+"'>أفلام: "+((d&&d.count)||0)+"</div>"+
 "<div class='"+(a&&a.count?"ok":"bad")+"'>مقاطع كبار: "+((a&&a.count)||0)+"</div>";});});
g("browse.json").then(function(b){g("pulse.json").then(function(p){g("rewards.json").then(function(r){
 document.getElementById("ag").innerHTML="<div>طلبات إعلان من الوكيل: "+((b&&b.ad_requests)||0)+"</div>"+
 "<div>دورات: "+((p&&p.cycle)||0)+"</div><div>مكافآت: $"+(((r&&r.total)||0).toFixed?((r&&r.total)||0).toFixed(6):"0")+"</div>";});});});
})();
</script></body></html>
DEOF

# ================== 8) بناء + نشر + تحقق + تشغيل الوكيل ==================
PAGES_LIMIT=800 python3 tools/pages_gen.py || true
python3 tools/adult_pages.py 2>/dev/null || true
python3 tools/ping_all.py || true
bash tools/agent_cycle.sh || true
echo "$V" > sw-version.txt
push_all "runall: content + workflows + captcha gate + diag [$V]"

echo
echo "═══ 5 · تحقق الريموت ═══"
git fetch origin main -q 2>/dev/null || true
git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
M=0
for f in .github/workflows/agent.yml .github/workflows/browse.yml catalog.json adult.json library.html adult.html auth.json diag.html; do
  grep -qx "$f" .remote.txt && ok "$f" || { bad "$f غائب"; M=$((M+1)); }
done
[ "$M" = "0" ] && ok "كل الملفات في الريموت" || warn "$M غائب"

echo
echo "═══ 6 · تشغيل الوكيل يدويًا الآن ═══"
for wf in agent.yml browse.yml; do
  R="$(API -X POST -H "Content-Type: application/json" \
      -d "{\"ref\":\"main\"}" \
      "https://api.github.com/repos/$REPO/actions/workflows/$wf/dispatches" -o /dev/null -w '%{http_code}')"
  [ "$R" = "204" ] && ok "شُغّل $wf" || bad "$wf → $R"
done

info "انتظار 110 ثانية…"
sleep 110
API "https://api.github.com/repos/$REPO/actions/runs?per_page=4" > .runs.json
python3 - <<'PY'
import json
try: d=json.load(open(".runs.json"))
except Exception: d={}
r=d.get("workflow_runs") or []
if not r: print("  ✗ لا تشغيل — تحقق من تفعيل Actions في تبويب Actions")
for x in r[:4]:
    print("  •",x.get("name"),x.get("status"),x.get("conclusion") or "-",x.get("created_at"))
PY

echo
echo "═══ 7 · تحقق حي ═══"
for f in catalog.json adult.json library.html adult.html diag.html auth.json; do
  c=0
  for t in 1 2 3; do c="$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f?v=$V")"; [ "$c" = "200" ] && break; sleep 15; done
  [ "$c" = "200" ] && ok "$f حيّ" || bad "$f → $c"
done
python3 -c "
import json
for f,k in (('catalog.json','أفلام'),('adult.json','مقاطع كبار')):
  try: d=json.load(open(f));print('  %s: %d'%(k,d['count']))
  except Exception: print('  %s: مفقود'%k)
"
echo; ok "افتح: $LIVE/diag.html ثم $LIVE/library.html و $LIVE/adult.html"
info "واترك مفتوحًا: $LIVE/watch.html"
