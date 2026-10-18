#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  DOCTOR.sh — تشخيص · إصلاح ذاتي · تفعيل مفاتيح بذكاء · ربط · نشر
#  bash DOCTOR.sh            → تشخيص + إصلاح + ربط + نشر
#  bash DOCTOR.sh paste      → الصق مفاتيحك (سطر NAME=value · ثم END)
#  bash DOCTOR.sh smart      → الصق كود إعلان كاملًا وسيتعرّف عليه
#  bash DOCTOR.sh catalog    → كل المفاتيح المطلوبة وروابطها
#  bash DOCTOR.sh fix        → إصلاح فقط بلا نشر
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
MODE="${1:-run}"; LOG="logs/doctor.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
go(){ printf '\n%s▸ %s%s\n' "$B" "$1" "$N" | tee -a "$LOG"; }
kv(){ python3 - "$1" <<'PY'
import sys
try:
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if s.startswith(sys.argv[1]+"="): print(s.split("=",1)[1]); break
except Exception: pass
PY
}
clip(){ termux-clipboard-get 2>/dev/null | tr -d '\r\n'; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }

# ═══════════ 1 · تشخيص ═══════════
hd "1 · تشخيص"
DIAG=""; FIXN=0
chk(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; DIAG="$DIAG$1; "; FIXN=$((FIXN+1)); fi; }
chk "gh.py كامل"            "[ -f gh.py ] && grep -q '^def ensure_repo' gh.py"
chk "tools/auth_device.py"  "[ -f tools/auth_device.py ]"
chk "tools/mailopen.py"     "[ -f tools/mailopen.py ]"
chk "tools/vault.py"        "[ -f tools/vault.py ]"
chk "tools/revenue_sync.py" "[ -f tools/revenue_sync.py ]"
chk "hits.js (عدّاد)"       "[ -f hits.js ]"
chk ".nojekyll"             "[ -f .nojekyll ]"
chk "404.html"              "[ -f 404.html ]"
chk "sitemap.xml"           "[ -f sitemap.xml ]"
chk "robots.txt"            "[ -f robots.txt ]"
chk "app.html"              "[ -f app.html ]"
chk "index.html"            "[ -f index.html ]"
chk "workflow الوكيل"       "[ -f .github/workflows/agent.yml ]"
chk "ads.json"              "[ -f ads.json ]"
chk "gh token"              "[ -n \"$(kv GH_TOKEN)$(cat .secrets.gh_token 2>/dev/null)\" ]"
printf '  → ناقص: %d عنصرًا\n' "$FIXN" | tee -a "$LOG"
[ -n "$DIAG" ] && printf '  %s%s%s\n' "$D" "$DIAG" "$N"

# ═══════════ 2 · إصلاح ذاتي ═══════════
hd "2 · إصلاح ذاتي"
[ -f .nojekyll ] || { : > .nojekyll; ok ".nojekyll"; }
for p in '.tmp/' 'logs/' '*.log' '.secrets*' 'auth.json' 'keys.env'; do
  grep -qxF "$p" .gitignore 2>/dev/null || printf '%s\n' "$p" >> .gitignore
done
ok ".gitignore"

if [ ! -f 404.html ]; then
cat > 404.html <<'HEOF'
<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>غير موجود</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:16px/1.8 system-ui,Tahoma;display:grid;place-items:center;height:100vh;text-align:center}
a{color:#5ca9ff}b{font-size:22px}</style><div><b>الصفحة غير موجودة</b><p><a href="/">الرئيسية</a> · <a href="/app.html">التطبيق</a> · <a href="/library.html">المكتبة</a></p></div></html>
HEOF
ok "404.html"; fi

if [ ! -f hits.js ]; then
cat > hits.js <<'JEOF'
(function(){var k=(location.pathname.replace(/^\/|\/$/g,"")||"home").replace(/\//g,"__").replace(/[^\w.\-]/g,"_");
function f(u){try{fetch(u,{cache:"no-store"}).catch(function(){})}catch(e){}}
f("https://api.counterapi.dev/v1/cinehub3099/"+k+"/up");
f("https://abacus.jasoncameron.dev/hit/cinehub3099/"+k);})();
JEOF
ok "hits.js"; fi

if [ ! -f gh.py ] || ! grep -q '^def ensure_repo' gh.py; then
cat > gh.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, subprocess, urllib.request, urllib.error
def token():
    t = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not t:
        for f in (".secrets.gh_token", ".secrets/gh_token", ".gh_token", "auth.json"):
            if not os.path.exists(f): continue
            try: t = json.load(open(f)).get("token", "") if f.endswith(".json") else open(f).read()
            except Exception: t = ""
            t = (t or "").strip()
            if t: break
    return t
def api(path, method="GET", data=None, tok=None):
    tok = tok or token()
    url = path if path.startswith("http") else "https://api.github.com" + path
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": "Bearer " + tok, "Accept": "application/vnd.github+json",
        "User-Agent": "CineHub3099", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, timeout=40) as x:
            raw = (x.read().decode() or "{}").strip()
            return json.loads(raw) if raw[:1] in "{[(" else {"raw": raw}
    except urllib.error.HTTPError as e:
        try: return json.loads(e.read().decode() or "{}")
        except Exception: return {}
    except Exception: return {}
def login(t=None): return (api("/user", tok=t or token()) or {}).get("login", "")
def repo_name(u=None): return (u or login()) + ".github.io"
def ensure_repo(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    if (api("/repos/%s/%s" % (u, r), tok=t) or {}).get("full_name"): return True
    return bool((api("/user/repos", "POST",
        {"name": r, "private": False, "auto_init": True, "default_branch": "main"}, t) or {}).get("full_name"))
def enable_pages(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    api("/repos/%s/%s/pages" % (u, r), "POST", {"source": {"branch": "main", "path": "/"}}, t)
    api("/repos/%s/%s/pages" % (u, r), "PUT", {"source": {"branch": "main", "path": "/"}}, t)
    return "https://%s.github.io/" % u
def push(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    url = "https://x-access-token:%s@github.com/%s/%s.git" % (t, u, r)
    subprocess.run("git add -A", shell=True, capture_output=True)
    subprocess.run("git -c user.email=a@c.local -c user.name=Agent commit -m update", shell=True, capture_output=True)
    p = subprocess.run("git push --force %s main" % url, shell=True, capture_output=True, text=True)
    return p.returncode == 0, (p.stdout + p.stderr)
PYEOF
ok "gh.py كامل"; fi

[ -f tools/auth_device.py ] || { cat > tools/auth_device.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request, urllib.parse
T = os.environ.get("GHTMP") or os.path.expanduser("~/.cinehub-tmp"); os.makedirs(T, exist_ok=True)
CID = os.environ.get("GH_CLIENT_ID", "178c6fc778ccc68e1d6a")
def post(u, d):
    r = urllib.request.Request(u, data=urllib.parse.urlencode(d).encode(),
        headers={"Accept": "application/json", "User-Agent": "CineHub3099"})
    return json.load(urllib.request.urlopen(r, timeout=30))
d = post("https://github.com/login/device/code", {"client_id": CID, "scope": "repo workflow read:org"})
code, url = d["user_code"], d["verification_uri"]
print("\n  ┌──────────────────────────────┐"); print("  │  الرمز:  %-20s│" % code); print("  └──────────────────────────────┘")
print("  افتح: %s  والصق الرمز ثم Approve\n" % url, flush=True)
iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
while time.time() < end:
    time.sleep(iv)
    t = post("https://github.com/login/oauth/access_token",
             {"client_id": CID, "device_code": d["device_code"], "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if t.get("access_token"): open(T + "/gh_tok", "w").write(t["access_token"]); sys.exit(0)
    e = t.get("error", "")
    if e == "slow_down": iv += 5
    elif e == "authorization_pending": print("  … بانتظار الموافقة", flush=True)
    elif e in ("expired_token", "access_denied"): sys.exit(2)
sys.exit(4)
PYEOF
ok "auth_device.py"; }

[ -f .github/workflows/agent.yml ] || {
mkdir -p .github/workflows
cat > .github/workflows/agent.yml <<'YEOF'
name: agent
on:
  schedule: [{cron: "15 */6 * * *"}]
  workflow_dispatch:
permissions: {contents: write}
concurrency: {group: agent, cancel-in-progress: false}
jobs:
  cycle:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}
      - name: cycle
        env: {GH_TOKEN: "${{ secrets.GITHUB_TOKEN }}"}
        run: |
          for s in revenue_sync hits_report ping vault money dashboard; do
            [ -f "tools/$s.py" ] && python3 "tools/$s.py" || true
          done
          git config user.email a@c.local; git config user.name agent
          git add -A; git commit -m "agent cycle $(date -u +%FT%TZ)" || true
          git push || true
YEOF
ok "workflow الوكيل"; }
chmod +x tools/*.py 2>/dev/null || true

# ═══════════ 3 · كتالوج المفاتيح ═══════════
hd "3 · الكتالوج"
python3 - <<'PY' | tee -a "$LOG"
import json
NET = [
 # key, name, kind, pay, min, signup, hint, re, verify, expect
 ("AADS_UNIT","A-ADS","adult-ok","BTC تلقائي","$0","https://a-ads.com/","data-aa",r'\d{4,8}','https://a-ads.com/api/v1/banners/{v}','.'),
 ("EXOCLICK_ZONE","ExoClick","adult","Paxum/Wire","€20","https://www.exoclick.com/signup/","Zone ID",r'\d{5,9}','',''),
 ("JUICYADS_ZONE","JuicyAds","adult","Paxum/BTC","$50","https://www.juicyads.com/signup","Zone ID",r'\d{4,9}','',''),
 ("TRAFFICJUNKY_ZONE","TrafficJunky","adult","Wire","$100","https://www.trafficjunky.com/","Zone ID",r'\d{4,9}','',''),
 ("PLUGRUSH_ZONE","PlugRush","adult","PayPal/BTC","$25","https://www.plugrush.com/","Zone ID",r'\d{4,9}','',''),
 ("CLICKADU_ZONE","Clickadu","adult","PayPal/Paxum","$5","https://www.clickadu.com/","Zone ID",r'\d{3,9}','',''),
 ("HILLTOPADS_ZONE","HilltopAds","adult","PayPal","$50","https://hilltopads.net/","Zone ID",r'\d{3,9}','',''),
 ("ADMAVEN_ZONE","AdMaven","adult","PayPal","$5","https://ad-maven.com/","Zone ID",r'\d{4,9}','',''),
 ("GALAKSION_ZONE","Galaksion","adult","PayPal","$10","https://galaksion.com/","Zone ID",r'\d{3,9}','',''),
 ("MYBID_ZONE","MyBid","adult","PayPal","$25","https://mybid.io/","Zone ID",r'\d{3,9}','',''),
 ("EVADAV_ZONE","Evadav","adult","PayPal","$5","https://evadav.com/","Zone ID",r'\d{3,9}','',''),
 ("STRIPCHAT_AFF","Stripchat","adult-aff","Wire/Paxum","$50","https://affiliates.stripchat.com/","Affiliate ID",r'[A-Za-z0-9_-]{4,32}','',''),
 ("JASMIN_AFF","LiveJasmin","adult-aff","Wire","$50","https://www.livejasmin.com/en/affiliate","Affiliate ID",r'[A-Za-z0-9_-]{4,32}','',''),
 ("BONGA_AFF","BongaCams","adult-aff","Wire","$50","https://bongacams.com/affiliate","Affiliate ID",r'[A-Za-z0-9_-]{4,32}','',''),
 ("ADSTERRA_API_KEY","Adsterra","general","USDT/PayPal","$5","https://publishers.adsterra.com/signup","API Key",r'[A-Za-z0-9_-]{20,48}','https://api3.adsterra.com/api/v1/publisher/balance',''),
 ("MONETAG_MULTITAG","Monetag","general","PayPal/Skrill","$5","https://monetag.com/","Multitag ID",r'\d{5,9}','',''),
 ("PROPELLER_ZONE","PropellerAds","general","PayPal/Paxum","$5","https://publishers.propellerads.com/","Zone ID",r'\d{4,9}','',''),
 ("POPADS_SITE_ID","PopAds","general","PayPal/BTC","$5","https://www.popads.net/users/signup","Site ID",r'\d{4,9}','',''),
 ("ADCASH_ZONE","Adcash","general","PayPal/Wire","$5","https://adcash.com/","Zone ID",r'\d{4,9}','',''),
 ("ADSENSE_CLIENT","AdSense","general","Wire/Payoneer","$100","https://adsense.google.com","ca-pub-...",r'ca-pub-\d{10,20}','',''),
 ("CPAGRIP_SMARTLINK","CPAGrip","cpa","PayPal/Payoneer","$50","https://www.cpagrip.com/","Smartlink",r'[A-Za-z0-9_./:-]{6,80}','',''),
 ("OGADS_SMARTLINK","OGAds","cpa","PayPal","$20","https://ogads.com/","Smartlink",r'[A-Za-z0-9_./:-]{6,80}','',''),
 ("LINKVERTISE_UID","Linkvertise","short","PayPal","$5","https://publisher.linkvertise.com/","User ID",r'\d{4,9}','',''),
 ("TMDB_KEY","TMDB","film","-","-","https://www.themoviedb.org/signup","API Key v3",r'[0-9a-fA-F]{32}','https://api.themoviedb.org/3/configuration?api_key={v}','images'),
 ("OMDB_API_KEY","OMDb","film","-","-","https://www.omdbapi.com/apikey.aspx","8 أحرف",r'[A-Za-z0-9]{6,12}','https://www.omdbapi.com/?apikey={v}&t=Inception','True'),
 ("TVMAZE_KEY","TVmaze","series","-","-","https://www.tvmaze.com/api","-",r'[A-Za-z0-9]{4,32}','',''),
 ("WATCHMODE_KEY","Watchmode","series","-","-","https://api.watchmode.com/","API Key",r'[A-Za-z0-9]{20,40}','',''),
 ("FANART_API_KEY","Fanart.tv","film","-","-","https://fanart.tv/get-an-api-key/","API Key",r'[A-Za-z0-9]{16,40}','',''),
 ("TRAKT_CLIENT_ID","Trakt","film","-","-","https://trakt.tv/oauth/applications","Client ID",r'[A-Za-z0-9]{20,64}','',''),
 ("USDT_TRC20","محفظة USDT","pay","-","-","https://www.binance.com","عنوان TRC20",r'T[1-9A-HJ-NP-Za-km-z]{33}','',''),
]
json.dump({"updated": __import__("time").strftime("%F %H:%M"),
  "items":[{"key":a,"name":b,"kind":c,"pay":d,"min":e,"url":f,"hint":g,"re":h,"vurl":i,"expect":j}
           for a,b,c,d,e,f,g,h,i,j in NET]},
  open("keys.catalog.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)
K = {"adult":"إباحي","adult-ok":"إباحي/عام","adult-aff":"إباحي CPA","general":"عام","cpa":"CPA",
     "short":"اختصار روابط","film":"أفلام","series":"مسلسلات","pay":"دفع"}
cur = {}
try:
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); cur[k.strip()] = v.strip()
except Exception: pass
grp = {}
for x in NET: grp.setdefault(x[2], []).append(x)
for k, arr in grp.items():
    print("\n  ── %s (%d) ──" % (K.get(k, k), len(arr)))
    for x in arr:
        m = "✓" if cur.get(x[0]) else "·"
        print("   %s %-20s %-16s %-12s حد %-6s %s" % (m, x[0], x[1], x[3], x[4], x[5]))
print("\n  مضبوط: %d من %d" % (sum(1 for x in NET if cur.get(x[0])), len(NET)))
PY

[ "$MODE" = "catalog" ] && { echo; exit 0; }
[ "$MODE" = "fix" ] && { echo; ok "انتهى الإصلاح"; exit 0; }

# ═══════════ 4 · استقبال المفاتيح ═══════════
if [ "$MODE" = "paste" ]; then
hd "4 · الصق مفاتيحك"
printf '  الصق أسطرًا بصيغة NAME=value ثم اكتب END وحدها في سطر.\n'
printf '  %sمثال: AADS_UNIT=1234567%s\n\n' "$D" "$N"
PASTE=""
while IFS= read -r l </dev/tty; do [ "$l" = "END" ] && break; PASTE="$PASTE$l"$'\n'; done
python3 - "$PASTE" <<'PY' | tee -a "$LOG"
import sys, os, json, re, time
CAT = {x["key"]: x for x in json.load(open("keys.catalog.json", encoding="utf-8"))["items"]}
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
okn = 0
for line in sys.argv[1].splitlines():
    line = line.strip()
    if not line or "=" not in line: continue
    k, v = line.split("=", 1); k, v = k.strip(), v.strip()
    if k not in CAT: print("  ! مفتاح غير معروف: %s" % k); continue
    if v and not re.match(CAT[k]["re"], v): print("  ✗ %s شكل خاطئ: %s" % (k, v[:30])); continue
    E[k] = v; okn += 1; print("  ✓ %s" % k)
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
print("  مضبوط الآن: %d مفتاح" % len(E))
PY
fi

if [ "$MODE" = "smart" ]; then
hd "4 · الصق كود إعلان — سأتعرّف عليه"
printf '  انسخ كود الإعلان من أي موقع والصقه هنا ثم END.\n\n'
PASTE=""
while IFS= read -r l </dev/tty; do [ "$l" = "END" ] && break; PASTE="$PASTE$l"$'\n'; done
python3 - "$PASTE" <<'PY' | tee -a "$LOG"
import sys, os, re, json
SIG = [("a-ads.com","AADS_UNIT"),("exoclick","EXOCLICK_ZONE"),("juicyads","JUICYADS_ZONE"),
       ("jads.js","JUICYADS_ZONE"),("monetag","MONETAG_MULTITAG"),("adsterra","ADSTERRA_API_KEY"),
       ("hilltopads","HILLTOPADS_ZONE"),("popads","POPADS_SITE_ID"),("propellerads","PROPELLER_ZONE"),
       ("clickadu","CLICKADU_ZONE"),("plugrush","PLUGRUSH_ZONE"),("adcash","ADCASH_ZONE"),
       ("ad-maven","ADMAVEN_ZONE"),("galaksion","GALAKSION_ZONE"),("evadav","EVADAV_ZONE"),
       ("mybid","MYBID_ZONE"),("trafficjunky","TRAFFICJUNKY_ZONE"),("stripchat","STRIPCHAT_AFF"),
       ("bongacams","BONGA_AFF"),("livejasmin","JASMIN_AFF"),("cpagrip","CPAGRIP_SMARTLINK"),
       ("ogads","OGADS_SMARTLINK"),("linkvertise","LINKVERTISE_UID"),("ca-pub-","ADSENSE_CLIENT"),
       ("googlesyndication","ADSENSE_CLIENT"),("themoviedb","TMDB_KEY"),("omdbapi","OMDB_API_KEY")]
CAT = {x["key"]: x for x in json.load(open("keys.catalog.json", encoding="utf-8"))["items"]}
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
blob = sys.argv[1]; low = blob.lower(); hit = 0
for frag, key in SIG:
    if frag not in low: continue
    rex = CAT[key]["re"]
    for tok in re.split(r'[^A-Za-z0-9._~\-]+', blob):
        if re.match("^%s$" % rex, tok or ""):
            E[key] = tok; print("  ✓ تعرّفت: %s ← %s" % (key, tok)); hit += 1; break
    if hit: break
if not hit: print("  ! لم أتعرّف — استخدم: bash DOCTOR.sh paste")
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
PY
fi

# ═══════════ 5 · ربط · بناء · نشر ═══════════
hd "5 · ربط وبناء ونشر"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
try: a = json.load(open("ads.json", encoding="utf-8"))
except Exception: a = {}
try: CAT = json.load(open("keys.catalog.json", encoding="utf-8"))["items"]
except Exception: CAT = []
nets = {n.get("k"): n for n in (a.get("networks") or []) if n.get("k")}
for x in CAT:
    if x["key"] in nets: continue
    if x["kind"] in ("film","series","pay"): continue
    nets[x["key"]] = {"n": x["name"], "k": x["key"], "pay": x["pay"], "kind": x["kind"], "min": x["min"]}
on = 0
for k, n in nets.items():
    v = E.get(k) or ""
    n["id"] = v; n["enabled"] = bool(v); on += bool(v)
a["networks"] = list(nets.values())
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ شبكات: %d مفعّلة من %d" % (on, len(nets)))
for k, n in sorted(nets.items()):
    print("    %s %-20s %s" % ("✓" if n["enabled"] else "·", n["n"], n["pay"]))
PY

for f in ads gen_static money vault dashboard ping revenue_sync; do
  [ -f "tools/$f.py" ] && { printf '  · %s\n' "$f"; python3 "tools/$f.py" >/dev/null 2>&1 || true; }
done

T="$(cat .secrets.gh_token 2>/dev/null || python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
if [ -n "$U" ]; then
  R="$U.github.io"; SITE="https://$U.github.io"
  python3 -c "import gh;gh.ensure_repo();gh.enable_pages()" >/dev/null 2>&1 || true
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
  git config pull.rebase true
  git add -A
  git -c user.email=a@c.local -c user.name=Agent commit -m "doctor $(date +%F_%H%M)" >/dev/null 2>&1 || true
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
  P=0
  for i in 1 2 3 4; do
    case "$i" in
      1) timeout 1800 git push origin main 2>"$GHTMP/e" && P=1 ;;
      2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
      3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
      4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
         git -c user.email=a@c.local -c user.name=Agent commit -m doctor >/dev/null 2>&1
         git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    esac
    [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
  done
  [ "$P" = 1 ] || bad "الدفع فشل"
else bad "لا مصادقة — bash ONE2.sh"; fi

# ═══════════ 6 · تحقق ═══════════
hd "6 · تحقق"
if [ -n "${SITE:-}" ]; then
  for f in "" app.html index.html library.html money.html wallet.html verify.txt; do
    c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 10; done
    [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
  done
  printf '\n  الموقع: %s · الخزينة: %s/wallet.html\n  السجل: %s\n' "$SITE" "$SITE" "$LOG" | tee -a "$LOG"
fi
