#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  DOCTOR2.sh — شفاء كامل بلا أسئلة: يكتب الناقص · يطهّر · يربط · ينشر
#  bash DOCTOR2.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/doctor2.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
W(){ [ -f "$1" ] && return 0; shift; mkdir -p "$(dirname "$1" 2>/dev/null || echo .)" 2>/dev/null; cat > "$1"; ok "أُنشئ $1"; }

# ═══════ 1 · تطهير المفاتيح ═══════
hd "1 · تطهير المفاتيح"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re
JUNK = re.compile(r'^[A-Z][A-Z_]{6,}$')
DOM  = re.compile(r'^[a-z0-9\-]+(\.[a-z0-9\-]+)+$', re.I)
STOP = {"END","TRUE","FALSE","HTTP","HTTPS","API","KEY","NONE","NULL"}
PAT = {"AADS_UNIT":r'^\d{4,8}$', "ADSTERRA_API_KEY":r'^[A-Za-z0-9_-]{20,48}$',
       "EXOCLICK_ZONE":r'^\d{5,9}$', "JUICYADS_ZONE":r'^\d{4,9}$',
       "MONETAG_MULTITAG":r'^\d{5,9}$', "USDT_TRC20":r'^T[1-9A-HJ-NP-Za-km-z]{33}$',
       "MAIL_USER":r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$', "MAIL_APP_PASS":r'^[A-Za-z0-9]{12,20}$',
       "TMDB_KEY":r'^[0-9a-fA-F]{32}$', "OMDB_API_KEY":r'^[A-Za-z0-9]{6,12}$',
       "GH_TOKEN":r'^(gh[pousr]_|github_pat_)', "ADSENSE_CLIENT":r'^ca-pub-\d{10,20}$'}
E, drop = {}, []
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.rstrip("\n")
        if "=" not in s or s.lstrip().startswith("#"): continue
        k, v = s.split("=", 1); k, v = k.strip(), v.strip()
        if not v: continue
        why = None
        if v in STOP or JUNK.match(v): why = "كلمة إنجليزية لا مفتاح"
        elif DOM.match(v) and "@" not in v: why = "اسم نطاق"
        elif any(c in v for c in "…⏳·«»؟✓✗"): why = "نص توضيحي"
        elif k in PAT and not re.match(PAT[k], v): why = "شكل خاطئ"
        if why: drop.append((k, v, why)); continue
        E[k] = v
open("keys.env", "w", encoding="utf-8").write(
    "# CineHub 3099 — مطهّر\n" + "\n".join("%s=%s" % (k, E[k]) for k in sorted(E)) + "\n")
print("  حُذف %d · بقي %d" % (len(drop), len(E)))
for k, v, w in drop: print("    ✗ %-20s %-30s (%s)" % (k, v[:30], w))
PY

# ═══════ 2 · شفاء الملفات الأساسية ═══════
hd "2 · شفاء الملفات"
mkdir -p tools data .github/workflows

# gh.py كامل
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

# tools/vault.py
if [ ! -f tools/vault.py ]; then
cat > tools/vault.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, time, urllib.request
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
def get(u, h=None):
    r = urllib.request.Request(u, headers=h or {"User-Agent": "CineHub3099"})
    with urllib.request.urlopen(r, timeout=25) as x: return json.loads(x.read().decode() or "{}")
src, total = [], 0.0
if E.get("ADSTERRA_API_KEY"):
    for h in ({"X-API-Key": E["ADSTERRA_API_KEY"]}, {"Authorization": "Bearer " + E["ADSTERRA_API_KEY"]}):
        try:
            d = get("https://api3.adsterra.com/api/v1/publisher/balance", h)
            b = float(d.get("balance") or d.get("amount") or 0)
            src.append({"n": "Adsterra", "usd": b, "live": True, "min": 5, "pay": "USDT/PayPal"}); total += b; break
        except Exception as e:
            src.append({"n": "Adsterra", "usd": 0, "live": False, "err": str(e)[:40], "min": 5, "pay": "USDT/PayPal"}); break
for n, k, mn, pay in (("ExoClick","EXOCLICK_ZONE",20,"Paxum/Wire"), ("JuicyAds","JUICYADS_ZONE",50,"Paxum/BTC"),
                      ("Monetag","MONETAG_MULTITAG",5,"PayPal/Skrill"), ("A-ADS","AADS_UNIT",0,"BTC تلقائي"),
                      ("TrafficJunky","TRAFFICJUNKY_ZONE",100,"Wire"), ("PlugRush","PLUGRUSH_ZONE",25,"PayPal/BTC"),
                      ("Clickadu","CLICKADU_ZONE",5,"PayPal/Paxum"), ("HilltopAds","HILLTOPADS_ZONE",50,"PayPal")):
    src.append({"n": n, "usd": 0, "live": False, "min": mn, "pay": pay,
                "note": "المعرّف مضبوط" if E.get(k) else "ينتظر المعرّف"})
btc = 0.0
try: btc = float(get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")["bitcoin"]["usd"])
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%Y-%m-%d %H:%M"), "sources": src, "total_usd": round(total, 4), "btc_usd": btc,
  "payout": {"bank": "بنك الكريمي للتمويل الأصغر", "swift": E.get("KURAIMI_SWIFT", "KBMFYESAXXX"),
             "name": E.get("KURAIMI_NAME", ""), "account": E.get("KURAIMI_ACCOUNT", ""), "usdt": E.get("USDT_TRC20", "")},
  "ladder": ["الشبكة → USDT(TRC20)/Paxum/PayPal/BTC", "Binance P2P: USDT → نقد", "صرافة", "إيداع الكريمي"]},
  open("data/wallet.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ wallet.json · إجمالي $%.4f" % total)
PYEOF
ok "tools/vault.py"; fi

# tools/revenue_sync.py
if [ ! -f tools/revenue_sync.py ]; then
cat > tools/revenue_sync.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, "tools"))
import gh
T = gh.token()
def api(p):
    r = urllib.request.Request("https://api.github.com" + p,
        headers={"Authorization": "Bearer " + T, "Accept": "application/vnd.github+json", "User-Agent": "CineHub3099"})
    with urllib.request.urlopen(r, timeout=30) as x: return json.loads(x.read().decode() or "{}")
try: me = api("/user")["login"]
except Exception: sys.exit(0)
repo = me + ".github.io"
out = {"updated": time.strftime("%Y-%m-%d %H:%M"), "pages_url": "https://%s.github.io/" % me,
       "views_14d": 0, "uniques_14d": 0, "clones_14d": 0, "stars": 0, "top_paths": []}
for key, p in (("views", "/traffic/views"), ("clones", "/traffic/clones")):
    try:
        d = api("/repos/%s/%s%s" % (me, repo, p))
        out[key + "_14d"] = d.get("count", 0)
        if key == "views": out["uniques_14d"] = d.get("uniques", 0)
    except Exception: pass
try: out["stars"] = api("/repos/%s/%s" % (me, repo)).get("stargazers_count", 0)
except Exception: pass
try: out["top_paths"] = api("/repos/%s/%s/traffic/popular/paths" % (me, repo))[:20]
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump(out, open("data/revenue.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ زيارات GitHub: %d" % out["views_14d"])
PYEOF
ok "tools/revenue_sync.py"; fi

# أدوات مساعدة بسيطة إن غابت
for t in money dashboard ping; do
  [ -f "tools/$t.py" ] || { printf '#!/usr/bin/env python3\nimport os,time\nROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\nos.makedirs(os.path.join(ROOT,"data"),exist_ok=True)\nprint("  ✓ %s")\n' "$t" > "tools/$t.py"; ok "tools/$t.py"; }
done

# hits.js + 404
[ -f hits.js ] || { cat > hits.js <<'JEOF'
(function(){var k=(location.pathname.replace(/^\/|\/$/g,"")||"home").replace(/\//g,"__").replace(/[^\w.\-]/g,"_");
function f(u){try{fetch(u,{cache:"no-store"}).catch(function(){})}catch(e){}}
f("https://api.counterapi.dev/v1/cinehub3099/"+k+"/up");f("https://abacus.jasoncameron.dev/hit/cinehub3099/"+k);})();
JEOF
ok "hits.js"; }
[ -f 404.html ] || { cat > 404.html <<'HEOF'
<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>غير موجود</title><style>body{margin:0;background:#0b0d12;color:#e9eef6;font:16px/1.8 system-ui,Tahoma;display:grid;place-items:center;height:100vh;text-align:center}a{color:#5ca9ff}</style>
<div><b style="font-size:22px">الصفحة غير موجودة</b><p><a href="/">الرئيسية</a> · <a href="/app.html">التطبيق</a> · <a href="/library.html">المكتبة</a></p></div></html>
HEOF
ok "404.html"; }
[ -f .nojekyll ] || { : > .nojekyll; ok ".nojekyll"; }
[ -f robots.txt ] || { printf 'User-agent: *\nAllow: /\nSitemap: https://%s.github.io/sitemap.xml\n' "$(python3 -c "import gh;print(gh.login())" 2>/dev/null || echo alisalimax3)" > robots.txt; ok "robots.txt"; }

# ═══════ 3 · بناء التطبيق إن غاب ═══════
hd "3 · بناء التطبيق"
if [ ! -f app.html ]; then
cat > app.html <<'AEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub 3099 — التطبيق</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
header{position:sticky;top:0;background:#0e1219ee;backdrop-filter:blur(8px);border-bottom:1px solid #1b2331;padding:10px;z-index:9}
.w{max-width:1100px;margin:0 auto;padding:0 12px}
input{width:100%;padding:11px 14px;border-radius:11px;border:1px solid #232c3c;background:#131a25;color:#e9eef6;font-size:15px}
.chips{display:flex;gap:6px;overflow-x:auto;padding:9px 0;scrollbar-width:none}
.chips::-webkit-scrollbar{display:none}
.chip{white-space:nowrap;padding:5px 12px;border-radius:999px;background:#161e2b;border:1px solid #232c3c;color:#a9b6c9;font-size:12.5px;cursor:pointer}
.chip.on{background:#17324d;color:#8ec5ff;border-color:#27567f}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:12px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px 7px;font-weight:500;line-height:1.35;height:52px;overflow:hidden}
.ad{margin:10px 0;min-height:60px;display:flex;justify-content:center;align-items:center}
.more{width:100%;padding:12px;margin:10px 0 30px;border-radius:11px;background:#16233a;color:#a9ccff;border:1px solid #24354f;font-size:14px;cursor:pointer}
nav a{color:#8fa4bf;font-size:12.5px;margin-inline-end:12px;text-decoration:none}
.k{color:#7d8899;font-size:12px;text-align:center;padding:10px}
</style></head><body>
<header><div class="w"><nav><a href="./">الرئيسية</a><a href="library.html">المكتبة</a><a href="money.html">الأموال</a><a href="wallet.html">الخزينة</a></nav>
<input id="q" placeholder="ابحث عن فيلم أو مسلسل…" autocomplete="off"></div></header>
<div class="w"><div class="chips" id="chips"></div><div class="ad" id="ad1"></div>
<div class="grid" id="g"></div><button class="more" id="more">المزيد</button>
<div class="ad" id="ad2"></div><div class="k" id="st">…</div></div>
<script src="hits.js" defer></script>
<script>
let ALL=[],F=[],N=120;
async function load(){for(const f of['catalog.json','films.json','titles.json','data/catalog.json']){try{const r=await fetch(f);if(!r.ok)continue;const d=await r.json();
const a=Array.isArray(d)?d:(d.items||Object.values(d));if(a&&a.length)return a.map(x=>({i:x.i||x.id||x.slug,t:x.t||x.title||x.name||'',th:x.th||x.poster||x.image||'',y:x.y||x.year||'',c:x.c||x.cat||x.category||''})).filter(x=>x.t)}catch(e){}}return[]}
function draw(){const q=(document.getElementById('q').value||'').toLowerCase();
F=ALL.filter(x=>(!q||x.t.toLowerCase().includes(q))&&(!window.CAT||x.c===window.CAT));
document.getElementById('g').innerHTML=F.slice(0,N).map(x=>'<a class="c" href="'+(x.i?'f/'+encodeURIComponent(x.i)+'.html':'#')+'">'+
'<img loading="lazy" src="'+(x.th||'')+'" onerror="this.style.opacity=.25"><b>'+x.t+(x.y?' ('+x.y+')':'')+'</b></a>').join('');
document.getElementById('more').style.display=F.length>N?'block':'none';
document.getElementById('st').textContent=ALL.length?F.length+' نتيجة من '+ALL.length:'لا كتالوج بعد — شغّل المولّد';}
document.getElementById('q').oninput=()=>{N=120;draw()};
document.getElementById('more').onclick=()=>{N+=120;draw()};
(async()=>{ALL=await load();const gs=[...new Set(ALL.map(x=>x.c).filter(Boolean))].slice(0,24);
document.getElementById('chips').innerHTML=gs.map(g=>'<div class="chip">'+g+'</div>').join('');
document.querySelectorAll('.chip').forEach(c=>c.onclick=()=>{document.querySelectorAll('.chip').forEach(z=>z.classList.remove('on'));
if(window.CAT===c.textContent){window.CAT=null}else{window.CAT=c.textContent;c.classList.add('on')}N=120;draw()});
draw();
try{const a=await(await fetch('ads.json')).json();const on=(a.networks||[]).filter(n=>n.id);
const html=on.slice(0,2).map(n=>{
 if(n.k==='AADS_UNIT')return'<iframe src="https://a-ads.com/banner?aa='+n.id+'&size=300x250" width="300" height="250" frameborder="0" scrolling="no"></iframe>';
 if(n.k==='EXOCLICK_ZONE')return'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+n.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>';
 return'';}).join('');
document.getElementById('ad1').innerHTML=html||('<span class="k">'+on.length+' شبكة مفعّلة</span>');}catch(e){}
})();
</script></body></html>
AEOF
ok "app.html"; fi

[ -f library.html ] || cp app.html library.html 2>/dev/null || true
[ -f sitemap.xml ] || { printf '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n<url><loc>https://%s.github.io/</loc></url>\n</urlset>\n' "$(python3 -c "import gh;print(gh.login())" 2>/dev/null||echo x)" > sitemap.xml; ok "sitemap.xml"; }
[ -f ads.json ] || { printf '{"networks":[]}\n' > ads.json; ok "ads.json"; }

# ═══════ 4 · ربط الشبكات ═══════
hd "4 · ربط الشبكات"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
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
    if k not in nets: nets[k] = {"n": nm, "k": k, "pay": pay, "kind": kind}
on = 0
for k, n in nets.items():
    v = E.get(k) or ""; n["id"] = v; n["enabled"] = bool(v); on += bool(v)
a["networks"] = list(nets.values())
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ مفعّل %d من %d شبكة" % (on, len(nets)))
PY

# ═══════ 5 · نشر ═══════
hd "5 · نشر"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
if [ -n "$U" ]; then
  R="$U.github.io"; SITE="https://$U.github.io"
  python3 -c "import gh;gh.ensure_repo();gh.enable_pages()" >/dev/null 2>&1 || true
  git config --local credential.helper ""; git config pull.rebase true
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
  git add -A
  git -c user.email=a@c.local -c user.name=Agent commit -m "heal $(date +%F_%H%M)" >/dev/null 2>&1 || true
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
  P=0
  for i in 1 2 3 4; do
    case "$i" in
      1) timeout 1800 git push origin main 2>"$GHTMP/e" && P=1 ;;
      2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
      3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
      4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
         git -c user.email=a@c.local -c user.name=Agent commit -m heal >/dev/null 2>&1
         git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    esac
    [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
  done
  [ "$P" = 1 ] || bad "الدفع فشل: $(tail -1 "$GHTMP/e" | cut -c1-70)"
else bad "لا مصادقة"; fi

# ═══════ 6 · تحقق ═══════
hd "6 · تحقق"
if [ -n "${SITE:-}" ]; then
  for f in "" app.html library.html money.html wallet.html robots.txt; do
    c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 10; done
    [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
  done
fi
hd "الخلاصة"
printf '  الموقع : %s/\n  التطبيق: %s/app.html\n  الخزينة: %s/wallet.html\n  السجل  : %s\n' "${SITE:-?}" "${SITE:-?}" "${SITE:-?}" "$LOG" | tee -a "$LOG"
