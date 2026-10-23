#!/data/data/com.termux/files/usr/bin/bash
mkdir -p "/data/data/com.termux/files/home/tmp3099"
# ═══════════════════════════════════════════════════════════════
# CineHub 3099 · restart.sh · إعادة تشغيل نظيفة ذاتية الإصلاح
#   bash restart.sh          → تشغيل واحد كامل
#   bash restart.sh --watch  → حلقة تلقائية كل 15 دقيقة
# ═══════════════════════════════════════════════════════════════
set -u
OWNER="alkazmybwhwr-dot"; REPO="alisalimax3.github.io"; BRANCH="main"
SITE="https://${OWNER}.github.io"; API="https://api.github.com"
C_G(){ printf '\033[32m%s\033[0m\n' "$1"; }; C_R(){ printf '\033[31m%s\033[0m\n' "$1"; }
C_Y(){ printf '\033[33m%s\033[0m\n' "$1"; }; C_C(){ printf '\033[36m%s\033[0m\n' "$1"; }
S(){ printf '\n\033[36m━━ %s ━━\033[0m\n' "$1"; }; OK(){ C_G "  ✓ $1"; }
NO(){ C_R "  ✗ $1"; }; WN(){ C_Y "  ! $1"; }

cd "$(dirname "$0")" 2>/dev/null || cd ~/cinehub3099 || { C_R "لا أجد cinehub3099"; exit 1; }
D="$(pwd)"

S "1/11 الأدوات والبيئة"
for t in git python3 curl tar; do command -v $t >/dev/null 2>&1 || { WN "تثبيت $t"; pkg install -y $t >/dev/null 2>&1; }; done
command -v git >/dev/null && command -v python3 >/dev/null && OK "git + python3" || { NO "فشل التثبيت"; exit 1; }
python3 -c "import urllib.request,json,re,os,time,glob" && OK "مكتبات python"

S "2/11 إصلاح المستودع (السبب الجذري السابق)"
rm -f ~/.git/index.lock "$D/.git/index.lock" 2>/dev/null
TOP="$(git rev-parse --show-toplevel 2>/dev/null || echo NONE)"
if [ "$TOP" != "$D" ]; then WN "المستودع في $TOP — إعادة بناء مستقل في $D"; rm -rf "$D/.git"; git init -q "$D"; git symbolic-ref HEAD "refs/heads/$BRANCH"; fi
git config user.email "cinehub@local"; git config user.name "CineHub"
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n__pycache__/\n*.tgz\n' > .gitignore
[ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$D" ] && OK "مستودع مستقل صحيح" || { NO "فشل"; exit 1; }

S "3/11 المصادقة (تصحيح ذاتي)"
AUTH=0
if [ -f .gh-token ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $(tr -d '\n\r ' < .gh-token)" "$API/user" 2>/dev/null)
  [ "$code" = "200" ] || { WN "التوكن غير صالح ($code)"; AUTH=1; }
else AUTH=1; fi
if [ "$AUTH" = "1" ]; then
  if [ -f auth.py ]; then C_C "  تشغيل auth.py…"; python3 auth.py || { NO "فشل الدخول"; exit 1; }
  else
    python3 - <<'PY'
import json,urllib.request,time,os
CID="Iv1.b507a08c87ecfe98"
d=json.loads(urllib.request.urlopen(urllib.request.Request("https://github.com/login/device/code",
  data=json.dumps({"client_id":CID,"scope":"repo"}).encode(),
  headers={"Content-Type":"application/json","Accept":"application/json"})).read())
print("\n  افتح https://github.com/login/device  والكود: %s\n"%d["user_code"])
while True:
    time.sleep(d.get("interval",5))
    r=json.loads(urllib.request.urlopen(urllib.request.Request("https://github.com/login/oauth/access_token",
      data=json.dumps({"client_id":CID,"device_code":d["device_code"],
      "grant_type":"urn:ietf:params:oauth:grant-type:device_code"}).encode(),
      headers={"Content-Type":"application/json","Accept":"application/json"})).read())
    if r.get("access_token"): open(".gh-token","w").write(r["access_token"]); print("  ✓ تمت المصادقة"); break
    if r.get("error") not in ("authorization_pending","slow_down"): raise SystemExit(r)
PY
  fi
fi
T="$(tr -d '\n\r ' < .gh-token)"
OK "مصادق"

S "4/11 تصحيح الإعدادات (إزالة النصوص النائبة)"
python3 - <<'PY'
import json,os,re
def bad(v): return bool(re.search(r"[\u0600-\u06FF]|TOKEN|\.\.\.|xxx|XXX|PUT-|YOUR",str(v)))
def fix(v):
    if isinstance(v,str): return "" if bad(v) else v
    if isinstance(v,dict): return {k:fix(x) for k,x in v.items()}
    if isinstance(v,list): return [fix(x) for x in v]
    return v
for f in ("ads-config.json","surveys-config.json","wallet.json","payouts.json"):
    if not os.path.exists(f): continue
    try: d=json.load(open(f,encoding="utf-8"))
    except Exception: W=""; continue
    json.dump(fix(d),open(f,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
PY
python3 - <<'PY'
import json,os,re
n=0
for f in ("ads-config.json","wallet.json","surveys-config.json"):
    if not os.path.exists(f): continue
    s=open(f,encoding="utf-8").read()
    if re.search(r'"\s*:\s*"\s*"',s): n+=1
print("  إعدادات نظيفة" if not n else "  %d ملف فيه حقول فارغة (طبيعي قبل التسجيل)"%n)
if os.path.exists("wallet.json"):
    a=json.load(open("wallet.json",encoding="utf-8")).get("address","")
    print("  ! المحفظة غير محددة — نفّذ: bash wallet.sh 0x..." if not re.match(r"^0x[0-9a-fA-F]{40}$",a) else "  ✓ المحفظة: "+a)
PY

S "5/11 ضمان الملفات الأساسية"
[ -f .nojekyll ] || : > .nojekyll
printf 'User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' "$SITE" > robots.txt
cat > manifest.json <<'JS'
{"name":"CineHub 3099","short_name":"CineHub","start_url":"/","scope":"/","display":"standalone",
"background_color":"#0a0e1a","theme_color":"#0a0e1a","lang":"ar","dir":"rtl",
"description":"CineHub 3099 — أفلام ومسلسلات + أرباح إعلانات حقيقية.",
"icons":[{"src":"/icon.svg","sizes":"any","type":"image/svg+xml","purpose":"any maskable"}]}
JS
cat > push.js <<'JS'
(function(){window.OneSignalDeferred=window.OneSignalDeferred||[];var A="PUT-ONESIGNAL-APP-ID";
if(A.indexOf("PUT")===0)return;var s=document.createElement("script");
s.src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js";s.defer=1;document.head.appendChild(s);
OneSignalDeferred.push(function(O){O.init({appId:A})});})();
JS
cat > live-earnings.js <<'JS'
(function(){var e=document.getElementById("ch-live");
if(!e){e=document.createElement("div");e.id="ch-live";
e.style.cssText="position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.6 system-ui;padding:6px 10px;border-radius:10px";
addEventListener("DOMContentLoaded",function(){document.body.appendChild(e)});}
function t(){var v=+(localStorage.getItem("ch_visits")||0),i=+(localStorage.getItem("ch_impressions")||0);
e.innerHTML="زيارات <b>"+v+"</b> · ظهور <b>"+i+"</b> · تقدير <b>$"+((i/1000)*1.2).toFixed(4)+"</b>";}
setInterval(t,2000);t();})();
JS
[ -f 404.html ] || cat > 404.html <<'H4'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/><title>404 — CineHub 3099</title>
<style>body{margin:0;background:#0a0e1a;color:#e8f6ff;font:15px system-ui,Tahoma;display:grid;place-items:center;min-height:100vh;text-align:center}
a{color:#4dd0e1;display:inline-block;margin:6px;border:1px solid #1e2a44;padding:7px 13px;border-radius:9px;text-decoration:none}h1{font-size:60px;margin:0}</style></head>
<body><div><h1>404</h1><p>الصفحة غير موجودة — لكن الموقع يعمل.</p>
<a href="/">الرئيسية</a><a href="/earn.html">الأرباح</a><a href="/withdraw.html">السحب</a>
<a href="/b/movies-2026.html">أفلام 2026</a></div></body></html>
H4
grep -q "CH-UI" index.html 2>/dev/null || WN "index.html قديم (سيُبنى من جديد بأمر fix2 إن لزم)"
OK "robots · manifest · sw · 404 · push · live"

S "6/11 إعادة تشغيل الإقلاع الداخلي (Service Worker + الإصدار)"
python3 - <<'PY'
import time,os
v="ch3099-%d"%int(time.time())
src='''const V="%s";
const CORE=["/","/index.html","/ads.js","/manifest.json"];
self.addEventListener("install",e=>{self.skipWaiting();e.waitUntil(caches.open(V).then(c=>c.addAll(CORE).catch(()=>{})))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener("fetch",e=>{const r=e.request;if(r.method!=="GET")return;
e.respondWith(caches.match(r).then(hit=>{const net=fetch(r).then(res=>{caches.open(V).then(c=>c.put(r,res.clone()));return res}).catch(()=>hit);return hit||net;}))});
'''%v
open("sw.js","w").write(src)
open("version.json","w").write('{"v":"%s","t":"%d"}'%(v,int(time.time())))
print("  نسخة جديدة: %s"%v)
PY
OK "الإقلاع الداخلي أُعيد"

S "7/11 إعادة البناء (SEO + sitemap + حقن السكربتات)"
python3 - <<'PY'
import os,re
B="https://alisalimax3.github.io"
SC=["/push.js","/ads.js","/engage.js","/live-earnings.js"]
LG=[d for d in ("en","es","fr","id","pt","tr","ar") if os.path.isdir(d)]
hl="<!--hreflang-->"+"".join('\n<link rel="alternate" hreflang="%s" href="%s/%s/">'%(l,B,l) for l in LG)
hl+='\n<link rel="alternate" hreflang="x-default" href="%s/">'%B+"\n<!--/hreflang-->"
F=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    F+=[os.path.join(r,x) for x in f if x.endswith(".html")]
n=0
for p in F:
    s=o=open(p,encoding="utf-8").read()
    s=re.sub(r"<!--hreflang-->.*?<!--/hreflang-->","",s,flags=re.S)
    if "<head>" in s: s=s.replace("<head>","<head>\n"+hl,1)
    for sc in SC:
        if os.path.basename(sc) in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace("</body>",t+"\n</body>",1) if "</body>" in s else s+"\n"+t
    if s!=o: open(p,"w",encoding="utf-8").write(s); n+=1
print("  حقن: %d ملف"%n)
PY
python3 - <<'PY'
import os,datetime
B="https://alisalimax3.github.io";U=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    for x in f:
        if x.endswith(".html"):
            p=os.path.relpath(os.path.join(r,x),".").replace("\\","/")
            U.append(B+"/" if p=="index.html" else B+"/"+p)
U=sorted(set(U));T=datetime.date.today().isoformat()
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
+"".join("  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"%(u,T) for u in U)+"</urlset>")
print("  sitemap: %d رابط"%len(U))
PY
OK "البناء تم"

S "8/11 النشر (مع إصلاح تلقائي)"
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
push(){
  git remote remove origin 2>/dev/null
  git remote add origin "https://x-access-token:${T}@github.com/${OWNER}/${REPO}.git"
  git add -A
  git rm --cached -q --ignore-unmatch .gh-token 2>/dev/null
  git diff --cached --quiet || git commit -q -m "restart $(date -u +%FT%TZ)"
  n=0; until bash deploy.sh main "auto $(date -u +%FT%TZ)"; do
    n=$((n+1)); [ $n -ge 4 ] && { NO "فشل الدفع: $(tail -1 /data/data/com.termux/files/home/tmp3099/gp.err)"; return 1; }
    WN "إعادة محاولة $n"; sleep $((n*4))
  done; return 0
}
if git ls-files | grep -q '^cinehub3099/'; then WN "مسارات مسبوقة — إعادة تهيئة"; rm -rf .git; git init -q .; git symbolic-ref HEAD "refs/heads/$BRANCH"; fi
push && OK "نُشر فعليًا" || exit 1

S "9/11 إعادة تشغيل الإقلاع السحابي (GitHub Pages)"
curl -s -X POST -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
  "$API/repos/$OWNER/$REPO/pages" -d '{"source":{"branch":"main","path":"/"}}' -o /dev/null 2>/dev/null
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $T" \
  -H "Accept: application/vnd.github+json" "$API/repos/$OWNER/$REPO/pages/builds" 2>/dev/null)
case "$code" in 201|204) OK "أُعيد بناء Pages (HTTP $code)";; *) WN "نداء rebuild رجع $code — الدفع نفسه يكفي";; esac

S "10/11 التحقق الحيّ (مع إصلاح تلقائي)"
check(){
python3 - <<'PY'
import urllib.request
B="https://alisalimax3.github.io"
L=["/","/index.html","/ads.js","/ads-config.json","/wallet.json","/sitemap.xml","/robots.txt",
   "/manifest.json","/sw.js","/404.html","/withdraw.html","/b/movies-2026.html"]
bad=0
for u in L:
    try:
        c=urllib.request.urlopen(B+u,timeout=25).status
    except Exception as e: c=getattr(e,"code","ERR")
    if c!=200: bad+=1; print("  %s  %s"%(c,u))
try: x=urllib.request.urlopen(B+"/cinehub3099/",timeout=20).status
except Exception as e: x=getattr(e,"code","ERR")
print("  /cinehub3099/ = %s  %s"%(x,"✓" if x!=200 else "✗ مسارات مسبوقة"))
import sys; sys.exit(1 if bad else 0)
PY
}
sleep 90
if check; then OK "كل الصفحات 200 — الموقع يعمل"; else
  WN "صفحات فاشلة — إصلاح تلقائي وإعادة نشر"; sleep 20; push; sleep 90
  if check; then OK "أُصلح بعد المحاولة الثانية"; else NO "لا تزال صفحات فاشلة"; fi
fi
python3 -c "
import urllib.request
b=urllib.request.urlopen('$SITE/',timeout=25).read().decode('utf-8','ignore')
print('  محتوى:', 'CineHub 3099 موجود ✓' if 'CineHub 3099' in b else '✗ العنوان مفقود', '· الحجم:', len(b),'بايت')"

S "11/11 الفهرسة والتقرير"
python3 - <<'PY'
import re,glob,json,urllib.request
B="https://alisalimax3.github.io"
k=[f[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",f)]
if k:
    U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
    d=json.dumps({"host":"alisalimax3.github.io","key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
    r=urllib.request.Request("https://api.indexnow.org/indexnow",data=d,headers={"Content-Type":"application/json; charset=utf-8"})
    try: print("  IndexNow:",urllib.request.urlopen(r,timeout=30).status,"·",len(U),"رابط")
    except Exception as e: print("  IndexNow:",e)
PY
printf '\n\033[32m══ إعادة التشغيل اكتملت · %s ══\033[0m\n' "$SITE"
printf '\033[33mالمتبقي يدويًا: bash wallet.sh 0xعنوانك  ·  bash activate.sh "//رابط-إعلان-حقيقي"\033[0m\n'
