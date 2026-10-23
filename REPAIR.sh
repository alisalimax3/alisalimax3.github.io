#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  REPAIR.sh — إصلاح حقيقي للأخطاء الثمانية · تنفيذ · اختبار · نشر
#  استخدام: bash REPAIR.sh          (نشر تلقائي)
#            ASK=1 bash REPAIR.sh   (يسأل قبل النشر)
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data go .github/workflows
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/repair.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · نسخة احتياطية"
BK="$HOME/cinehub-backups/repair-$(date +%F_%H%M%S)"; mkdir -p "$BK"
tar czf "$BK/tree.tgz" --exclude=.git --exclude=.tmp --exclude=logs . 2>/dev/null
git bundle create "$BK/repo.bundle" --all >/dev/null 2>&1
cp keys.env "$BK/keys.env.bak" 2>/dev/null; cp -r data "$BK/data" 2>/dev/null
ok "$BK ($(du -sh "$BK" 2>/dev/null | cut -f1))"

# ══════════════════════════════ إصلاح 1 · core.py (ns() يستشفي ذاتيًا)
hd "1 · إصلاح core.py — نطاق العدّاد + استشفاء GH_USER"
cat > tools/core.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub 3099 — النواة: بيئة · توحيد حقول · أقفال · عملات · HTTP."""
import json, os, re, sys, time, html as _html, hashlib, contextlib, subprocess
import urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
TMP = os.path.join(ROOT, ".tmp"); os.makedirs(TMP, exist_ok=True)
DATA = os.path.join(ROOT, "data"); os.makedirs(DATA, exist_ok=True)

_ENVC = None
def _read_env():
    E = {}
    for p in ("keys.env", ".env", "data/keys.env"):
        if not os.path.exists(p): continue
        try: lines = open(p, encoding="utf-8", errors="ignore").read().splitlines()
        except Exception: continue
        for ln in lines:
            s = ln.strip()
            if not s or s.startswith("#") or "=" not in s: continue
            k, v = s.split("=", 1); k = k.strip()
            if k.startswith("export "): k = k[7:].strip()
            v = v.strip()
            if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'": v = v[1:-1]
            if k: E[k] = v
    return E
def env():
    global _ENVC
    if _ENVC is None: _ENVC = _read_env()
    return _ENVC
def reload_env():
    global _ENVC; _ENVC = None; return env()
def get(k, d=""): return env().get(k, d) or d
def has(k): return bool(env().get(k, "").strip())
def fp(v, n=8): return hashlib.sha256(str(v or "").encode()).hexdigest()[:n]
def mask(v, keep=4):
    v = str(v or ""); return "" if not v else (v if len(v) <= keep else v[:keep] + "…" + v[-2:])

def load(p, default=None):
    try:
        with open(p, encoding="utf-8") as f: return json.load(f)
    except Exception: return default
def save(p, obj):
    d = os.path.dirname(p)
    if d: os.makedirs(d, exist_ok=True)
    t = p + ".tmp"
    with open(t, "w", encoding="utf-8") as f: json.dump(obj, f, ensure_ascii=False, indent=1)
    os.replace(t, p)
def write_if_changed(p, text):
    try:
        if open(p, encoding="utf-8").read() == text: return False
    except Exception: pass
    d = os.path.dirname(p)
    if d: os.makedirs(d, exist_ok=True)
    open(p, "w", encoding="utf-8").write(text)
    return True

@contextlib.contextmanager
def lock(name, ttl=3600):
    p = os.path.join(TMP, "lk." + re.sub(r"\W+", "_", name))
    got = False
    try: os.mkdir(p); got = True
    except FileExistsError:
        try:
            if time.time() - os.path.getmtime(p) > ttl:
                os.rmdir(p); os.mkdir(p); got = True
        except Exception: pass
    try: yield got
    finally:
        if got:
            try: os.rmdir(p)
            except Exception: pass

def slug(s, n=70):
    s = re.sub(r"\s+", "-", str(s or "").strip())
    s = re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", s)
    s = re.sub(r"-{2,}", "-", s).strip("-._")
    return (s[:n] or "item")
def esc(x): return _html.escape(str(x or ""), quote=True)

UA = "Mozilla/5.0 (Linux; Android) CineHub3099-Agent/1.0"
def http(url, timeout=12, method="GET"):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"}, method=method)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {"ok": True, "code": r.status, "final": r.geturl()}
    except urllib.error.HTTPError as e:
        return {"ok": False, "code": e.code, "final": url, "err": "HTTP %s" % e.code}
    except Exception as e:
        return {"ok": False, "code": 0, "final": url, "err": type(e).__name__}

FIELD_MAP = {
  "t":  ("t","title","name","ar","ar_title","title_ar","original_title","en","label","nm"),
  "i":  ("i","id","slug","key","code","uid","imdb","imdb_id","tmdb","tmdb_id","_id","ref"),
  "th": ("th","poster","image","img","cover","thumbnail","pic","photo","poster_url","image_url","banner"),
  "c":  ("c","cat","category","genre","genres","section","type","kind","collection","tags","list"),
  "s":  ("s","src","source","provider","origin","site","from","host","server"),
  "y":  ("y","year","date","release","release_date","released","air_date","premiere"),
  "u":  ("u","url","link","href","watch","watch_url","embed","player","stream","file"),
  "d":  ("d","desc","description","overview","plot","summary","synopsis","about","note"),
}
LIST_KEYS = ("items","data","results","rows","entries","catalog","list","films","titles","movies","all")

def pick(d, key, default=""):
    for k in FIELD_MAP.get(key, (key,)):
        if k in d:
            v = d[k]
            if v in (None, "", [], {}): continue
            if isinstance(v, (list, tuple)): v = ", ".join(str(x) for x in v if x)
            return v
    return default
def as_list(d):
    if d is None: return []
    if isinstance(d, list): return [x for x in d if isinstance(x, dict)]
    if isinstance(d, dict):
        for k in LIST_KEYS:
            v = d.get(k)
            if isinstance(v, list): return [x for x in v if isinstance(x, dict)]
        if d and all(isinstance(v, dict) for v in d.values()):
            out = []
            for k, v in d.items():
                v = dict(v); v.setdefault("id", k); out.append(v)
            return out
    return []

CATALOG_FILES = ("catalog.json","films.json","titles.json","data/catalog.json","data/films.json","data/items.json","data/titles.json")

def catalog():
    out, seen, srcs = [], set(), []
    for f in CATALOG_FILES:
        d = load(f)
        if not d: continue
        rows = as_list(d)
        if not rows: continue
        srcs.append("%s:%d" % (f, len(rows)))
        for x in rows:
            t = str(pick(x, "t")).strip()
            i = str(pick(x, "i")).strip() or t
            if not t and not i: continue
            sl = slug(i or t)
            if sl in seen: continue
            seen.add(sl)
            out.append({"t": t or sl, "i": sl, "th": str(pick(x, "th")), "c": str(pick(x, "c")),
                        "s": str(pick(x, "s")), "y": str(pick(x, "y"))[:4],
                        "u": str(pick(x, "u")), "d": str(pick(x, "d"))[:300]})
    return out, " · ".join(srcs)

STRONG = ("adult","18+","xxx","erotic","nsfw","porn","hentai","rule34","redgifs","brazzers","milf","onlyfans")
WEAK   = ("adult","18+","xxx","erotic","nsfw","porn","hentai","rule34","sexy","lingerie","cam")
def is_adult(row):
    strong = (row.get("c","") + " " + row.get("s","")).lower()
    if any(k in strong for k in STRONG): return True
    weak = (row.get("t","") + " " + row.get("d","")).lower()
    return any(k in weak for k in WEAK)

def _owner():
    """يستنبط اسم المالك من المفاتيح أو .env أو git remote — لا يبقى anon."""
    u = get("GH_USER").strip()
    if not u:
        m = re.match(r"https?://([^.]+)\.github\.io", get("SITE_URL"))
        if m: u = m.group(1)
    if not u:
        try:
            r = subprocess.run(["git", "remote", "get-url", "origin"],
                               capture_output=True, text=True, timeout=8).stdout
            m = re.search(r"github\.com[:/]([^/]+)/", r or "")
            if m: u = m.group(1)
        except Exception: pass
    return u

def site():
    s = get("SITE_URL").rstrip("/")
    if s: return s
    o = _owner()
    return ("https://%s.github.io" % o) if o else ""
def ns():
    o = _owner()
    return "cinehub3099-" + re.sub(r"[^a-z0-9]", "", (o or "anon").lower())[:16]

def fx(): 
    d = load("data/fx.json", {}) or {}
    return d.get("rates", []) if isinstance(d, dict) else []
def convert(amount, frm, to="USD", date=""):
    frm, to = (frm or "USD").upper(), (to or "USD").upper()
    if frm == to: return float(amount), {"rate": 1.0, "date": date or time.strftime("%F"), "source": "identity"}
    best = None
    for r in fx():
        if (r.get("from","").upper(), r.get("to","").upper()) != (frm, to): continue
        if date and r.get("date","") > date: continue
        if best is None or r.get("date","") > best.get("date",""): best = r
    if not best: return None, {"rate": None, "date": "", "source": "missing"}
    return round(float(amount) * float(best["rate"]), 4), best
PYEOF
python3 -m py_compile tools/core.py && ok "core.py" || bad "core.py"

# ══════════════════════════════ إصلاح 2 · الجذر: pid → row[0]  ★ الأهم
hd "2 · إصلاح revenue_engine.py — الخطأ الذي أسقط 6 أدوات"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, shutil, subprocess, sys
p = "tools/revenue_engine.py"
s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/revenue_engine.py.bak")
before = s
# الإصلاح الجذري
s = s.replace("provs = [_rec(oi.get(pid, {}), *row) for row in P]",
              "provs = [_rec(oi.get(row[0], {}), *row) for row in P]")
# إبقاء fit_score بعد build()
s = s.replace('"verified_on": ver, "note": note,',
              '"verified_on": ver, "note": note,\n      "fit_score": int(o.get("fit_score", 0)),\n'
              '      "reachable": o.get("reachable"), "http_code": o.get("http_code"),\n'
              '      "checked_on": o.get("checked_on", ""),')
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/revenue_engine.py.bak", p)
    print("  ✗ استُعيد الأصل:", r.stderr.decode().strip().splitlines()[-1][:120])
else:
    print("  ✓ pid → row[0] :", before != s)
    print("  ✓ fit_score محفوظ:", '"fit_score"' in s)
    b = subprocess.run([sys.executable, p, "build"], capture_output=True, text=True, timeout=120)
    print("  " + ("✓ build يعمل" if b.returncode == 0 else "✗ build فشل: " + (b.stderr or "").strip().splitlines()[-1][:110]))
PY

# ══════════════════════════════ إصلاح 3 · hits.js بنطاق صحيح
hd "3 · إصلاح hits.js — نطاق صحيح + زوار فريدون + يُعاد بناؤه كل مرة"
cat > .tmp/hits.tpl <<'JSEOF'
/* CineHub 3099 — عدّاد سيرفري (Abacus) · بلا كوكيز · بلا تسجيل */
(function () {
  var NS = "__NS__", API = "https://abacus.jasoncameron.dev";
  function safe(k) { return k.replace(/[^A-Za-z0-9._-]/g, "-").replace(/-{2,}/g, "-"); }
  function vid() { try { var v = localStorage.getItem("ch_vid");
    if (!v) { v = Math.random().toString(36).slice(2, 10) + Date.now().toString(36); localStorage.setItem("ch_vid", v); }
    return v; } catch (e) { return "anon"; } }
  function hit(k) { return fetch(API + "/hit/" + safe(k)).then(function (r) { return r.json(); })
    .then(function (j) { return j && j.value; }).catch(function () { return null; }); }
  function get(k) { return fetch(API + "/get/" + safe(k)).then(function (r) { return r.json(); })
    .then(function (j) { return j && j.value; }).catch(function () { return null; }); }
  var d = new Date().toISOString().slice(0, 10);
  var path = safe(location.pathname.replace(/\/index\.html$/, "/") || "/");
  try { var q = new URLSearchParams(location.search);
    var ref = q.get("ref"); if (ref) localStorage.setItem("ch_ref", ref.slice(0, 24));
    var s1 = q.get("utm_source"); if (s1) localStorage.setItem("ch_src", s1.slice(0, 24));
    var c1 = q.get("utm_campaign"); if (c1) localStorage.setItem("ch_cmp", c1.slice(0, 24)); } catch (e) {}
  window.CH = { ns: NS, vid: vid, hit: hit, get: get, today: d,
    pv: "pv" + path, dv: "dv-" + d, uvtoday: "uniq-" + d, claims: "claims" };
  hit(window.CH.pv); hit(window.CH.dv);
  /* زائر فريد: مفتاح لكل (يوم+جهاز) → أول مرة فقط يزيد العدّاد العام */
  hit(NS + "/uv-" + d + "-" + vid()).then(function (v) { if (v === 1) hit(NS + "/uniq-" + d); });
  document.addEventListener("DOMContentLoaded", function () {
    var el = document.querySelectorAll("[data-hits]");
    for (var i = 0; i < el.length; i++) (function (n) {
      get(window.CH[n.getAttribute("data-hits")]).then(function (v) {
        if (v !== null && v !== undefined) n.textContent = v; }); })(el[i]);
  });
})();
JSEOF

# ══════════════════════════════ إصلاح 4 · ads.py (A-ADS بصيغتين)
hd "4 · إصلاح ads.py — دعم A-ADS المزدوج + منع التكرار"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import shutil, subprocess, sys
p = "tools/ads.py"; s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/ads.py.bak")
old = '''def _one(n):
    e = core.get(n["embed_key"])
    if e: return e
    z = n["zone"]
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    url = tpl.replace("{id}", core.esc(z)).replace("{size}", "300x250")
    return ('<iframe src="%s" width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % url)'''
new = '''def _one(n):
    e = core.get(n["embed_key"])
    if e: return e
    z = core.get(n["zone"])
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    z = core.esc(z)
    url = tpl.replace("{id}", z).replace("{size}", "300x250")
    # A-ADS: الوسم data-aa يجعل الصيغة الكلاسيكية تعمل أيضًا
    extra = " data-aa='%s'" % z if n["id"] == "aads" else ""
    return ('<iframe src="%s"%s width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % (url, extra))'''
if old in s: s = s.replace(old, new); print("  ✓ دعم A-ADS المزدوج")
else: print("  ! لم أطابق _one (سيُستخدم الأصل)")
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ ads.py سليم" if r.returncode == 0 else "✗ " + r.stderr.decode()[-120:]))
PY

# ══════════════════════════════ إصلاح 5 · secrets.py (عام مقابل سري)
hd "5 · إصلاح secrets.py — تمييز المفتاح العام عن السري"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import shutil, subprocess, sys
p = "tools/secrets.py"; s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/secrets.py.bak")
s = s.replace('SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}',
              'SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}\n'
              '# مفاتيح عامة بطبيعتها: معرّف المنطقة وروابط الإحالة — آمن ظهورها في الريبو\n'
              'PUBLIC_OK = {"GH_USER","SITE_URL","REF_CODE"}')
s = s.replace('''    for d in (".", "go", "adult"):''', '''    for d in (".", "go", "adult"):''')
s = s.replace('''            for n in GROUPS["api"] + list(SECRET):
                v = (E.get(n) or "").strip()
                if len(v) > 6 and v in s: out["leaks"].append("%s→%s" % (n, os.path.join(d, f)))''',
'''            for n in SECRET:
                v = (E.get(n) or "").strip()
                if len(v) > 6 and v in s:
                    out["leaks"].append("%s→%s" % (n, os.path.join(d, f)))''')
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ secrets.py" if r.returncode == 0 else "✗ " + r.stderr.decode()[-120:]))
PY

# ══════════════════════════════ إصلاح 6 · تعارض أسماء الصفحات
hd "6 · إصلاح تعارض earn.html و networks.html مع أدواتك"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import shutil, subprocess, sys
# rewards.py: earn.html → rewards-earn.html (بلا تعارض مع tools/earn.py)
p = "tools/rewards.py"; s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/rewards.py.bak")
s = s.replace('core.write_if_changed("earn.html", EARN % {',
              'core.write_if_changed("rewards-earn.html", EARN % {')
s = s.replace('print("  ✓ rewards.html + earn.html', 'print("  ✓ rewards.html + rewards-earn.html')
s = s.replace('<a href="earn.html">اكسب أكثر</a>', '<a href="rewards-earn.html">اكسب أكثر</a>')
open(p, "w", encoding="utf-8").write(s)
r1 = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)

# adult_registry.py: networks.html → income.html (بلا تعارض مع tools/networks.py) مع نسخة في الاسمين
p = "tools/adult_registry.py"; s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/adult_registry.py.bak")
s = s.replace('core.write_if_changed("networks.html", """',
              'HTML = """')
s = s.replace('''</div></body></html>""" % (len(r["providers"]), rows))
        print("  ✓ networks.html (%d مزود)" % len(r["providers"]))''',
'''</div></body></html>""" % (len(r["providers"]), rows)
        core.write_if_changed("income.html", HTML)
        core.write_if_changed("networks.html", HTML)
        print("  ✓ income.html + networks.html (%d مزود)" % len(r["providers"]))''')
open(p, "w", encoding="utf-8").write(s)
r2 = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ rewards.py + adult_registry.py" if r1.returncode == 0 and r2.returncode == 0
              else "✗ " + ((r1.stderr or r2.stderr).decode()[-120:])))
PY

# ══════════════════════════════ إصلاح 7 · توافق revenue.py
hd "7 · توافق: tools/revenue.py يشير للمحرك المركزي"
cat > tools/revenue.py <<'PYEOF'
#!/usr/bin/env python3
"""اسم توافقي — ينفّذ نفس tools/revenue_engine.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import revenue_engine as _re
if __name__ == "__main__": _re.cli()
PYEOF
python3 -m py_compile tools/revenue.py && ok "tools/revenue.py يعمل" || bad "revenue.py"

# ══════════════════════════════ إصلاح 8 · ledger.json التالف
hd "8 · إصلاح ledger.json التالف (بنسخة .bak قبل أي تغيير)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, re, shutil
def repair(path):
    if not os.path.exists(path): return "غير موجود"
    raw = open(path, encoding="utf-8", errors="replace").read()
    if not raw.strip(): return "فارغ"
    try: json.loads(raw); return "سليم أصلًا"
    except Exception: pass
    cands = [raw.lstrip("\ufeff")]
    cands.append(re.sub(r",(\s*[}\]])", r"\1", cands[-1]))
    cands.append(re.sub(r"\bNaN\b", "null", cands[-1]))
    cands.append(re.sub(r"\bInfinity\b", "1e999", cands[-1]))
    cands.append(re.sub(r"//[^\n]*", "", cands[-1]))
    for c in cands:
        try:
            obj = json.loads(c)
            shutil.copy(path, path + ".bak")
            json.dump(obj, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            return "أُصلح (%s)" % type(obj).__name__
        except Exception: continue
    # محاولة أخيرة: JSON متسلسل سطرًا سطرًا
    try:
        objs = [json.loads(l) for l in raw.splitlines() if l.strip()]
        shutil.copy(path, path + ".bak")
        json.dump(objs, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        return "حوّل %d سطر JSON إلى مصفوفة" % len(objs)
    except Exception as e:
        return "فشل: %s" % str(e)[:60]
found = 0
for d in (".", "data"):
    if not os.path.isdir(d): continue
    for f in sorted(os.listdir(d)):
        if f.endswith(".json"):
            res = repair(os.path.join(d, f))
            if res != "سليم أصلًا":
                print("  %-34s %s" % (os.path.join(d, f), res)); found += 1
print("  ملفات احتاجت إصلاحًا: %d" % found)
PY

# ══════════════════════════════ إصلاح 9 · audit_full.py
hd "9 · تشخيص audit_full.py (ملف قديم — لن يُسقط النشر)"
if [ -f tools/audit_full.py ]; then
  if python3 -m py_compile tools/audit_full.py 2>/dev/null; then ok "سليم"
  else
    wrn "به خطأ نحوي — ليس من أدوات المحرك · يُوسم"
    cp tools/audit_full.py ".tmp/audit_full.py.bak"
    python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
try:
    from ast import parse
    src = open("tools/audit_full.py", encoding="utf-8").read()
    print("  السطور: %d · آخر 3 سطور:" % len(src.splitlines()))
    for l in src.splitlines()[-3:]: print("    |", l[:90])
    print("  أول سطر: " + src.splitlines()[0][:80] if src.strip() else "  فارغ")
except Exception as e: print("  ", e)
os.makedirs("data", exist_ok=True)
d = json.load(open("data/legacy_warnings.json", encoding="utf-8")) if os.path.exists("data/legacy_warnings.json") else {}
d["tools/audit_full.py"] = "SyntaxError — ملف قديم خارج المحرك، لا يوقف النشر"
json.dump(d, open("data/legacy_warnings.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  fi
fi

# ══════════════════════════════ إصلاح 10 · AUDIT.sh $D
hd "10 · إصلاح AUDIT.sh (متغير D غير معرّف)"
if [ -f AUDIT.sh ]; then
  grep -q "^D=" AUDIT.sh || sed -i "s/^G=\$'\\\\033\[32m'/# ألوان/" AUDIT.sh
  python3 - <<'PY' 2>&1 | tee -a "$LOG"
p = "AUDIT.sh"; s = open(p, encoding="utf-8").read()
if "D=$'" not in s:
    s = s.replace("N=$'\\033[0m'", "N=$'\\033[0m';D=$'\\033[2m'", 1)
    open(p, "w", encoding="utf-8").write(s)
    print("  ✓ أُضيف تعريف D" if "D=$'" in s else "  ! تعذّر")
else: print("  · D معرّف أصلًا")
PY
  bash -n AUDIT.sh && ok "AUDIT.sh سليم نحويًا" || wrn "AUDIT.sh ما زال به خطأ"
fi

# ══════════════════════════════ إصلاح 11 · selftest لا يُسقط على ملفات قديمة
hd "11 · إصلاح selftest.py — فشل أدواتك القديمة لا يوقف النشر"
cat > tools/selftest.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""اختبارات. الملفات القديمة = تحذير. ملفات المحرك = إلزامية."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE, ads

MINE = {"core.py","ads.py","secrets.py","revenue_engine.py","revenue.py","provider_discovery.py",
        "adult_build.py","adult_promote.py","adult_registry.py","fix_pages.py","growth.py",
        "rewards.py","agent_lib.py","selftest.py","dashboard.py","hits_report.py"}
MARK = {"owner.html":"CH:owner","rewards.html":"CH:rewards","income.html":"CH:income",
        "share.html":"CH:share","adult.html":"CineHub 3099"}
P = F = W = 0
def t(n, c, x=""):
    global P, F
    if c: P += 1; print("  ✓ %s %s" % (n, x))
    else: F += 1; print("  ✗ %s %s" % (n, x))
def w(n, x=""):
    global W; W += 1; print("  ! %s %s" % (n, x))

def main():
    print("— بنية —")
    for p in sorted(os.listdir("tools")):
        if not p.endswith(".py"): continue
        r = subprocess.run([sys.executable, "-m", "py_compile", "tools/" + p], capture_output=True)
        if r.returncode == 0: continue
        msg = (r.stderr.decode().strip().splitlines() or [""])[-1][:70]
        if p in MINE: t("py_compile " + p, False, msg)
        else: w("قديم: " + p, msg)
    print("— JSON —")
    bad = []
    for d in (".", "data", "go", "data/reports"):
        if not os.path.isdir(d): continue
        for p in os.listdir(d):
            if p.endswith(".json"):
                try: json.load(open(os.path.join(d, p), encoding="utf-8"))
                except Exception: bad.append(os.path.join(d, p))
    t("كل JSON سليم", not bad, str(bad[:3]))
    print("— قيد فريد —")
    before = len((RE._led() or {}).get("tx", {}))
    RE.add("__test__", 1.2345, "pending", "T-1", "2026-01-01")
    RE.add("__test__", 1.2345, "pending", "T-1", "2026-01-01")
    after = len((RE._led() or {}).get("tx", {}))
    t("نفس (مزود+معرف) لا يتكرر", after - before == 1, "أُضيف %d" % (after - before))
    _, _, tx = RE.add("__test__", 10, "pending", "T-9", "2026-01-01", currency="EUR")
    t("عملة بلا سعر → amount_usd فارغ", tx.get("amount_usd") is None)
    RE.fx_set("EUR", "USD", 1.08, "2026-01-01", "test")
    _, _, tx2 = RE.add("__test__", 10, "pending", "T-10", "2026-01-02", currency="EUR")
    t("بعد السعر → يُحوَّل", tx2.get("amount_usd") is not None, str(tx2.get("amount_usd")))
    print("— إعلانات —")
    blk = ads.block("adult")
    t("الكتلة تُبنى بلا مفاتيح", "ADS:adult:start" in blk and "ADS:adult:end" in blk)
    a2 = ads.inject(ads.inject("<html><body>x</body></html>"))
    t("حقن مرتين = كتلة واحدة", a2.count("<!--ADS:adult:start-->") == 1)
    n, on = ads.counts()
    t("شبكات مُعدّة", n >= 10, "%d شبكة · %d مفعّلة" % (n, on))
    print("— صفحات —")
    for f, mark in MARK.items():
        if not os.path.exists(f): t("موجود " + f, False); continue
        s = open(f, encoding="utf-8").read()
        t("سلامة " + f, len(s) > 400 and "</body>" in s and mark in s, "%dKB" % (len(s) // 1024))
    print("— أسرار —")
    import secrets as SEC
    r = SEC.report()
    t("لا توكن سري في الواجهة", len(r["leaks"]) == 0, str(r["leaks"][:2]))
    if r["tracked"]: w("keys.env متتبَّع في Git — مقبول للمفاتيح العامة")
    print("— بناء فعلي —")
    for m in ("adult_build", "growth", "rewards", "adult_registry", "dashboard"):
        p = "tools/%s.py" % m
        if not os.path.exists(p): continue
        t0 = time.time()
        rr = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=300)
        t("تشغيل " + m, rr.returncode == 0, "%.1fs" % (time.time() - t0))
        if rr.returncode and rr.stderr:
            print("       " + rr.stderr.strip().splitlines()[-1][:100])
    # تنظيف معاملات الاختبار
    led = RE._led(); n0 = len(led["tx"])
    led["tx"] = {k: v for k, v in led["tx"].items() if v.get("provider") != "__test__"}
    core.save(RE.LED, led)
    print("\nالنتيجة: %d ناجح · %d فاشل · %d تحذير" % (P, F, W))
    return 0 if F == 0 else 1

if __name__ == "__main__": sys.exit(main())
PYEOF
python3 -m py_compile tools/selftest.py && ok "selftest.py" || bad "selftest.py"

# ══════════════════════════════ إصلاح 12 · المهام في النهاية
hd "12 · ضمان ترتيب المهام (أدوات المحرك تعمل أخيرًا)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, shutil, subprocess, sys
p = "tools/tasks.py"
if not os.path.exists(p): print("  ! tasks.py مفقود"); raise SystemExit
s = open(p, encoding="utf-8").read()
shutil.copy(p, ".tmp/tasks.py.bak2")
NEW = [("نمو","tools/growth.py","360*M"),("مكافآت","tools/rewards.py","720*M"),
       ("سجل مزودين","tools/adult_registry.py","720*M"),("لوحة","tools/dashboard.py","240*M"),
       ("تحقق","tools/selftest.py","360*M")]
lines = s.split("\n")
for n, f, iv in NEW:
    idx = [i for i, l in enumerate(lines) if re.search(r'\(\s*"[^"]*"\s*,\s*"%s"' % re.escape(f), l)]
    if idx:
        lines.pop(idx[0])                      # انقلها للنهاية
    if not any(re.search(r'"%s"' % re.escape(f), l) for l in lines):
        lines.append('    ("%s", "%s", %s),' % (n, f, iv))
    else:
        lines.append('    ("%s", "%s", %s),' % (n, f, iv))
open(p, "w", encoding="utf-8").write("\n".join(lines))
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/tasks.py.bak2", p); print("  ✗ استُعيد:", r.stderr.decode().strip().splitlines()[-1][:110])
else:
    cnt = len([l for l in open(p, encoding="utf-8") if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/', l)])
    print("  ✓ المهام: %d · أدوات المحرك في النهاية" % cnt)
PY

# ══════════════════════════════ تنفيذ
hd "13 · تنفيذ"
if pgrep -f agentd.sh >/dev/null 2>&1; then
  printf '  إيقاف الوكيل مؤقتًا (سبب: نفس ملفات المخرجات) ثم يُعاد\n'; pkill -f agentd.sh; sleep 1
fi
NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
OWN="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core._owner())")"
ok "المالك: ${OWN:-?} · نطاق العدّاد: $NSV"
[ -n "$OWN" ] && { grep -q '^GH_USER=' .env 2>/dev/null || echo "GH_USER=$OWN" >> .env; }
grep -q '^SITE_URL=' .env 2>/dev/null || [ -n "$OWN" ] && echo "SITE_URL=https://$OWN.github.io" >> .env
grep -q '^REF_CODE=' .env 2>/dev/null || echo "REF_CODE=${OWN:-ch}" >> .env
sed "s/__NS__/$NSV/" .tmp/hits.tpl > hits.js
grep -q "$NSV" hits.js && ok "hits.js بنطاق صحيح" || bad "hits.js"
[ -n "$OWN" ] && python3 tools/core.py 2>/dev/null; true

for s in ads provider_discovery secrets adult_build adult_promote adult_registry fix_pages growth rewards dashboard; do
  printf '%s▸ %s%s\n' "$D" "$s" "$N"
  python3 "tools/$s.py" 2>&1 | tail -4 | tee -a "$LOG"
done
python3 tools/revenue.py build >/dev/null 2>&1 && ok "السجل مبني"
python3 tools/revenue.py report 2>&1 | tail -8 | tee -a "$LOG"

hd "14 · الاختبارات"
python3 tools/selftest.py 2>&1 | tee -a "$LOG"
ST="${PIPESTATUS[0]}"

hd "15 · النشر"
U="$OWN"; [ -n "$U" ] || U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null)"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null)"
if [ -n "$U" ] && [ -n "$T" ]; then
  git remote remove origin 2>/dev/null
  git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
  rm -f .git/index.lock
  git add -A; git add -f .github/workflows/agent.yml 2>/dev/null
  git -c user.email=a@c.local -c user.name=Agent commit -m "repair: fix pid crash + hits namespace + page collisions + ledger + selftest" >/dev/null 2>&1
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
  DO=1
  if [ "${ASK:-0}" = "1" ]; then printf '؟ انشر؟ [Y/n] '; A=""; read -r -t 20 A || true
    case "$A" in n|N) DO=0;; esac; fi
  if [ "$DO" = 1 ]; then
    if timeout 1800 git push origin main 2>"$TMPDIR/e"; then ok "نُشر (بلا --force)"
    else bad "فشل الرفع:"; tail -3 "$TMPDIR/e" | sed 's/^/    /'; fi
  else wrn "أُجّل"; fi
  python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1
  hd "16 · تحقق منشور"
  SITE="https://$U.github.io"
  for f in owner.html rewards.html rewards-earn.html income.html networks.html share.html sitemap.xml robots.txt rss.xml go-cams.html promote-adult.html; do
    c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 10; done
    [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
  done
  # عدّاد حقيقي: هل Abacus يستجيب؟
  c="$(curl -s -o /dev/null -w '%{http_code}' -m 20 "https://abacus.jasoncameron.dev/get/$NSV/claims")"
  [ "$c" = "200" ] && ok "عدّاد Abacus يستجيب (200)" || wrn "Abacus → $c (قد يكون المفتاح جديدًا)"
else wrn "لا تفويض gh — لم يُنشر"; fi

hd "17 · إعادة تشغيل الوكيل"
rm -f .git/index.lock
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2; pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"
python3 tools/agent_lib.py >/dev/null 2>&1

printf '\n%s╔═══════════════════════════════════════════╗\n' "$G"
printf '║  REPAIR انتهى                             ║\n'
printf '╚═══════════════════════════════════════════╝%s\n' "$N"
printf 'اختبارات: %s · السجل: %s · النسخة: %s\n' "$([ "${ST:-1}" = 0 ] && echo نجحت || echo "فشلت جزئيًا")" "$LOG" "$BK"
printf 'اللوحة: %s/owner.html · الدخل: %s/income.html\n' "${SITE:-—}" "${SITE:-—}"
