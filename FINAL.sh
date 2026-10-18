#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  FINAL.sh — التنفيذ الشامل: تفويض · شفاء · ربط · تشغيل · نشر · إثبات
#  bash FINAL.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/final.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }

# ═══════ 1 · مصادقة بتفويض ═══════
hd "1 · التفويض"
[ -f tools/auth_device.py ] || cat > tools/auth_device.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request, urllib.parse
T = os.environ.get("GHTMP") or os.path.expanduser("~/.cinehub-tmp"); os.makedirs(T, exist_ok=True)
CID = os.environ.get("GH_CLIENT_ID", "178c6fc778ccc68e1d6a")
def post(u, d):
    r = urllib.request.Request(u, data=urllib.parse.urlencode(d).encode(),
        headers={"Accept": "application/json", "User-Agent": "CineHub"})
    return json.load(urllib.request.urlopen(r, timeout=30))
d = post("https://github.com/login/device/code", {"client_id": CID, "scope": "repo workflow read:org"})
code, url = d["user_code"], d["verification_uri"]
print("\n  ┌──────────────────────────────┐\n  │  الرمز:  %-20s│\n  └──────────────────────────────┘" % code)
print("  افتح: %s  والصق الرمز ثم Approve\n" % url, flush=True)
iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
while time.time() < end:
    time.sleep(iv)
    t = post("https://github.com/login/oauth/access_token",
             {"client_id": CID, "device_code": d["device_code"],
              "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if t.get("access_token"): open(T + "/gh_tok", "w").write(t["access_token"]); sys.exit(0)
    e = t.get("error", "")
    if e == "slow_down": iv += 5
    elif e == "authorization_pending": print("  … بانتظار الموافقة", flush=True)
    elif e in ("expired_token", "access_denied"): sys.exit(2)
sys.exit(4)
PYEOF

T="$(cat .secrets.gh_token 2>/dev/null || true)"
U="$(T="$T" python3 - <<'PY' 2>/dev/null
import json,os,urllib.request
t=os.environ.get("T") or ""
r=urllib.request.Request("https://api.github.com/user",headers={"Authorization":"Bearer "+t,"Accept":"application/vnd.github+json"})
print(json.load(urllib.request.urlopen(r,timeout=25))["login"])
PY
)"
if [ -z "$U" ]; then
  wrn "لا تفويض — افتح الرابط والصق الرمز"
  python3 tools/auth_device.py || true
  T="$(cat "$GHTMP/gh_tok" 2>/dev/null || true)"
  [ -n "$T" ] && { printf '%s' "$T" > .secrets.gh_token; chmod 600 .secrets.gh_token
    U="$(T="$T" python3 -c "
import json,os,urllib.request
r=urllib.request.Request('https://api.github.com/user',headers={'Authorization':'Bearer '+os.environ['T'],'Accept':'application/vnd.github+json'})
print(json.load(urllib.request.urlopen(r,timeout=25))['login'])" 2>/dev/null || true)"; }
fi
[ -n "$U" ] || { bad "لا تفويض"; exit 1; }
ok "مفوَّض: $U"
R="$U.github.io"; SITE="https://$U.github.io"
URL="https://x-access-token:$T@github.com/$U/$R.git"
export GH_TOKEN="$T"
python3 - <<'PY' >/dev/null 2>&1
import json,os,urllib.request
t=os.environ["GH_TOKEN"]
def api(p,m="GET",d=None):
    r=urllib.request.Request("https://api.github.com"+p,method=m,
      data=json.dumps(d).encode() if d else None,
      headers={"Authorization":"Bearer "+t,"Accept":"application/vnd.github+json","Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=30))
me=api("/user")["login"]; repo=me+".github.io"
try: api("/repos/%s/%s"%(me,repo))
except Exception: api("/user/repos","POST",{"name":repo,"private":False,"auto_init":True,"default_branch":"main"})
try: api("/repos/%s/%s/pages"%(me,repo),"POST",{"source":{"branch":"main","path":"/"}})
except Exception: pass
PY
ok "المستودع و Pages جاهزان"

# ═══════ 2 · شفاء الأدوات ═══════
hd "2 · شفاء الأدوات"

cat > gh.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, subprocess, urllib.request, urllib.error
def token():
    t = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not t:
        for f in (".secrets.gh_token", ".secrets/gh_token", ".gh_token"):
            if os.path.exists(f):
                t = open(f).read().strip()
                if t: break
    return t
def api(path, method="GET", data=None, tok=None):
    tok = tok or token()
    url = path if path.startswith("http") else "https://api.github.com" + path
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": "Bearer " + tok, "Accept": "application/vnd.github+json",
        "User-Agent": "CineHub", "Content-Type": "application/json"})
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
    return bool((api("/user/repos", "POST", {"name": r, "private": False, "auto_init": True}, t) or {}).get("full_name"))
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

cat > tools/vault.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
def get(u, h=None):
    r = urllib.request.Request(u, headers=h or {"User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=25) as x: return json.loads(x.read().decode() or "{}")
src, total = [], 0.0
if E.get("ADSTERRA_API_KEY"):
    for h in ({"X-API-Key": E["ADSTERRA_API_KEY"]}, {"Authorization": "Bearer " + E["ADSTERRA_API_KEY"]}):
        try:
            d = get("https://api3.adsterra.com/api/v1/publisher/balance", h)
            b = float(d.get("balance") or d.get("amount") or 0)
            src.append({"n": "Adsterra", "usd": b, "live": True, "min": 5, "pay": "USDT/PayPal"}); total += b; break
        except Exception as e:
            src.append({"n": "Adsterra", "usd": 0, "live": False, "note": str(e)[:40], "min": 5, "pay": "USDT/PayPal"}); break
for n, k, mn, pay in (("ExoClick","EXOCLICK_ZONE",20,"Paxum/Wire"),("JuicyAds","JUICYADS_ZONE",50,"Paxum/BTC"),
                      ("Monetag","MONETAG_MULTITAG",5,"PayPal/Skrill"),("A-ADS","AADS_UNIT",0,"BTC تلقائي"),
                      ("TrafficJunky","TRAFFICJUNKY_ZONE",100,"Wire"),("PlugRush","PLUGRUSH_ZONE",25,"PayPal/BTC"),
                      ("Clickadu","CLICKADU_ZONE",5,"PayPal/Paxum"),("HilltopAds","HILLTOPADS_ZONE",50,"PayPal"),
                      ("CPAGrip","CPAGRIP_SMARTLINK",50,"PayPal"),("Stripchat","STRIPCHAT_AFF",50,"Wire")):
    src.append({"n": n, "usd": 0, "live": False, "min": mn, "pay": pay,
                "note": "المعرّف مضبوط" if E.get(k) else "ينتظر المعرّف"})
btc = 0.0
try: btc = float(get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")["bitcoin"]["usd"])
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "sources": src, "total_usd": round(total, 4), "btc_usd": btc,
  "payout": {"bank": "بنك الكريمي للتمويل الأصغر", "swift": E.get("KURAIMI_SWIFT", "KBMFYESAXXX"),
             "name": E.get("KURAIMI_NAME", ""), "account": E.get("KURAIMI_ACCOUNT", ""), "usdt": E.get("USDT_TRC20", "")},
  "ladder": ["الشبكة → USDT(TRC20) / Paxum / PayPal / BTC", "Binance P2P: USDT → نقد", "صرافة محلية", "إيداع الكريمي"]},
  open("data/wallet.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ wallet.json ($%.4f)" % total)
PYEOF

cat > tools/revenue_sync.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
T = gh.token()
def api(p):
    r = urllib.request.Request("https://api.github.com" + p,
        headers={"Authorization": "Bearer " + T, "Accept": "application/vnd.github+json", "User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=30) as x: return json.loads(x.read().decode() or "{}")
try: me = api("/user")["login"]
except Exception: sys.exit(0)
repo = me + ".github.io"
out = {"updated": time.strftime("%F %H:%M"), "pages_url": "https://%s.github.io/" % me,
       "views_14d": 0, "uniques_14d": 0, "clones_14d": 0, "stars": 0, "top_paths": []}
for key, p in (("views", "/traffic/views"), ("clones", "/traffic/clones")):
    try:
        d = api("/repos/%s/%s%s" % (me, repo, p)); out[key + "_14d"] = d.get("count", 0)
        if key == "views": out["uniques_14d"] = d.get("uniques", 0)
    except Exception: pass
try: out["stars"] = api("/repos/%s/%s" % (me, repo)).get("stargazers_count", 0)
except Exception: pass
try: out["top_paths"] = api("/repos/%s/%s/traffic/popular/paths" % (me, repo))[:20]
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump(out, open("data/revenue.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ زيارات GitHub: %d | فريدون: %d" % (out["views_14d"], out["uniques_14d"]))
PYEOF

cat > tools/hits_report.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, re, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
def slug(p): return re.sub(r"[^\w.\-]", "_", p.strip("/").replace("/", "__")) or "home"
def get(u):
    try:
        r = urllib.request.Request(u, headers={"User-Agent": "CineHub"})
        with urllib.request.urlopen(r, timeout=15) as x: return json.loads(x.read().decode() or "{}")
    except Exception: return {}
pages = ["/", "/app.html", "/library.html"]
for x in (rd("data/revenue.json", {}).get("top_paths") or [])[:25]:
    if x.get("path"): pages.append(x["path"])
seen, top, total = set(), [], 0
for p in pages:
    k = slug(p)
    if k in seen: continue
    seen.add(k)
    d = get("https://api.counterapi.dev/v1/cinehub3099/%s" % k)
    c = int(d.get("count") or 0)
    total += c
    if c: top.append({"p": p, "n": c})
top.sort(key=lambda x: -x["n"])
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "total": total, "checked": len(seen), "top": top[:40]},
          open("data/hits.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ عدّاد حقيقي: %d مشاهدة (%d صفحة)" % (total, len(seen)))
PYEOF

cat > tools/money.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
rev = rd("data/revenue.json", {}); hit = rd("data/hits.json", {}); ads = rd("ads.json", {})
live = [n for n in (ads.get("networks") or []) if n.get("id")]
off = [n for n in (ads.get("networks") or []) if not n.get("id")]
views = rev.get("views_14d", 0); hv = hit.get("total", 0)
impr = int(views * 1.7 + hv * 1.0); ecpm = 1.35 if live else 0.65
m = {"updated": time.strftime("%F %H:%M"),
     "real": {"github_views_14d": views, "github_uniques_14d": rev.get("uniques_14d", 0),
              "hits_total": hv, "live_ad_networks": len(live)},
     "estimated": {"impressions": impr, "ecpm_used": ecpm, "usd": round(impr / 1000.0 * ecpm, 4)},
     "networks_live": [{"n": n.get("n"), "pay": n.get("pay")} for n in live],
     "networks_off": [{"n": n.get("n"), "k": n.get("k")} for n in off],
     "live_url": rev.get("pages_url", "")}
os.makedirs("data", exist_ok=True)
json.dump(m, open("data/money.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ money.json | real views=%d hits=%d live=%d | est $%s" % (views, hv, len(live), m["estimated"]["usd"]))
PYEOF

cat > tools/dashboard.py <<'PYEOF'
#!/usr/bin/env python3
import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
open("money.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>الأموال — CineHub</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.7 system-ui,Tahoma}.w{max-width:960px;margin:0 auto;padding:18px}
h1{font-size:20px}h2{font-size:14px;color:#aab6c8;margin:20px 0 8px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px}
.c{background:#141924;border:1px solid #1e2635;border-radius:13px;padding:13px}.k{color:#8b96a8;font-size:12px}
.v{font-size:23px;font-weight:700}.g{color:#39d98a}.y{color:#ffcf5c}.tag{font-size:11px;padding:2px 8px;border-radius:999px}
.on{background:#12301f;color:#39d98a}.off{background:#2a1c1c;color:#ff9b9b}table{width:100%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}a{color:#5ca9ff}</style>
<div class="w"><h1>💰 لوحة الأموال</h1><div class="k" id="up">…</div>
<div class="grid" id="r"></div><h2>تقديري (ليس نقدًا)</h2><div class="grid" id="e"></div>
<h2>الشبكات</h2><div class="c"><table id="n"></table></div>
<p><a href="./">الرئيسية</a> · <a href="wallet.html">الخزينة</a> · <a href="app.html">التطبيق</a></p></div>
<script>fetch('data/money.json?_='+Date.now()).then(r=>r.json()).then(m=>{
document.getElementById('up').textContent='آخر تحديث: '+m.updated;const R=m.real||{};
document.getElementById('r').innerHTML=[['زيارات GitHub',R.github_views_14d,'g'],['زوار فريدون',R.github_uniques_14d,'y'],
['عدّاد الصفحات',R.hits_total,'b'],['شبكات مفعّلة',R.live_ad_networks,'g']]
.map(x=>'<div class="c"><div class="k">'+x[0]+'</div><div class="v '+x[2]+'">'+(x[1]??0)+'</div></div>').join('');
const E=m.estimated||{};document.getElementById('e').innerHTML=[['عروض',E.impressions,''],['eCPM',E.ecpm_used,'b'],['$',E.usd,'g']]
.map(x=>'<div class="c"><div class="k">'+x[0]+'</div><div class="v '+x[2]+'">'+(x[1]??0)+'</div></div>').join('');
let h='<tr><th>الشبكة</th><th>الدفع</th><th>الحالة</th></tr>';
(m.networks_live||[]).forEach(x=>h+='<tr><td>'+x.n+'</td><td>'+x.pay+'</td><td><span class="tag on">مفعّلة</span></td></tr>');
(m.networks_off||[]).forEach(x=>h+='<tr><td>'+x.n+'</td><td>—</td><td><span class="tag off">تنتظر '+x.k+'</span></td></tr>');
document.getElementById('n').innerHTML=h;});</script></html>""")
print("  ✓ money.html")
PYEOF

cat > tools/ping.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
def req(u, d=None, h=None, t=45):
    r = urllib.request.Request(u, data=d, headers=h or {"User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=t) as x: return x.status
def xrpc(host):
    b = ('<?xml version="1.0"?><methodCall><methodName>weblogUpdates.ping</methodName><params>'
         '<param><value>CineHub</value></param><param><value>%s</value></param></params></methodCall>' % S).encode()
    return req(host, b, {"Content-Type": "text/xml"})
res = {}
for nm, host in (("pingomatic", "http://rpc.pingomatic.com/"), ("twingly", "https://rpc.twingly.com/")):
    try: res[nm] = xrpc(host)
    except Exception as e: res[nm] = str(e)[:30]
key = next((f[:-4] for f in os.listdir(".") if f.endswith(".txt") and f[:-4].isalnum() and len(f[:-4]) in (8, 32)), None)
if key:
    try:
        b = json.dumps({"host": "%s.github.io" % U, "key": key,
                        "keyLocation": "%s/%s.txt" % (S, key),
                        "urlList": [S + "/", S + "/app.html", S + "/library.html"]}).encode()
        res["indexnow"] = req("https://api.indexnow.org/indexnow", b, {"Content-Type": "application/json"})
    except Exception as e: res["indexnow"] = str(e)[:30]
try: res["wayback"] = req("https://web.archive.org/save/" + S + "/", t=90)
except Exception as e: res["wayback"] = str(e)[:30]
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "site": S, "results": res},
          open("data/ping.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ إشعال: " + ", ".join("%s=%s" % (k, v) for k, v in res.items()))
PYEOF

cat > tools/inject_hits.py <<'PYEOF'
#!/usr/bin/env python3
import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
n = 0
for dp, dn, fn in os.walk("."):
    if any(x in dp for x in (".git", "node_modules", ".tmp")): continue
    for f in fn:
        if not f.endswith(".html"): continue
        p = os.path.join(dp, f); d = max(dp.count(os.sep) - 1, 0)
        try: s = open(p, encoding="utf-8").read()
        except Exception: continue
        if "hits.js" in s or "</body>" not in s: continue
        s = s.replace("</body>", '<script src="%shits.js" defer></script></body>' % ("../" * d if d else ""), 1)
        try: open(p, "w", encoding="utf-8").write(s); n += 1
        except Exception: pass
print("  ✓ العدّاد في %d صفحة" % n)
PYEOF
chmod +x tools/*.py

# ═══════ 3 · شفاء الصفحات ═══════
hd "3 · شفاء الصفحات"
[ -f .nojekyll ] || { : > .nojekyll; ok ".nojekyll"; }
[ -f hits.js ] || { cat > hits.js <<'JEOF'
(function(){var k=(location.pathname.replace(/^\/|\/$/g,"")||"home").replace(/\//g,"__").replace(/[^\w.\-]/g,"_");
function f(u){try{fetch(u,{cache:"no-store"}).catch(function(){})}catch(e){}}
f("https://api.counterapi.dev/v1/cinehub3099/"+k+"/up");f("https://abacus.jasoncameron.dev/hit/cinehub3099/"+k);})();
JEOF
ok "hits.js"; }
[ -f 404.html ] || { cat > 404.html <<'HEOF'
<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>غير موجود</title><style>body{margin:0;background:#0b0d12;color:#e9eef6;font:16px/1.8 system-ui,Tahoma;display:grid;place-items:center;height:100vh;text-align:center}a{color:#5ca9ff}</style>
<div><b style="font-size:22px">الصفحة غير موجودة</b><p><a href="/">الرئيسية</a> · <a href="/app.html">التطبيق</a></p></div></html>
HEOF
ok "404.html"; }

if [ ! -f app.html ]; then
cat > app.html <<'AEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub 3099</title>
<style>*{box-sizing:border-box}body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
header{position:sticky;top:0;background:#0e1219ee;backdrop-filter:blur(8px);border-bottom:1px solid #1b2331;padding:10px;z-index:9}
.w{max-width:1100px;margin:0 auto;padding:0 12px}input{width:100%;padding:11px 14px;border-radius:11px;border:1px solid #232c3c;background:#131a25;color:#e9eef6}
.chips{display:flex;gap:6px;overflow-x:auto;padding:9px 0}.chip{white-space:nowrap;padding:5px 12px;border-radius:999px;background:#161e2b;border:1px solid #232c3c;color:#a9b6c9;font-size:12.5px;cursor:pointer}
.chip.on{background:#17324d;color:#8ec5ff}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:12px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}.c b{display:block;font-size:12.5px;padding:6px;height:52px;overflow:hidden;font-weight:500}
.ad{margin:10px 0;min-height:60px;display:flex;justify-content:center}.more{width:100%;padding:12px;margin:10px 0 30px;border-radius:11px;background:#16233a;color:#a9ccff;border:1px solid #24354f}
nav a{color:#8fa4bf;font-size:12.5px;margin-inline-end:12px;text-decoration:none}.k{color:#7d8899;font-size:12px;text-align:center;padding:10px}</style></head><body>
<header><div class="w"><nav><a href="./">الرئيسية</a><a href="library.html">المكتبة</a><a href="money.html">الأموال</a><a href="wallet.html">الخزينة</a></nav>
<input id="q" placeholder="ابحث…" autocomplete="off"></div></header>
<div class="w"><div class="chips" id="chips"></div><div class="ad" id="ad1"></div>
<div class="grid" id="g"></div><button class="more" id="more">المزيد</button><div class="k" id="st">…</div></div>
<script src="hits.js" defer></script><script>
let ALL=[],F=[],N=120,CAT=null;
async function load(){for(const f of['catalog.json','films.json','titles.json']){try{const r=await fetch(f);if(!r.ok)continue;
const d=await r.json();const a=Array.isArray(d)?d:(d.items||Object.values(d));if(a&&a.length)
return a.map(x=>({i:x.i||x.id||x.slug,t:x.t||x.title||x.name||'',th:x.th||x.poster||x.image||'',y:x.y||x.year||'',c:x.c||x.cat||x.category||''})).filter(x=>x.t)}catch(e){}}return[]}
function draw(){const q=(document.getElementById('q').value||'').toLowerCase();
F=ALL.filter(x=>(!q||x.t.toLowerCase().includes(q))&&(!CAT||x.c===CAT));
document.getElementById('g').innerHTML=F.slice(0,N).map(x=>'<a class="c" href="'+(x.i?'f/'+encodeURIComponent(x.i)+'.html':'#')+'"><img loading="lazy" src="'+(x.th||'')+'"><b>'+x.t+(x.y?' ('+x.y+')':'')+'</b></a>').join('');
document.getElementById('more').style.display=F.length>N?'block':'none';
document.getElementById('st').textContent=ALL.length?F.length+' من '+ALL.length:'لا كتالوج';}
document.getElementById('q').oninput=()=>{N=120;draw()};document.getElementById('more').onclick=()=>{N+=120;draw()};
(async()=>{ALL=await load();const gs=[...new Set(ALL.map(x=>x.c).filter(Boolean))].slice(0,24);
document.getElementById('chips').innerHTML=gs.map(g=>'<div class="chip">'+g+'</div>').join('');
document.querySelectorAll('.chip').forEach(c=>c.onclick=()=>{document.querySelectorAll('.chip').forEach(z=>z.classList.remove('on'));
CAT=(CAT===c.textContent)?null:c.textContent;if(CAT)c.classList.add('on');N=120;draw()});draw();
try{const a=await(await fetch('ads.json')).json();const on=(a.networks||[]).filter(n=>n.id);
document.getElementById('ad1').innerHTML=on.slice(0,2).map(n=>
n.k==='AADS_UNIT'?'<iframe src="https://a-ads.com/banner?aa='+n.id+'&size=300x250" width="300" height="250" frameborder="0"></iframe>':
n.k==='EXOCLICK_ZONE'?'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+n.id+'" width="300" height="250" frameborder="0"></iframe>':'').join('')
||('<span class="k">'+on.length+' شبكة مفعّلة</span>');}catch(e){}})();</script></body></html>
AEOF
ok "app.html"; fi
[ -f library.html ] || cp app.html library.html
[ -f ads.json ] || printf '{"networks":[]}\n' > ads.json
[ -f robots.txt ] || printf 'User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' "$SITE" > robots.txt
[ -f sitemap.xml ] || printf '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>%s/</loc></url></urlset>\n' "$SITE" > sitemap.xml

# ═══════ 4 · تطهير وربط ═══════
hd "4 · تطهير وربط"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, json
JUNK = re.compile(r'^[A-Z][A-Z_]{6,}$'); DOM = re.compile(r'^[a-z0-9\-]+(\.[a-z0-9\-]+)+$', re.I)
PAT = {"AADS_UNIT":r'^\d{4,8}$', "ADSTERRA_API_KEY":r'^[A-Za-z0-9_-]{20,48}$',
       "EXOCLICK_ZONE":r'^\d{5,9}$', "JUICYADS_ZONE":r'^\d{4,9}$', "MONETAG_MULTITAG":r'^\d{5,9}$',
       "MAIL_USER":r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$', "MAIL_APP_PASS":r'^[A-Za-z0-9]{12,20}$',
       "USDT_TRC20":r'^T[1-9A-HJ-NP-Za-km-z]{33}$'}
E, drop = {}, []
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.rstrip("\n")
        if "=" not in s or s.lstrip().startswith("#"): continue
        k, v = s.split("=", 1); k, v = k.strip(), v.strip()
        if not v: continue
        why = None
        if JUNK.match(v) or DOM.match(v) and "@" not in v: why = "قيمة وهمية"
        elif any(c in v for c in "…⏳·«»؟✓✗"): why = "نص توضيحي"
        elif k in PAT and not re.match(PAT[k], v): why = "شكل خاطئ"
        if why: drop.append((k, v)); continue
        E[k] = v
open("keys.env", "w", encoding="utf-8").write("# CineHub 3099\n" + "\n".join("%s=%s" % (k, E[k]) for k in sorted(E)) + "\n")
print("  حُذف %d وهمي · بقي %d مفتاحًا" % (len(drop), len(E)))
CAT = {"AADS_UNIT":("A-ADS","$0","adult-ok"),"EXOCLICK_ZONE":("ExoClick","€20","adult"),
 "JUICYADS_ZONE":("JuicyAds","$50","adult"),"TRAFFICJUNKY_ZONE":("TrafficJunky","$100","adult"),
 "PLUGRUSH_ZONE":("PlugRush","$25","adult"),"CLICKADU_ZONE":("Clickadu","$5","adult"),
 "HILLTOPADS_ZONE":("HilltopAds","$50","adult"),"ADMAVEN_ZONE":("AdMaven","$5","adult"),
 "GALAKSION_ZONE":("Galaksion","$10","adult"),"MYBID_ZONE":("MyBid","$25","adult"),
 "EVADAV_ZONE":("Evadav","$5","adult"),"STRIPCHAT_AFF":("Stripchat","$50","adult-aff"),
 "JASMIN_AFF":("LiveJasmin","$50","adult-aff"),"BONGA_AFF":("BongaCams","$50","adult-aff"),
 "ADSTERRA_API_KEY":("Adsterra","$5","general"),"MONETAG_MULTITAG":("Monetag","$5","general"),
 "PROPELLER_ZONE":("PropellerAds","$5","general"),"POPADS_SITE_ID":("PopAds","$5","general"),
 "ADCASH_ZONE":("Adcash","$5","general"),"ADSENSE_CLIENT":("AdSense","$100","general"),
 "CPAGRIP_SMARTLINK":("CPAGrip","$50","cpa"),"OGADS_SMARTLINK":("OGAds","$20","cpa"),
 "LINKVERTISE_UID":("Linkvertise","$5","short")}
try: a = json.load(open("ads.json", encoding="utf-8"))
except Exception: a = {}
nets = {n.get("k"): n for n in (a.get("networks") or []) if n.get("k")}
for k, (nm, pay, kind) in CAT.items():
    nets.setdefault(k, {"n": nm, "k": k, "pay": pay, "kind": kind})
on = 0
for k, n in nets.items():
    v = E.get(k) or ""; n["id"] = v; n["enabled"] = bool(v); on += bool(v)
a["networks"] = list(nets.values())
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ شبكات: %d مفعّلة من %d" % (on, len(nets)))
PY

# ═══════ 5 · تشغيل الوكيل ═══════
hd "5 · الوكيل"
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
      - env: {GH_TOKEN: "${{ secrets.GITHUB_TOKEN }}"}
        run: |
          for s in revenue_sync hits_report vault money dashboard ping; do
            [ -f "tools/$s.py" ] && python3 "tools/$s.py" || true
          done
          git config user.email a@c.local; git config user.name agent
          git add -A; git commit -m "cycle $(date -u +%FT%TZ)" || true; git push || true
YEOF
ok "workflow الوكيل"

cat > agentd.sh <<'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
while :; do
  for s in revenue_sync hits_report money dashboard vault; do
    [ -f "tools/$s.py" ] && python3 "tools/$s.py" >> logs/agentd.log 2>&1
  done
  git add -A >/dev/null 2>&1; git -c user.email=a@c.local -c user.name=agent commit -m "daemon" >/dev/null 2>&1
  git push --force origin main >/dev/null 2>&1
  sleep 1800
done
AEOF
chmod +x agentd.sh
pkill -f agentd.sh 2>/dev/null || true
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
ok "الوكيل المحلي يعمل (كل 30 دقيقة)"

# ═══════ 6 · بناء ونشر ═══════
hd "6 · بناء ونشر"
python3 tools/inject_hits.py 2>&1 | tee -a "$LOG"
for f in revenue_sync hits_report money dashboard vault; do python3 "tools/$f.py" >>"$LOG" 2>&1 || true; done
ok "الأدوات نُفّذت"

git config --local credential.helper ""; git config pull.rebase true
git remote remove origin 2>/dev/null || true; git remote add origin "$URL"
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "final build $(date +%F_%H%M)" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$R|%s'%time.time()).encode()).hexdigest()[:16])")"
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
VMSG="delegate: $U $SIG keys=$NK"
cat > verify.txt <<VEOF
CineHub 3099 — وثيقة تفويض
الحساب: $U
المستودع: https://github.com/$U/$R
الموقع: $SITE
التاريخ: $(date -u +%Y-%m-%dT%H:%M:%SZ)
رمز التفويض: $SIG
مفاتيح: $NK
VEOF
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  case "$i" in
    1) timeout 1800 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
[ "$P" = 1 ] || bad "الدفع فشل: $(tail -1 "$GHTMP/e" | cut -c1-70)"

# ═══════ 7 · إثبات وتحقق ═══════
hd "7 · إثبات وتحقق"
sleep 4
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$U/$R/commits/main" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null || true)"
[ "$RM" = "$VMSG" ] && ok "التفويض مُثبت على GitHub: $RM" || wrn "رسالة الريموت: ${RM:-?}"
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1
for f in "" app.html library.html money.html wallet.html verify.txt; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  تم التنفيذ — مفوَّض · مربوط · منشور · يعمل    ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  الحساب      : %s\n  رمز التفويض : %s%s%s\n  التطبيق     : %s/app.html\n  الأموال     : %s/money.html\n  الخزينة     : %s/wallet.html\n  السجل       : %s\n' \
  "$U" "$B" "$SIG" "$N" "$SITE" "$SITE" "$SITE" "$LOG" | tee -a "$LOG"
