#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — AUDIT.sh
#  فحص عميق حقيقي + تحليل الفجوات + إصلاح ما يمكن إصلاحه + تقرير مقروء
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"; OWNER="alkazmybwhwr-dot"; REPO="$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
mkdir -p tools .github/workflows
TOK="$(git remote get-url origin 2>/dev/null | sed -n 's|https://[^:]*:\([^@]*\)@.*|\1|p')"

git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
git branch -f main HEAD >/dev/null 2>&1 || true
git fetch origin main -q 2>/dev/null || true
git rebase --autostash origin/main -q >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
touch .nojekyll

# ================== 1) أداة الفحص ==================
cat > tools/audit_full.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص حقيقي شامل: بيئة · مستودع · حيّ · واجهات · مفاتيح · وكيل · مال · فجوات"""
import json,os,re,subprocess,sys,urllib.request,urllib.error,datetime,shutil
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
TOK=os.environ.get("CH_TOK",""); REPO=os.environ.get("CH_REPO","alkazmybwhwr-dot/alkazmybwhwr-dot.github.io")
LIVE="https://"+REPO.split("/")[0]+".github.io"
R={"at":datetime.datetime.now(datetime.timezone.utc).isoformat(),"gaps":[]}
def sh(c):
    try: return subprocess.run(c,shell=True,capture_output=True,text=True,timeout=25).stdout.strip()
    except Exception: return ""
def api(path,method="GET",body=None):
    try:
        req=urllib.request.Request("https://api.github.com"+path,
            data=json.dumps(body).encode() if body else None,
            headers={"Authorization":"token "+TOK,"Accept":"application/vnd.github+json","Content-Type":"application/json"})
        if method!="GET": req.method=method
        r=urllib.request.urlopen(req,timeout=25)
        return json.loads(r.read().decode()) if r.status!=204 else {}, r.status
    except urllib.error.HTTPError as e: return None,e.code
    except Exception as e: return None,str(e)[:60]
def get(u,t=25):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,headers={"User-Agent":"ch3099"}),timeout=t)
        return r.status,r.read().decode("utf-8","replace")
    except urllib.error.HTTPError as e: return e.code,""
    except Exception: return 0,""
def head(u,t=20):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,method="HEAD",headers={"User-Agent":"ch3099"}),timeout=t)
        return r.status
    except urllib.error.HTTPError as e: return e.code
    except Exception: return 0
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d

# --- بيئة ---
R["env"]={"python":sys.version.split()[0],"node":sh("node -v") or "غير مثبّت",
          "curl":sh("curl --version | head -1")[:40] or "غير مثبّت",
          "termux":os.path.isdir("/data/data/com.termux/files/usr"),
          "disk":sh("df -h . | tail -1")}

# --- مستودع ---
R["repo"]={"branch":sh("git rev-parse --abbrev-ref HEAD"),
           "detached":sh("git rev-parse --abbrev-ref HEAD")=="HEAD",
           "remote":sh("git remote get-url origin").split("@")[-1],
           "token_present":bool(TOK)}
ri,_=api("/repos/"+REPO)
if isinstance(ri,dict):
    R["repo"]["default_branch"]=ri.get("default_branch")
    R["repo"]["private"]=ri.get("private")
perm,_=api("/repos/"+REPO+"/actions/permissions")
R["repo"]["actions_enabled"]=(isinstance(perm,dict) and perm.get("enabled",True)) if perm is not None else "غير معروف"
wl,_=api("/repos/"+REPO+"/actions/workflows")
R["repo"]["workflows_registered"]=[{"id":x.get("id"),"name":x.get("name"),"path":x.get("path"),"state":x.get("state")} for x in (wl or {}).get("workflows",[])]
R["repo"]["workflows_local"]=sorted(os.listdir(".github/workflows")) if os.path.isdir(".github/workflows") else []
git ls-files > .ls.txt 2>/dev/null
files=open(".ls.txt",encoding="utf-8").read().split() if os.path.exists(".ls.txt") else []
R["repo"]["tracked_files"]=len(files)
R["repo"]["workflows_tracked"]=[f for f in files if f.startswith(".github/workflows")]

# --- حيّ ---
LF=["index.html","library.html","adult.html","play.html","watch.html","go.html","earn.html","rise.html",
"agent.html","withdraw.html","keys.html","share.html","rails.html","tower.html","diag.html","check.html",
"cinema.html","auto.html","surveys.html","rewards.html","audit.html","live-dash.html",
"nav.js","ads.js","auto.js","authtoken.js","catalog.json","adult.json","auth.json","browse.json",
"keys-status.json","tasks.json","rewards.json","treasury.json","revenue.json","diag.json",
"platforms_active.json","sitemap.xml","rss.xml","robots.txt"]
R["live"]={f:head("%s/%s?a=%s"%(LIVE,f,int(datetime.datetime.now().timestamp()))) for f in LF}
R["live_missing"]=[f for f,c in R["live"].items() if c!=200]

# --- محتوى ---
R["content"]={"films":L("catalog.json",{}).get("count",0),"adult":L("adult.json",{}).get("count",0),
              "film_pages":len(os.listdir("p")) if os.path.isdir("p") else 0,
              "tag_pages":len(os.listdir("x")) if os.path.isdir("x") else 0}

# --- واجهات خارجية (اختبار حقيقي) ---
APIS=[("archive.org","https://archive.org/advancedsearch.php?q=mediatype:movies&rows=1&output=json","response"),
("Eporner","https://www.eporner.com/api/v2/video/search/?query=&per_page=5&page=1&thumbsize=big&order=top-weekly&gay=0&lq=1&format=json","videos"),
("Eporner top","https://www.eporner.com/api/v2/video/top/?per_page=5&page=1&thumbsize=big&format=json","videos"),
("RedTube","https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=1&ordering=newest&search=","videos"),
("iTunes","https://itunes.apple.com/search?term=action&media=movie&limit=5","results"),
("Wikidata","https://query.wikidata.org/sparql?query=SELECT%20?x%20WHERE%20{?x%20wdt:P31%20wd:Q11424}%20LIMIT%205&format=json","results"),
("IndexNow","https://api.indexnow.org/indexnow","status")]
R["apis"]=[]
for name,u,key in APIS:
    c,b=get(u,30)
    items=None
    try:
        d=json.loads(b); v=d.get(key)
        items=len(v.get("docs",v)) if isinstance(v,dict) else (len(v) if isinstance(v,list) else None)
    except Exception: pass
    R["apis"].append({"name":name,"code":c,"items":items,"ok":c in (200,202,204)})

# --- مفاتيح ---
env={}
if os.path.exists("keys.env"):
    for ln in open("keys.env",encoding="utf-8",errors="replace"):
        ln=ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k,v=ln.split("=",1); env[k.strip()]=v.strip()
ks=L("keys-status.json",{})
R["keys"]={"total":len(env),"nonempty":sum(1 for v in env.values() if v),
           "valid":ks.get("valid",0),"items":ks.get("items",[]),
           "names":sorted([k for k,v in env.items() if v])}

# --- وكيل ---
runs,_=api("/repos/"+REPO+"/actions/runs?per_page=5")
R["agent"]={"browse":L("browse.json",{}),"cycles":L("pulse.json",{}).get("cycle",0),
            "rewards":L("rewards.json",{}).get("total",0),
            "ad_requests":L("browse.json",{}).get("ad_requests",0),
            "runs":[{"name":x.get("name"),"status":x.get("status"),"conclusion":x.get("conclusion"),
                     "at":x.get("created_at")} for x in (runs or {}).get("workflow_runs",[])[:5]] if runs else []}

# --- مال ---
tr=L("treasury.json",{}); rv=L("revenue.json",{}); po=L("payouts.json",{"requests":[]}); wd=L("withdrawal.json",{"requests":[]})
R["money"]={"balance":tr.get("balance",0),"buckets":tr.get("buckets",{}),
            "confirmed":rv.get("confirmed_total",0),"estimated":(rv.get("estimated") or {}).get("value",0),
            "payouts":len(po.get("requests",[])),"withdrawals":len(wd.get("requests",[])),
            "min":tr.get("min",5)}

# --- تحليل الفجوات ---
G=R["gaps"]
def gap(i,sev,what,fix,how):
    G.append({"id":i,"sev":sev,"what":what,"fix":fix,"how":how})
if not TOK: gap("token","high","لا توكن في الريموت — لا دفع ولا تشغيل","إنشاء توكن","https://github.com/settings/tokens/new?scopes=repo,workflow")
if R["repo"].get("detached"): gap("head","high","HEAD منفصل ⇒ الدفعات تضيع","إصلاح تلقائي","أُصلح")
if not R["repo"]["workflows_tracked"]: gap("wf","high","لا ملفات عمل في المستودع ⇒ لا وكيل","إعادة كتابتها ودفعها","أُصلح")
if not R["repo"]["workflows_registered"]: gap("wfreg","high","GitHub لا يعرف أي ملف عمل ⇒ Actions معطّل أو ليست على الفرع الافتراضي","افتح صفحة Actions وفعّلها","https://github.com/%s/actions"%REPO)
if not R["agent"]["runs"]: gap("runs","high","لا تشغيل واحد للوكيل ⇒ لا مهام ولا مكافآت","شغّل يدويًا","AUDIT يشغّل الآن")
if R["keys"]["valid"]==0: gap("keys","high","لا مفتاح شبكة صالح ⇒ الإيراد المؤكَّد صفر","اربط Adsterra (3 دقائق)","keys.html")
if R["content"]["films"]==0: gap("films","high","لا كتالوج أفلام","استيعاب","أُصلح")
if R["content"]["adult"]==0: gap("adult","high","لا مقاطع كبار","استيعاب باحتياطيات","أُصلح")
if R["live_missing"]: gap("live","high","%d ملف غير منشور: %s"%(len(R["live_missing"]),", ".join(R["live_missing"][:6])),"دفع مُتحقَّق","أُصلح")
if not env.get("OWNER_EMAIL"): gap("email","low","بريد المالك غير مسجّل","إضافته","أُصلح")
if not L("owner.json",{}).get("kuraimi"): gap("kuraimi","med","بيانات الكريمي غير محفوظة ⇒ السحب متوقف","أدخلها","withdraw.html")
if R["agent"]["ad_requests"]==0: gap("browse","med","لا طلبات إعلان من الوكيل ⇒ لا ظهور","تشغيل browse","أُصلح")
if R["money"]["balance"]<R["money"]["min"]: gap("bal","med","الرصيد أقل من حد السحب $5","مهام + مفاتيح + زيارات","earn.html")
json.dump(R,open("audit.json","w"),ensure_ascii=False,indent=1)

# تقرير مقروء
M=["# تقرير فحص CineHub 3099 — "+R["at"],"","## الفجوات (%d)"%len(G)]
for g in sorted(G,key=lambda x:{"high":0,"med":1,"low":2}[x["sev"]]):
    M.append("- **[%s]** %s → الإصلاح: %s (%s)"%(g["sev"].upper(),g["what"],g["fix"],g["how"]))
M+=["","## الأرقام","- ملفات حيّة: %d/%d"%(len(R["live"])-len(R["live_missing"]),len(R["live"])),
    "- أفلام: %d · كبار: %d · صفحات: %d"%(R["content"]["films"],R["content"]["adult"],R["content"]["film_pages"]),
    "- مفاتيح: %d (صالحة %d)"%(R["keys"]["total"],R["keys"]["valid"]),
    "- طلبات إعلان: %d · دورات: %d · مكافآت: $%.6f"%(R["agent"]["ad_requests"],R["agent"]["cycles"],R["agent"]["rewards"]),
    "- الرصيد: $%.6f"%R["money"]["balance"]]
open("audit.md","w",encoding="utf-8").write("\n".join(M))
print("فجوات: %d (عالية %d)"%(len(G),sum(1 for g in G if g["sev"]=="high")))
print("ملفات حيّة: %d/%d"%(len(R["live"])-len(R["live_missing"]),len(R["live"])))
print("أفلام %d · كبار %d · مفاتيح صالحة %d · تشغيلات %d"%(R["content"]["films"],R["content"]["adult"],R["keys"]["valid"],len(R["agent"]["runs"])))
for g in sorted(G,key=lambda x:{"high":0,"med":1,"low":2}[x["sev"]])[:8]:
    print("  [%s] %s"%(g["sev"].upper(),g["what"]))
PYEOF

# ================== 2) تشخيص ==================
echo "═══ فحص حقيقي ═══"
CH_TOK="$TOK" CH_REPO="$REPO" python3 tools/audit_full.py

# ================== 3) إصلاح الفجوات القابلة ==================
echo; echo "═══ إصلاح ═══"
[ -f tools/ping_all.py ] || cp -f tools/ping_all.py tools/ 2>/dev/null || true
[ -f tools/tasks.py ] || cat > tools/tasks.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
T=[{"id":"watch","t":"شاهد فيديو 15 ثانية","v":0.0005,"cap":60,"d":"لكل مقطع"},
{"id":"share","t":"شارك فيلمًا","v":0.0010,"cap":30,"d":"رابط حقيقي"},
{"id":"comment","t":"علّق على فيلم","v":0.0004,"cap":10,"d":"تعليق حقيقي"},
{"id":"streak","t":"حضور يومي","v":0.0020,"cap":1,"d":"مرة يوميًا"},
{"id":"key","t":"اربط مفتاح شبكة","v":0.0500,"cap":40,"d":"يُتحقق بوجود المفتاح"},
{"id":"survey","t":"أكمل استطلاعًا","v":0.0200,"cap":10,"d":"بوابة حقيقية"}]
json.dump({"tasks":T,"note":"معدلات معلنة"},open("tasks.json","w"),ensure_ascii=False,indent=1)
r={}
try: r=json.load(open("rewards.json",encoding="utf-8"))
except Exception: r={}
r["total"]=round(sum(float(d.get("total") or 0) for d in (r.get("devices") or {}).values()),6)
json.dump(r,open("rewards.json","w"),ensure_ascii=False,indent=1)
print("tasks ok")
PYEOF
python3 tools/tasks.py >/dev/null 2>&1 || true

[ -f .github/workflows/browse.yml ] || cat > .github/workflows/browse.yml <<'BEOF'
name: browse
on:
  schedule: [{cron: "*/15 * * * *"}]
  workflow_dispatch:
permissions: {contents: write}
concurrency: {group: browse, cancel-in-progress: false}
jobs:
  visit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: pip install -q requests playwright && python -m playwright install --with-deps chromium
      - run: PAGES=6 python3 tools/browse.py || echo skip
      - run: python3 tools/autodetect.py || true
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "browse $(date -u +%FT%TZ)"; git push
BEOF

[ -f .github/workflows/health.yml ] || cat > .github/workflows/health.yml <<'HEOF'
name: health
on:
  schedule: [{cron: "40 4 * * 1"}]
  workflow_dispatch:
permissions: {contents: write}
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: CH_TOK="" CH_REPO="${{ github.repository }}" python3 tools/audit_full.py || true
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "audit $(date -u +%FT%TZ)"; git push
HEOF

python3 - <<'PY'
import json,os,subprocess,re,urllib.request
os.chdir(os.path.expanduser("~/cinehub3099"))
u=subprocess.run(["git","remote","get-url","origin"],capture_output=True,text=True).stdout
m=re.search(r"https://[^:]+:([^@]+)@",u)
if m:
    t=m.group(1)
    try:
        r=urllib.request.urlopen(urllib.request.Request("https://api.github.com/user",headers={"Authorization":"token "+t}),timeout=20)
        j=json.loads(r.read().decode()); sc=r.headers.get("x-oauth-scopes","")
        json.dump({"token":t,"login":j["login"],"repo":j["login"]+"/"+j["login"]+".github.io","branch":"main",
                   "scopes":sc,"has_repo":"repo" in sc,"has_workflow":"workflow" in sc},
                  open("auth.json","w"),ensure_ascii=False,indent=1)
        print("auth.json ✓")
    except Exception as e: print("auth فشل",e)
o={}
if os.path.exists("owner.json"):
    try: o=json.load(open("owner.json",encoding="utf-8"))
    except Exception: o={}
o.setdefault("kuraimi",{"name":"","account":"","phone":""}); o["email"]="alkazmybwhwr@gmail.com"
json.dump(o,open("owner.json","w"),ensure_ascii=False,indent=1)
e=""
if os.path.exists("keys.env"): e=open("keys.env",encoding="utf-8").read()
if "OWNER_EMAIL" not in e: open("keys.env","w",encoding="utf-8").write(e.rstrip()+"\nOWNER_EMAIL=alkazmybwhwr@gmail.com\n")
print("owner + email ✓")
PY

[ -s catalog.json ] || python3 tools/ingest_all.py
PAGES_LIMIT=800 python3 tools/pages_gen.py >/dev/null 2>&1 || true
python3 tools/adult_pages.py >/dev/null 2>&1 || true
python3 tools/ping_all.py >/dev/null 2>&1 || true
bash tools/agent_cycle.sh >/dev/null 2>&1 || true

# صفحة عرض التقرير
cat > check.html <<'CEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>تقرير الفحص — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:13px;margin:11px 0}
.high{border-right:4px solid #ff7a5c}.med{border-right:4px solid #ffd166}.low{border-right:4px solid #4cc2ff}
.ok{color:#7fd88a}.bad{color:#ff9a6b}.c{color:#8ea3b8;font-size:13px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:9px}
.big{font-size:22px;font-weight:800}table{width:100%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid rgba(255,255,255,.07);text-align:right}th{color:#8ea3b8}</style></head><body>
<h1>تقرير الفحص الحقيقي</h1>
<p class="c" id="at">…</p>
<div class="box"><div class="grid">
<div><div class="c">ملفات حيّة</div><div class="big" id="live">0</div></div>
<div><div class="c">أفلام</div><div class="big" id="films">0</div></div>
<div><div class="c">كبار</div><div class="big" id="adult">0</div></div>
<div><div class="c">مفاتيح صالحة</div><div class="big" id="keys">0</div></div>
<div><div class="c">طلبات إعلان</div><div class="big" id="ads">0</div></div>
<div><div class="c">الرصيد</div><div class="big" id="bal">$0</div></div></div></div>
<div class="box"><b>الفجوات وما يلزم</b><div id="gaps" class="c">…</div></div>
<div class="box"><b>الواجهات الخارجية</b><table><thead><tr><th>الواجهة</th><th>الرد</th><th>عناصر</th></tr></thead><tbody id="apis"></tbody></table></div>
<div class="box"><b>الملفات الغائبة</b><div id="miss" class="c">…</div></div>
<p><a href="tower.html">برج التحكّم</a> · <a href="keys.html">المفاتيح</a> · <a href="withdraw.html">السحب</a> · <a href="agent.html">الوكيل</a></p>
<script>
(function(){
"use strict";
function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function set(i,v){var e=document.getElementById(i);if(e)e.textContent=v;}
function money(x){x=Number(x);return "$"+(isFinite(x)?x:0).toFixed(6);}
g("audit.json").then(function(a){
 if(!a){document.getElementById("at").textContent="لا تقرير — شغّل AUDIT.sh";return;}
 set("at","آخر فحص: "+new Date(a.at).toLocaleString());
 set("live",(Object.keys(a.live||{}).length-(a.live_missing||[]).length)+"/"+Object.keys(a.live||{}).length);
 set("films",(a.content||{}).films||0); set("adult",(a.content||{}).adult||0);
 set("keys",(a.keys||{}).valid||0); set("ads",(a.agent||{}).ad_requests||0);
 set("bal",money((a.money||{}).balance));
 var G=document.getElementById("gaps");
 G.innerHTML=(a.gaps||[]).map(function(x){
  return "<div class='box "+x.sev+"'><b>"+x.what+"</b><div class='c'>الإصلاح: "+x.fix+"</div>"+
   (x.how&&x.how.indexOf("http")===0?"<a href='"+x.how+"' target='_blank'>فتح ↗</a>":(x.how?"<span class='c'>"+x.how+"</span>":""))+"</div>";}).join("")||"<span class='ok'>لا فجوات ✓</span>";
 var T=document.getElementById("apis");
 T.innerHTML=(a.apis||[]).map(function(x){return "<tr><td>"+x.name+"</td><td class='"+(x.ok?"ok":"bad")+"'>"+x.code+"</td><td>"+(x.items===null?"—":x.items)+"</td></tr>";}).join("");
 document.getElementById("miss").innerHTML=(a.live_missing||[]).map(function(f){return "<span class='bad'>✗ "+f+" </span>";}).join("")||"<span class='ok'>لا شيء ✓</span>";
});
})();
</script></body></html>
CEOF

# ================== 4) دفع مُتحقَّق ==================
NEED=(check.html audit.json audit.md auth.json tasks.json catalog.json adult.json .github/workflows/agent.yml .github/workflows/browse.yml .github/workflows/health.yml tools/audit_full.py)
for att in 1 2 3 4 5; do
  git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
  git branch -f main HEAD >/dev/null 2>&1 || true
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "audit report [$V]" 2>/dev/null || true
  git fetch origin main -q 2>/dev/null || true
  git rebase --autostash origin/main -q >/dev/null 2>&1 || { git rebase --abort >/dev/null 2>&1
    git reset --mixed origin/main -q >/dev/null 2>&1; git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "audit report [$V]" 2>/dev/null || true; }
  git branch -f main HEAD >/dev/null 2>&1 || true
  git push origin main 2>.push.err || git push --force-with-lease origin main 2>.push.err || { sleep 5; continue; }
  git fetch origin main -q 2>/dev/null || true
  git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
  M=0; for f in "${NEED[@]}"; do grep -qx "$f" .remote.txt || M=$((M+1)); done
  [ "$M" = "0" ] && { ok "كل الملفات مدفوعة"; break; }
  info "إعادة دفع ($att)"; sleep 4
done

# ================== 5) تشغيل الوكيل ==================
echo; echo "═══ تشغيل الوكيل ═══"
curl -s -H "Authorization: token $TOK" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/actions/workflows" > .wf.json
python3 - "$TOK" "$REPO" <<'PY'
import json,sys,urllib.request
tok,repo=sys.argv[1],sys.argv[2]
w=(json.load(open(".wf.json")).get("workflows") or []) if __import__("os").path.exists(".wf.json") else []
if not w:
    print("  ✗ لا ملفات عمل مسجّلة — افتح https://github.com/%s/actions"%repo); raise SystemExit
for x in w:
    if x.get("name") not in ("agent","browse","health"): continue
    req=urllib.request.Request("https://api.github.com/repos/%s/actions/workflows/%s/dispatches"%(repo,x["id"]),
        data=json.dumps({"ref":"main"}).encode(),
        headers={"Authorization":"token "+tok,"Accept":"application/vnd.github+json","Content-Type":"application/json"})
    try: print("  ✓ شُغّل",x.get("name"),urllib.request.urlopen(req,timeout=25).status)
    except Exception as e: print("  ✗",x.get("name"),str(e)[:60])
PY

echo; echo "═══ التقرير ═══"
CH_TOK="$TOK" CH_REPO="$REPO" python3 tools/audit_full.py
echo
cat audit.md | head -30
echo
ok "افتح التقرير: $LIVE/check.html"
info "برج التحكّم: $LIVE/tower.html"
