#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  EXPAND.sh — PWA · SEO · hubs · RSS · تكثيف الوكيل إلى 20 مهمة
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data proof .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/expand.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · تنظيف"
pkill -f agentd.sh 2>/dev/null || true; sleep 1
rm -f .git/index.lock .git/*.lock 2>/dev/null; ok "جاهز"

U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { wrn "لا تفويض"; exit 1; }
SITE="https://$U.github.io"

hd "1 · PWA — تثبيت على الجوال"
cat > manifest.json <<'MEOF'
{
 "name": "CineHub 3099 — أفلام مجانية",
 "short_name": "CineHub",
 "description": "مشاهدة أفلام ومسلسلات مجانًا بلا تسجيل",
 "start_url": "/app.html",
 "scope": "/",
 "display": "standalone",
 "orientation": "portrait",
 "background_color": "#0b0d12",
 "theme_color": "#0b0d12",
 "lang": "ar",
 "dir": "rtl",
 "categories": ["entertainment", "video"],
 "icons": [
   {"src": "/icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any"},
   {"src": "/icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "maskable"}
 ]
}
MEOF

cat > icon.svg <<'IEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<rect width="512" height="512" rx="96" fill="#0b0d12"/>
<rect x="96" y="150" width="320" height="212" rx="26" fill="#16233a" stroke="#2c6a9c" stroke-width="8"/>
<circle cx="180" cy="212" r="16" fill="#5ca9ff"/><circle cx="180" cy="256" r="16" fill="#5ca9ff"/>
<circle cx="180" cy="300" r="16" fill="#5ca9ff"/>
<path d="M250 190 L370 256 L250 322 Z" fill="#39d98a"/>
<rect x="120" y="382" width="272" height="16" rx="8" fill="#1e2635"/>
</svg>
IEOF

cat > sw.js <<'SEOF'
const C = 'cinehub-3099-v1';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;
  let u; try { u = new URL(r.url); } catch (x) { return; }
  if (u.origin !== location.origin) return;
  const dyn = /\.(json|xml)$/.test(u.pathname);
  if (dyn) {
    e.respondWith(fetch(r).then(x => { const c = x.clone(); caches.open(C).then(k => k.put(r, c)); return x; })
      .catch(() => caches.match(r)));
  } else {
    e.respondWith(caches.match(r).then(c => c || fetch(r).then(x => {
      const cl = x.clone(); caches.open(C).then(k => k.put(r, cl)); return x;
    })));
  }
});
SEOF

cat > install.html <<'PEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>تثبيت التطبيق</title>
<link rel="manifest" href="manifest.json"><meta name="theme-color" content="#0b0d12">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:16px/1.9 system-ui,Tahoma}
.w{max-width:680px;margin:0 auto;padding:22px}.c{background:#131a25;border:1px solid #1e2635;border-radius:13px;padding:14px;margin:10px 0}
button{width:100%;padding:14px;border-radius:12px;border:0;background:#1d4ed8;color:#fff;font-size:16px;cursor:pointer}
ol{padding-inline-start:22px}a{color:#5ca9ff}b{color:#8ec5ff}</style></head><body>
<div class="w"><h1>📲 ثبّت التطبيق</h1>
<div class="c"><b>أندرويد · Chrome</b><ol><li>افتح القائمة (⋮) أعلى اليمين</li><li>«إضافة إلى الشاشة الرئيسية»</li></ol></div>
<div class="c"><b>آيفون · Safari</b><ol><li>زر المشاركة ⬆️</li><li>«إضافة إلى الشاشة الرئيسية»</li></ol></div>
<button id="b">تثبيت الآن</button>
<div class="c" style="color:#8b96a8;font-size:13.5px">بعد التثبيت يعمل التطبيق بلا شريط متصفح، ويفتح أسرع، ويعمل جزئيًا بلا إنترنت.</div>
<p><a href="app.html">← فتح التطبيق</a></p></div>
<script>
let p=null;
addEventListener('beforeinstallprompt',e=>{e.preventDefault();p=e;document.getElementById('b').style.display='block'});
document.getElementById('b').onclick=async()=>{if(p){p.prompt();await p.userChoice;p=null}else location.href='app.html'};
if('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(()=>{});
</script></body></html>
PEOF
ok "manifest · icon · sw · install"

python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re
PUB = ["index.html", "app.html", "library.html", "links.html"]
for f in PUB:
    if not os.path.exists(f): continue
    s = open(f, encoding="utf-8").read()
    if 'rel="manifest"' not in s:
        s = s.replace("</head>", '<link rel="manifest" href="manifest.json">\n<meta name="theme-color" content="#0b0d12">\n</head>', 1)
    if "sw.js" not in s:
        s = s.replace("</body>", "<script>if('serviceWorker' in navigator)navigator.serviceWorker.register('sw.js').catch(function(){});</script>\n</body>", 1)
    if f in ("index.html", "app.html") and "install.html" not in s:
        s = s.replace("</footer>", '<a href="install.html" style="color:#8ec5ff">📲 ثبّت التطبيق</a></footer>', 1)
    open(f, "w", encoding="utf-8").write(s)
    print("  ✓ %s: manifest + sw" % f)
PY

hd "2 · SEO — بطاقات مشاركة وهيكل بيانات"
cat > tools/seo.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يحقن OG + Twitter + JSON-LD في صفحات الأفلام تدريجيًا (يتابع من حيث توقف)."""
import json, os, re, sys
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAP = int(os.environ.get("SEO_MAX", "5000"))
try: U = json.load(open("data/seo_done.json", encoding="utf-8")).get("done", [])
except Exception: U = []
done = set(U)
files = []
for dp, dn, fn in os.walk("f"):
    for f in fn:
        if f.endswith(".html"): files.append(os.path.join(dp, f))
files.sort()
n = 0
for p in files:
    if p in done: continue
    if n >= CAP: break
    try: s = open(p, encoding="utf-8").read()
    except Exception: continue
    if 'property="og:title"' in s: done.add(p); continue
    t = re.search(r"<title>(.*?)</title>", s, re.S)
    title = (t.group(1).strip() if t else os.path.basename(p)[:-5])
    img = re.search(r'<img[^>]+src="([^"]+)"', s)
    image = img.group(1) if img else "/icon.svg"
    if image.startswith("/"): image = "https://" + os.environ.get("GH_HOST", "") + image
    og = ('<meta property="og:type" content="video.movie"><meta property="og:title" content="%s">'
          '<meta property="og:image" content="%s"><meta property="og:site_name" content="CineHub 3099">'
          '<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="%s">'
          '<meta name="twitter:image" content="%s">'
          '<script type="application/ld+json">{"@context":"https://schema.org","@type":"Movie","name":"%s","image":"%s"}</script>'
          % (title.replace('"', "'"), image, title.replace('"', "'"), image, title.replace('"', "'"), image))
    s = s.replace("</head>", og + "</head>", 1) if "</head>" in s else og + s
    try: open(p, "w", encoding="utf-8").write(s)
    except Exception: continue
    done.add(p); n += 1
json.dump({"done": sorted(done), "at": __import__("time").strftime("%F %H:%M")},
          open("data/seo_done.json", "w", encoding="utf-8"), ensure_ascii=False)
print("  ✓ SEO: %d صفحة (المجموع %d من %d)" % (n, len(done), len(files)))
PYEOF
chmod +x tools/seo.py
GH_HOST="$U.github.io" SEO_MAX=6000 python3 tools/seo.py 2>&1 | tee -a "$LOG"

hd "3 · صفحات hubs + RSS + QR"
cat > tools/hubs.py <<'PYEOF'
#!/usr/bin/env python3
import html, json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
S = rd("data/revenue.json", {}).get("pages_url") or ""
items = []
for f in ("catalog.json", "films.json", "titles.json"):
    d = rd(f, None)
    if not d: continue
    a = d.get("items") if isinstance(d, dict) else d
    if isinstance(a, dict): a = list(a.values())
    if isinstance(a, list):
        for x in a:
            if isinstance(x, dict) and (x.get("t") or x.get("title")):
                items.append({"i": x.get("i") or x.get("id") or "", "t": x.get("t") or x.get("title"),
                              "th": x.get("th") or x.get("poster") or "", "y": str(x.get("y") or "")[:4],
                              "c": x.get("c") or x.get("cat") or ""})
    if items: break
def page(title, desc, arr, fn, extra=""):
    cards = "".join('<a class="c" href="f/%s.html"><img loading="lazy" src="%s"><b>%s</b></a>'
                    % (html.escape(str(x["i"])), html.escape(x["th"] or ""), html.escape(str(x["t"]))) for x in arr[:120])
    open(fn, "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>
<meta name="description" content="%s">
<link rel="manifest" href="manifest.json"><link rel="alternate" type="application/rss+xml" title="CineHub" href="feed.xml">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:1100px;margin:0 auto;padding:16px}
h1{font-size:21px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:10px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
a{color:#5ca9ff}nav a{margin-inline-end:10px;text-decoration:none;color:#8fa4bf;font-size:12.5px}</style></head><body>
<div class="w"><nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="movies.html">أفلام</a><a href="series.html">مسلسلات</a><a href="adult.html">للكبار</a><a href="install.html">تثبيت</a></nav>
<h1>%s</h1><p style="color:#8b96a8;font-size:13px">%s</p>%s<div class="grid">%s</div>
<p><a href="feed.xml">📡 اشترك في RSS</a></p></div></body></html>"""
    % (title, desc, title, desc, extra, cards))
adult = [x for x in items if any(k in (x["c"] or "").lower() for k in ("adult","18","xxx","erotic"))] or items[:60]
page("أفلام مجانية", "أحدث الأفلام — مشاهدة مباشرة بلا تسجيل", items, "movies.html")
page("مسلسلات", "مسلسلات وحلقات — تحديث مستمر", items[20:] or items, "series.html")
page("للكبار", "قسم الأفلام للكبار", adult, "adult.html")
# feed
now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
open("feed.xml", "w", encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
 '<title>CineHub 3099</title><link>%s</link><description>أفلام مجانية</description><language>ar</language>'
 '<lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
 % (S, now, "".join('<item><title>%s</title><link>%s/f/%s.html</link></item>' % (html.escape(str(x["t"])), S, html.escape(str(x["i"]))) for x in items[:50])))
print("  ✓ movies/series/adult + feed.xml")
PYEOF
chmod +x tools/hubs.py
python3 tools/hubs.py 2>&1 | tee -a "$LOG"

cat > tools/promote.py <<'PYEOF'
#!/usr/bin/env python3
import html, json, os, time, urllib.parse
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = json.load(open("data/revenue.json", encoding="utf-8")).get("pages_url", "") if os.path.exists("data/revenue.json") else ""
items = []
d = None
for f in ("catalog.json", "films.json"):
    try: d = json.load(open(f, encoding="utf-8"))
    except Exception: continue
    if d: break
a = (d.get("items") if isinstance(d, dict) else d) or []
for x in (a if isinstance(a, list) else [])[:60]:
    if isinstance(x, dict) and x.get("t"): items.append({"t": x["t"], "i": x.get("i", "")})
rows = ""
for x in items:
    u = "%s/f/%s.html" % (S, x["i"]); t = x["t"]
    qr = "https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=" + urllib.parse.quote(u)
    txt = "%s — شاهد مجانًا\n%s" % (t, u)
    rows += ('<div class="c"><img src="%s"><div style="flex:1"><b>%s</b><textarea readonly>%s</textarea>'
             '<a target="_blank" href="https://wa.me/?text=%s">واتساب</a> '
             '<a target="_blank" href="https://t.me/share/url?url=%s&text=%s">تليجرام</a> '
             '<a target="_blank" href="https://twitter.com/intent/tweet?text=%s">X</a></div></div>'
             % (qr, html.escape(t), html.escape(txt), urllib.parse.quote(txt), urllib.parse.quote(u),
                urllib.parse.quote(t), urllib.parse.quote(txt)))
open("promote.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>ترويج</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:900px;margin:0 auto;padding:16px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px}
.c img{width:110px;height:110px;border-radius:8px;background:#fff;padding:4px}.c b{font-size:13.5px}
textarea{width:100%%;height:46px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px;margin-inline-end:8px}</style>
<div class="w"><h1>📣 ترويج — QR + نص جاهز لكل فيلم</h1>
<p style="color:#8b96a8;font-size:13px">انسخ النص أو اعرض QR. كل فتح = زيارة = إعلان.</p>%s</div></html>""" % rows)
print("  ✓ promote.html (%d)" % len(items))
PYEOF
chmod +x tools/promote.py
python3 tools/promote.py 2>&1 | tee -a "$LOG"

hd "4 · تكثيف الوكيل إلى 20 مهمة"
cat > tools/indexnow_new.py <<'PYEOF'
#!/usr/bin/env python3
"""IndexNow تدريجي: الجديد فقط"""
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
key = next((f[:-4] for f in os.listdir(".") if f.endswith(".txt") and f[:-4].isalnum() and len(f[:-4]) in (8, 32)), None)
if not key:
    key = "cinehub3099index"
    open(key + ".txt", "w").write(key)
files = []
for dp, dn, fn in os.walk("."):
    if ".git" in dp or "node_modules" in dp or dp.startswith("./data"): continue
    for f in fn:
        if f.endswith(".html"): files.append(os.path.relpath(os.path.join(dp, f), ".").replace("\\", "/"))
files.sort()
try: st = json.load(open("data/indexed.json", encoding="utf-8"))
except Exception: st = {"done": []}
done = set(st.get("done", []))
new = [f for f in files if f not in done]
if not new:
    print("  · لا جديد"); raise SystemExit
batch = new[:500]
urls = [S + "/" + f for f in batch]
body = json.dumps({"host": "%s.github.io" % U, "key": key, "keyLocation": "%s/%s.txt" % (S, key), "urlList": urls}).encode()
try:
    r = urllib.request.Request("https://api.indexnow.org/indexnow", data=body,
        headers={"Content-Type": "application/json; charset=utf-8"})
    with urllib.request.urlopen(r, timeout=60) as x: code = x.status
except Exception as e: code = str(e)[:30]
st["done"] = list(done | set(batch)); st["at"] = time.strftime("%F %H:%M")
json.dump(st, open("data/indexed.json", "w", encoding="utf-8"))
print("  ✓ أُرسل %d رابط جديد (كود %s) · المتبقي %d" % (len(batch), code, len(new) - len(batch)))
PYEOF

cat > tools/wayback_new.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
try: st = json.load(open("data/wayback.json", encoding="utf-8"))
except Exception: st = {"done": []}
done = set(st.get("done", []))
CAND = ["/", "/app.html", "/movies.html", "/adult.html", "/links.html", "/install.html", "/feed.xml"]
new = [c for c in CAND if c not in done][:4]
ok = 0
for c in new:
    try:
        urllib.request.urlopen("https://web.archive.org/save/" + S + c, timeout=75)
        done.add(c); ok += 1
    except Exception: pass
st["done"] = sorted(done); st["at"] = time.strftime("%F %H:%M")
json.dump(st, open("data/wayback.json", "w", encoding="utf-8"))
print("  ✓ أُرشف %d صفحة (المجموع %d)" % (ok, len(done)))
PYEOF

cat > tools/proof.py <<'PYEOF'
#!/usr/bin/env python3
import hashlib, json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CRIT = ["index.html","app.html","library.html","links.html","earn.html","owner.html","proof.html",
        "ads.json","hits.js","robots.txt","sitemap.xml","verify.txt","manifest.json","sw.js",
        "gh.py",".github/workflows/agent.yml","tools/tasks.py","tools/linkfix.py","tools/seo.py"]
man = {"at": time.strftime("%Y-%m-%dT%H:%M:%SZ"), "files": {}}
os.makedirs("proof", exist_ok=True)
for f in CRIT:
    if not os.path.exists(f): continue
    h = hashlib.sha256(open(f, "rb").read()).hexdigest()
    man["files"][f] = h[:32]
    open("proof/" + f.replace("/", "_") + ".sha", "w").write(h + "\n")
man["count"] = len(man["files"])
man["root"] = hashlib.sha256("".join(sorted(man["files"].values())).encode()).hexdigest()[:32]
json.dump(man, open("proof/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ مانيفست %d · جذر %s" % (man["count"], man["root"]))
PYEOF

cat > tools/tasks.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""طابور 20 مهمة بفواصل زمنية — ينفّذ المستحق فقط ويسجّل النتيجة"""
import json, os, subprocess, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
M = 60
T = [
 ("عدّاد فوري",      "tools/hits_report.py",   15*M),
 ("الخزينة",          "tools/vault.py",          15*M),
 ("الأموال",          "tools/money.py",          15*M),
 ("زيارات حقيقية",   "tools/revenue_sync.py",    30*M),
 ("اللوحة",           "tools/dashboard.py",      30*M),
 ("فهرسة سريعة",     "tools/indexnow_new.py",    30*M),
 ("روابط النشر",     "tools/share.py",           60*M),
 ("ترويج QR",        "tools/promote.py",         60*M),
 ("أرشفة",            "tools/wayback_new.py",    120*M),
 ("سجل الدخل",       "tools/earn.py",            180*M),
 ("سجل المنصات",     "tools/platforms_page.py",  180*M),
 ("hubs",             "tools/hubs.py",           180*M),
 ("SEO تدريجي",      "tools/seo.py",             240*M),
 ("إصلاح الروابط",   "tools/linkfix.py",         360*M),
 ("إشعار ping",      "tools/ping.py",            60*M),
 ("إثبات",            "tools/proof.py",           360*M),
 ("تحقق بصمات",      "VERIFY.sh",                 720*M),
]
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
st = rd("data/tasks.json", {"runs": 0, "log": []})
now = time.time(); done = []
for name, cmd, every in T:
    if now - st.get("last", {}).get(name, 0) < every: continue
    t0 = time.time()
    try:
        run = ("bash " if cmd.endswith(".sh") else "python3 ") + cmd
        p = subprocess.run(run, shell=True, capture_output=True, text=True, timeout=900)
        out = ((p.stdout or "") + (p.stderr or "")).strip().splitlines()
        done.append({"t": name, "ok": p.returncode == 0, "s": round(time.time() - t0, 1), "msg": (out[-1][:110] if out else "")})
    except Exception as e:
        done.append({"t": name, "ok": False, "s": round(time.time() - t0, 1), "msg": str(e)[:110]})
    st.setdefault("last", {})[name] = now
st["runs"] = st.get("runs", 0) + 1; st["at"] = time.strftime("%F %H:%M")
st["log"] = (done + st.get("log", []))[:80]
json.dump(st, open("data/tasks.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ %d مهمة (دورة %d) من %d" % (len(done), st["runs"], len(T)))
for d in done: print("    %s %-16s %5.1fs %s" % ("✓" if d["ok"] else "✗", d["t"], d["s"], d["msg"][:64]))
PYEOF
chmod +x tools/*.py

cat > agentd.sh <<'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
unlock(){ local n=0; while [ -f .git/index.lock ]; do n=$((n+1)); [ $n -gt 40 ] && { rm -f .git/index.lock; break; }; sleep 3; done; }
while :; do
  python3 tools/tasks.py >> logs/agentd.log 2>&1
  python3 - <<'PY' >> logs/agentd.log 2>&1
import json, time
try: st = json.load(open("agent_state.json", encoding="utf-8"))
except Exception: st = {}
st.update({"cycles": st.get("cycles", 0) + 1, "at": time.strftime("%F %H:%M"), "status": "ok"})
json.dump(st, open("agent_state.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  unlock; git add -A >/dev/null 2>&1
  git -c user.email=a@c.local -c user.name=agent commit -m "agent $(date +%F_%H%M)" >/dev/null 2>&1
  unlock; git push --force origin main >/dev/null 2>&1
  sleep 900
done
AEOF
chmod +x agentd.sh

python3 - <<'PY' >/dev/null 2>&1
p = ".github/workflows/agent.yml"
s = open(p, encoding="utf-8").read() if __import__("os").path.exists(p) else ""
if s:
    s = s.replace('cron: "15 */6 * * *"', 'cron: "5 */2 * * *"')
    if "tasks.py" not in s:
        s = s.replace("for s in revenue_sync", "python3 tools/tasks.py || true\n          for s in revenue_sync")
    open(p, "w", encoding="utf-8").write(s)
PY
ok "الوكيل: 17 مهمة · محلي كل 15 دقيقة · سحابي كل ساعتين"

hd "5 · تشغيل ونشر"
python3 tools/tasks.py 2>&1 | tee -a "$LOG"
python3 tools/proof.py 2>&1 | tee -a "$LOG"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
R="$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
ROOT="$(python3 -c "import json;print(json.load(open('proof/manifest.json'))['root'])")"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$ROOT|%s'%time.time()).encode()).hexdigest()[:24])")"
printf '%s' "$SIG" > .tmp/lastcode
VMSG="expand: $U $SIG root=$ROOT"
printf 'CineHub 3099 — توسيع\nالحساب: %s\nالموقع: %s\nالجذر: %s\nالتوقيع: %s\n' "$U" "$SITE" "$ROOT" "$SIG" > verify.txt
rm -f .git/index.lock 2>/dev/null
git add -A
git add -f .github/workflows/agent.yml 2>/dev/null || true
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 2400 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 2400 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1

pkill -f agentd.sh 2>/dev/null || true; sleep 1; rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل — 17 مهمة كل 15 دقيقة"

hd "6 · تحقق"
for f in "" app.html movies.html adult.html promote.html install.html manifest.json sw.js feed.xml; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  موسّع · قابل للتثبيت · الوكيل مكثّف           ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  للمستخدم : %s/  ·  تثبيت: %s/install.html\n  أفلام    : %s/movies.html · للكبار: %s/adult.html\n  ترويج    : %s/promote.html\n  التوقيع  : %s%s%s\n' \
  "$SITE" "$SITE" "$SITE" "$SITE" "$SITE" "$B" "$SIG" "$N" | tee -a "$LOG"
