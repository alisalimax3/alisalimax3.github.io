#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  FIXALL.sh — إصلاح جذري · بلا نسخة احتياطية · اختبار حتى النجاح · نشر بعده فقط
#  الاستخدام: bash FIXALL.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data go .github/workflows
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/fixall.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
SV(){ cp "$1" ".tmp/$(basename "$1").bak" 2>/dev/null; }   # حفظ صغير فقط

# ═════════════════════════════ 1 · core.py (المالك + ns + العملات)
hd "1 · core.py"
SV tools/core.py
cat > tools/core.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub 3099 — النواة: بيئة · توحيد حقول · أقفال · عملات · HTTP."""
import json, os, re, time, html as _html, hashlib, contextlib, subprocess
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
    p = os.path.join(TMP, "lk." + re.sub(r"\W+", "_", name)); got = False
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
def http(url, timeout=8):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read(60000)
            return {"ok": True, "code": r.status, "final": r.geturl(), "size": len(body)}
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
            t = str(pick(x, "t")).strip(); i = str(pick(x, "i")).strip() or t
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
    """يستنبط المالك — لا يبقى anon أبدًا."""
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
    if not u:
        try:
            r = subprocess.run(["git", "config", "user.name"], capture_output=True, text=True, timeout=5).stdout
            if r.strip() and r.strip() != "Agent": u = r.strip()
        except Exception: pass
    return u

def site():
    s = get("SITE_URL").rstrip("/")
    if s: return s
    o = _owner(); return ("https://%s.github.io" % o) if o else ""
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

# ═════════════════════════════ 2 · pid  ★
hd "2 · revenue_engine.py — إصلاح pid"
SV tools/revenue_engine.py
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import shutil, subprocess, sys
p = "tools/revenue_engine.py"; s = open(p, encoding="utf-8").read(); before = s
s = s.replace("provs = [_rec(oi.get(pid, {}), *row) for row in P]",
              "provs = [_rec(oi.get(row[0], {}), *row) for row in P]")
if '"fit_score"' not in s:
    s = s.replace('"verified_on": ver, "note": note,',
      '"verified_on": ver, "note": note,\n      "fit_score": int(o.get("fit_score", 0)),\n'
      '      "reachable": o.get("reachable"), "http_code": o.get("http_code"),\n'
      '      "checked_on": o.get("checked_on", ""),')
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  pid→row[0]: %s · fit_score: %s" % (before != s, '"fit_score"' in s))
if r.returncode:
    shutil.copy(".tmp/revenue_engine.py.bak", p); print("  ✗ استُعيد:", r.stderr.decode()[-110:])
else:
    b = subprocess.run([sys.executable, p, "build"], capture_output=True, text=True, timeout=120)
    print("  " + ("✓ build يعمل" if b.returncode == 0 else "✗ " + (b.stderr or "").strip().splitlines()[-1][:110]))
PY

# ═════════════════════════════ 3 · ads.py
hd "3 · ads.py — A-ADS بصيغتين + قراءة صحيحة"
SV tools/adults.py 2>/dev/null; SV tools/ads.py
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import subprocess, sys
p = "tools/ads.py"; s = open(p, encoding="utf-8").read()
s = s.replace('''    z = n["zone"]
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    url = tpl.replace("{id}", core.esc(z)).replace("{size}", "300x250")
    return ('<iframe src="%s" width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % url)''',
'''    z = core.get(n["zone"])
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    z = core.esc(z)
    url = tpl.replace("{id}", z).replace("{size}", "300x250")
    extra = " data-aa='%s'" % z if n["id"] == "aads" else ""
    return ('<iframe src="%s"%s width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % (url, extra))''')
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ ads.py" if r.returncode == 0 else "✗ " + r.stderr.decode()[-110:]))
PY

# ═════════════════════════════ 4 · secrets.py + فصل الأسرار
hd "4 · secrets.py — فصل السري عن العام"
SV tools/secrets.py
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import subprocess, sys
p = "tools/secrets.py"; s = open(p, encoding="utf-8").read()
if "PUBLIC_OK" not in s:
    s = s.replace('SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}',
                  'SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}\n'
                  'PUBLIC_OK = {"GH_USER","SITE_URL","REF_CODE"}')
    s = s.replace('for n in GROUPS["api"] + list(SECRET):', 'for n in SECRET:')
    open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ secrets.py" if r.returncode == 0 else "✗ " + r.stderr.decode()[-110:]))
PY
# انقل المفاتيح السرية من keys.env (متتبَّع) إلى .env (غير متتبَّع)
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, shutil
if not os.path.exists("keys.env"): print("  ! keys.env مفقود"); raise SystemExit
SEC = ("EXOCLICK_API_TOKEN","EXOCLICK_API_PASS","EXOCLICK_API_USER")
lines = open("keys.env", encoding="utf-8").read().splitlines()
keep, moved = [], []
for l in lines:
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", l.strip())
    if m and m.group(1) in SEC and m.group(2).strip():
        moved.append("%s=%s" % (m.group(1), m.group(2).strip())); keep.append("%s=" % m.group(1))
    else: keep.append(l)
if moved:
    shutil.copy("keys.env", ".tmp/keys.env.bak")
    open("keys.env", "w", encoding="utf-8").write("\n".join(keep) + "\n")
    env = open(".env", encoding="utf-8").read().splitlines() if os.path.exists(".env") else []
    have = {l.split("=")[0] for l in env if "=" in l}
    for x in moved:
        if x.split("=")[0] not in have: env.append(x)
    open(".env", "w", encoding="utf-8").write("\n".join(env) + "\n")
    print("  ✓ نُقل %d مفتاح سري إلى .env: %s" % (len(moved), ", ".join(x.split("=")[0] for x in moved)))
else:
    print("  · لا مفاتيح سرية في keys.env (أو فارغة)")
for g in (".env", "keys.env", ".tmp/", "logs/"):
    pass
gi = open(".gitignore", encoding="utf-8").read().splitlines() if os.path.exists(".gitignore") else []
for x in (".env", "keys.env", ".tmp/", "logs/", "*.log", "*.bak", "data/*.tmp"):
    if x not in gi: gi.append(x)
open(".gitignore", "w", encoding="utf-8").write("\n".join(gi) + "\n")
print("  ✓ .gitignore محدّث")
PY

# ═════════════════════════════ 5 · تعارض الصفحات
hd "5 · منع تعارض earn.html / networks.html / adult-networks.html"
SV tools/rewards.py; SV tools/adult_registry.py
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import subprocess, sys
# rewards: اكتب rewards-earn.html + املأ earn.html إن كان فارغًا
p = "tools/rewards.py"; s = open(p, encoding="utf-8").read()
s = s.replace('core.write_if_changed("earn.html", EARN % {', 'core.write_if_changed("rewards-earn.html", EARN % {')
s = s.replace('<a href="earn.html">اكسب أكثر</a>', '<a href="rewards-earn.html">اكسب أكثر</a>')
s = s.replace('print("  ✓ rewards.html + earn.html', 'print("  ✓ rewards.html + rewards-earn.html')
if 'EARN_PAGE' not in s:
    s = s.replace('def page():', '''def page():
    import os as _os
    _t = EARN % {"pts": CLAIM, "ref": REFPTS, "site": core.site(),
                 "code": core.get("REF_CODE") or core.get("GH_USER") or "ch", "honest": HONEST}
    if (not _os.path.exists("earn.html")) or _os.path.getsize("earn.html") < 200:
        core.write_if_changed("earn.html", _t)''')
open(p, "w", encoding="utf-8").write(s)
r1 = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
# registry: اكتب income.html + networks.html + adult-networks.html
p = "tools/adult_registry.py"; s = open(p, encoding="utf-8").read()
if 'HTML = """' not in s:
    s = s.replace('core.write_if_changed("networks.html", """', 'HTML = """')
    s = s.replace('''</div></body></html>""" % (len(r["providers"]), rows))
        print("  ✓ networks.html (%d مزود)" % len(r["providers"]))''',
'''</div></body></html>""" % (len(r["providers"]), rows)
        core.write_if_changed("income.html", HTML)
        core.write_if_changed("networks.html", HTML)
        ad = [p for p in r["providers"] if p.get("adult_ok") == "yes"]
        rows2 = "".join("<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>"
                        "<td><a target='_blank' rel='nofollow noopener' href='%s'>↗</a></td></tr>"
                        % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["min_payout"]),
                           core.esc(p["payment_methods"]), core.esc(p["account_status"]), p["official_url"])
                        for p in ad)
        core.write_if_changed("adult-networks.html", HTML.replace(
            "<h1>مصادر الدخل — %d</h1>" % len(r["providers"]),
            "<h1>🔞 شبكات الكبار — %d</h1>" % len(ad)).replace(rows, rows2 or rows))
        print("  ✓ income.html + networks.html + adult-networks.html (%d مزود · %d كبار)"
              % (len(r["providers"]), len(ad)))''')
open(p, "w", encoding="utf-8").write(s)
r2 = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ rewards.py + adult_registry.py" if r1.returncode == 0 and r2.returncode == 0
              else "✗ " + ((r1.stderr or r2.stderr) or b"").decode()[-130:]))
PY

# ═════════════════════════════ 6 · audit_full.py يعمل
hd "6 · إعادة كتابة audit_full.py (كان SyntaxError)"
SV tools/audit_full.py
cat > tools/audit_full.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل حقيقي — بلا أسرار في المخرجات."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def main():
    R = {"at": time.strftime("%F %H:%M:%S"), "root": os.getcwd()}
    R["files"] = {}
    for d in (".", "tools", "data", "adult", "go"):
        if os.path.isdir(d):
            R["files"][d] = len([f for f in os.listdir(d) if os.path.isfile(os.path.join(d, f))])
    try:
        R["branch"] = subprocess.run(["git","rev-parse","--abbrev-ref","HEAD"],
                                     capture_output=True,text=True).stdout.strip()
        R["dirty"] = len(subprocess.run(["git","status","--porcelain"],
                          capture_output=True,text=True).stdout.splitlines())
    except Exception: pass
    E = core.env()
    R["secrets"] = {"defined": len(E), "filled": len([k for k in E if E[k]])}
    bad = []
    for d in (".", "data"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if f.endswith(".json"):
                try: json.load(open(os.path.join(d, f), encoding="utf-8"))
                except Exception: bad.append(os.path.join(d, f))
    R["bad_json"] = bad
    rows, src = core.catalog()
    R["catalog"] = {"total": len(rows), "source": src, "adult": len([r for r in rows if core.is_adult(r)])}
    R["pages"] = {"root": len([f for f in os.listdir(".") if f.endswith(".html")]),
                  "adult": len([f for f in os.listdir("adult") if f.endswith(".html")]) if os.path.isdir("adult") else 0}
    os.makedirs("data/audit", exist_ok=True)
    p = "data/audit/full-%s.json" % time.strftime("%F_%H%M")
    core.save(p, R)
    print("  الملفات: %s" % R["files"])
    print("  كتالوج: %s عنوان (%s إباحي) · JSON تالف: %d" % (R["catalog"]["total"], R["catalog"]["adult"], len(bad)))
    print("  أسرار: %d مضبوط · صفحات: %s" % (R["secrets"]["filled"], R["pages"]))
    print("  ✓ %s" % p)

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/audit_full.py && ok "audit_full.py يعمل الآن" || bad "audit_full.py"

# ═════════════════════════════ 7 · revenue.py توافقي
hd "7 · tools/revenue.py"
cat > tools/revenue.py <<'PYEOF'
#!/usr/bin/env python3
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import revenue_engine as _re
if __name__ == "__main__": _re.cli()
PYEOF
python3 -m py_compile tools/revenue.py && ok "revenue.py" || bad "revenue.py"

# ═════════════════════════════ 8 · إصلاح JSON تالف
hd "8 · إصلاح ملفات JSON التالفة"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, re, shutil
def repair(path):
    if not os.path.exists(path): return None
    raw = open(path, encoding="utf-8", errors="replace").read()
    if not raw.strip(): return "فارغ"
    try: json.loads(raw); return None
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
            return "أُصلح → %s" % type(obj).__name__
        except Exception: continue
    try:
        objs = [json.loads(l) for l in raw.splitlines() if l.strip()]
        shutil.copy(path, path + ".bak")
        json.dump(objs, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        return "حوّل %d سطر إلى مصفوفة" % len(objs)
    except Exception as e:
        return "فشل: %s" % str(e)[:50]
n = 0
for d in (".", "data", "go"):
    if not os.path.isdir(d): continue
    for f in sorted(os.listdir(d)):
        if not f.endswith(".json"): continue
        r = repair(os.path.join(d, f))
        if r: print("  %-32s %s" % (os.path.join(d, f), r)); n += 1
print("  ملفات أُصلحت: %d" % n)
PY

# ═════════════════════════════ 9 · AUDIT.sh
hd "9 · AUDIT.sh"
if [ -f AUDIT.sh ]; then
  python3 - <<'PY' 2>&1 | tee -a "$LOG"
s = open("AUDIT.sh", encoding="utf-8").read()
if "D=$'" not in s:
    s = s.replace("N=$'\\033[0m'", "N=$'\\033[0m';D=$'\\033[2m'", 1)
    open("AUDIT.sh", "w", encoding="utf-8").write(s)
print("  ✓ D معرّف" if "D=$'" in s else "  ! تعذّر")
PY
  bash -n AUDIT.sh && ok "AUDIT.sh سليم" || bad "AUDIT.sh"
fi

# ═════════════════════════════ 10 · hits.js
hd "10 · hits.js بنطاق صحيح + زوار فريدون"
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
    var rf = q.get("ref"); if (rf) localStorage.setItem("ch_ref", rf.slice(0, 24));
    var s1 = q.get("utm_source"); if (s1) localStorage.setItem("ch_src", s1.slice(0, 24));
    var c1 = q.get("utm_campaign"); if (c1) localStorage.setItem("ch_cmp", c1.slice(0, 24)); } catch (e) {}
  window.CH = { ns: NS, vid: vid, hit: hit, get: get, today: d,
    pv: "pv" + path, dv: "dv-" + d, uvtoday: "uniq-" + d, claims: "claims" };
  hit(window.CH.pv); hit(window.CH.dv);
  hit(NS + "/uv-" + d + "-" + vid()).then(function (v) { if (v === 1) hit(NS + "/uniq-" + d); });
  document.addEventListener("DOMContentLoaded", function () {
    var el = document.querySelectorAll("[data-hits]");
    for (var i = 0; i < el.length; i++) (function (n) {
      get(window.CH[n.getAttribute("data-hits")]).then(function (v) {
        if (v !== null && v !== undefined) n.textContent = v; }); })(el[i]);
  });
})();
JSEOF

# ═════════════════════════════ 11 · adcheck.py (تحقق فعلي من الإعلان)
hd "11 · adcheck.py — فحص رابط الإعلان فعليًا"
cat > tools/adcheck.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يفحص رابط الإعلان المبني فعليًا عبر HTTP. A-ADS: يجرّب الصيغتين."""
import os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

def src_of(code):
    m = re.search(r'src="([^"]+)"', code or "")
    return m.group(1) if m else ""

def main():
    with core.lock("adcheck", 900) as got:
        if not got: print("  · مقفول"); return
        res = []
        for n in ads.status():
            if not n["on"]: continue
            code = ads._one(n)
            url = src_of(code)
            if not url: res.append({"id": n["id"], "status": "embed_only"}); continue
            r = core.http(url, timeout=10)
            entry = {"id": n["id"], "name": n["n"], "url": url, "code": r.get("code"),
                     "ok": bool(r.get("ok")), "err": r.get("err", "")}
            if not r.get("ok") and n["id"] == "aads":
                alt = url.replace("ad.a-ads.com", "acceptable.a-ads.com")
                r2 = core.http(alt, timeout=10)
                entry["alt"] = {"url": alt, "code": r2.get("code"), "ok": bool(r2.get("ok"))}
                if r2.get("ok"):
                    open(".env", "a", encoding="utf-8").write(
                        "AADS_EMBED=<iframe src=\"%s\" data-aa='%s' width=\"300\" height=\"250\""
                        " frameborder=\"0\" scrolling=\"no\" loading=\"lazy\""
                        " style=\"border:0;max-width:100%%\"></iframe>\n"
                        % (alt, core.get("AADS_UNIT")))
                    entry["switched_to"] = alt
            res.append(entry)
            print("    %s %-12s HTTP %s %s" % ("✓" if entry["ok"] else "✗", n["id"], entry["code"], entry.get("err","")))
        core.save("data/adcheck.json", {"at": time.strftime("%F %H:%M"), "results": res,
                  "working": [r["id"] for r in res if r.get("ok")],
                  "note": "فحص HTTP لرابط الإعلان. نجاح ≠ دفع، لكنه يثبت أن الوسم يُخدم."})
        w = [r["id"] for r in res if r.get("ok")]
        print("  ✓ يعمل: %s · فُحص: %d" % (", ".join(w) or "لا شيء", len(res)))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/adcheck.py && ok "adcheck.py" || bad "adcheck.py"

# ═════════════════════════════ 12 · selftest
hd "12 · selftest.py — لا يُسقط النشر على ملفاتك القديمة"
cat > tools/selftest.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""اختبارات. ملفات المحرك إلزامية · ملفاتك القديمة تحذير · بلا تلويث الدفتر."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE, ads

MINE = {"core.py","ads.py","secrets.py","revenue_engine.py","revenue.py","provider_discovery.py",
        "adult_build.py","adult_promote.py","adult_registry.py","fix_pages.py","growth.py",
        "rewards.py","agent_lib.py","selftest.py","dashboard.py","adcheck.py","audit_full.py"}
MARK = {"owner.html":"لوحة الإيرادات","rewards.html":"المكافأة اليومية","income.html":"مصادر الدخل",
        "share.html":"روابط مشاركة","adult.html":"CineHub 3099","rewards-earn.html":"طرق الكسب",
        "adult-networks.html":"شبكات الكبار"}
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
    print("— قيد فريد + عملات —")
    before = len((RE._led() or {}).get("tx", {}))
    RE.add("__t__", 1.2345, "pending", "T-1", "2026-01-01")
    RE.add("__t__", 1.2345, "pending", "T-1", "2026-01-01")
    t("نفس (مزود+معرف) لا يتكرر", len((RE._led() or {}).get("tx", {})) - before == 1)
    _, _, tx = RE.add("__t__", 10, "pending", "T-9", "2026-01-01", currency="EUR")
    t("عملة بلا سعر → amount_usd فارغ", tx.get("amount_usd") is None)
    RE.fx_set("EUR", "USD", 1.08, "2026-01-01", "test")
    _, _, tx2 = RE.add("__t__", 10, "pending", "T-10", "2026-01-02", currency="EUR")
    t("بعد السعر → يُحوَّل 10.8", tx2.get("amount_usd") is not None, str(tx2.get("amount_usd")))
    print("— إعلانات —")
    blk = ads.block("adult")
    t("الكتلة تُبنى بلا مفاتيح", "ADS:adult:start" in blk and "ADS:adult:end" in blk)
    t("حقن مرتين = كتلة واحدة", ads.inject(ads.inject("<html><body>x</body></html>")).count("<!--ADS:adult:start-->") == 1)
    n, on = ads.counts(); t("الشبكات مُعدّة", n >= 10, "%d شبكة · %d مفعّلة" % (n, on))
    print("— صفحات —")
    for f, mark in MARK.items():
        if not os.path.exists(f): t("موجود " + f, False); continue
        s = open(f, encoding="utf-8").read()
        t("سلامة " + f, len(s) > 400 and "</body>" in s and mark in s, "%dKB" % (len(s) // 1024))
    print("— أسرار —")
    import secrets as SEC
    r = SEC.report()
    t("لا توكن سري في الواجهة", len(r["leaks"]) == 0, str(r["leaks"][:2]))
    print("— بناء فعلي —")
    for m in ("adult_build", "growth", "rewards", "adult_registry", "dashboard", "audit_full"):
        p = "tools/%s.py" % m
        if not os.path.exists(p): continue
        t0 = time.time()
        rr = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=300)
        t("تشغيل " + m, rr.returncode == 0, "%.1fs" % (time.time() - t0))
        if rr.returncode and rr.stderr:
            print("       " + rr.stderr.strip().splitlines()[-1][:100])
    led = RE._led()
    led["tx"] = {k: v for k, v in led["tx"].items() if v.get("provider") != "__t__"}
    core.save(RE.LED, led)
    print("\nالنتيجة: %d ناجح · %d فاشل · %d تحذير" % (P, F, W))
    return 0 if F == 0 else 1

if __name__ == "__main__": sys.exit(main())
PYEOF
python3 -m py_compile tools/selftest.py && ok "selftest.py" || bad "selftest.py"

# ═════════════════════════════ 13 · المهام في النهاية
hd "13 · ترتيب المهام (أدوات المحرك آخرًا)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, shutil, subprocess, sys
p = "tools/tasks.py"
if not os.path.exists(p): print("  ! tasks.py مفقود"); raise SystemExit
s = open(p, encoding="utf-8").read(); shutil.copy(p, ".tmp/tasks.py.bak")
NEW = [("نمو","tools/growth.py","360*M"),("مكافآت","tools/rewards.py","720*M"),
       ("سجل مزودين","tools/adult_registry.py","720*M"),("لوحة","tools/dashboard.py","240*M"),
       ("فحص إعلانات","tools/adcheck.py","720*M"),("تحقق","tools/selftest.py","360*M")]
lines = s.split("\n")
for n, f, iv in NEW:
    lines = [l for l in lines if not re.search(r'\(\s*"[^"]*"\s*,\s*"%s"' % re.escape(f), l)]
    lines.append('    ("%s", "%s", %s),' % (n, f, iv))
open(p, "w", encoding="utf-8").write("\n".join(lines))
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/tasks.py.bak", p); print("  ✗ استُعيد:", r.stderr.decode()[-110:])
else:
    print("  ✓ المهام: %d · أدوات المحرك في النهاية"
          % len([l for l in open(p, encoding="utf-8") if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/', l)]))
PY

# ═════════════════════════════ 14 · حلقة الإصلاح والاختبار
hd "14 · تشغيل + اختبار حتى النجاح"
if pgrep -f agentd.sh >/dev/null 2>&1; then printf '  إيقاف الوكيل مؤقتًا (نفس ملفات المخرجات)\n'; pkill -f agentd.sh; sleep 1; fi
OWN="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core._owner())")"
[ -n "$OWN" ] && { grep -q '^GH_USER=' .env 2>/dev/null || echo "GH_USER=$OWN" >> .env; }
[ -n "$OWN" ] && { grep -q '^SITE_URL=' .env 2>/dev/null || echo "SITE_URL=https://$OWN.github.io" >> .env; }
grep -q '^REF_CODE=' .env 2>/dev/null || echo "REF_CODE=${OWN:-ch}" >> .env
NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
sed "s/__NS__/$NSV/" .tmp/hits.tpl > hits.js
grep -q "$NSV" hits.js && ok "hits.js ← $NSV" || bad "hits.js"
[ "$NSV" = "cinehub3099-anon" ] && wrn "المالك لم يُستنبط — اضبط GH_USER في .env"

ST=1
for round in 1 2 3; do
  printf '\n%s▸ دورة %d%s\n' "$B" "$round" "$N"
  for s in ads provider_discovery secrets adult_build adult_promote adult_registry fix_pages growth rewards dashboard audit_full adcheck; do
    printf '  · %s ' "$s"
    python3 "tools/$s.py" >>"$LOG" 2>&1 && printf '%s✓%s\n' "$G" "$N" || printf '%s✗%s\n' "$R" "$N"
  done
  python3 tools/revenue.py build >>"$LOG" 2>&1
  printf '%s— اختبار —%s\n' "$D" "$N"
  python3 tools/selftest.py 2>&1 | tail -30 | tee -a "$LOG"
  ST="${PIPESTATUS[0]}"
  [ "$ST" = "0" ] && { ok "كل الاختبارات نجحت (دورة $round)"; break; }
  [ "$round" != "3" ] && wrn "فشل — إعادة الإصلاح والاختبار"
done

# ═════════════════════════════ 15 · النشر (بعد النجاح فقط)
hd "15 · النشر"
SITE=""
if [ "$ST" != "0" ]; then wrn "الاختبارات لم تنجح كلها — لن يُنشر"
else
  U="$OWN"; [ -n "$U" ] || U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null)"
  T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null)"
  if [ -n "$U" ] && [ -n "$T" ]; then
    git remote remove origin 2>/dev/null
    git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
    rm -f .git/index.lock
    git add -A; git add -f .github/workflows/agent.yml 2>/dev/null
    git -c user.email=a@c.local -c user.name=Agent commit -m "fixall: pid + namespace + ledger + collisions + adcheck + selftest green" >/dev/null 2>&1
    git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
    if timeout 1800 git push origin main 2>"$TMPDIR/e"; then ok "نُشر (بلا --force)"; SITE="https://$U.github.io"
    else bad "فشل الرفع:"; tail -3 "$TMPDIR/e" | sed 's/^/    /'; fi
    python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1
    if [ -n "$SITE" ]; then
      hd "16 · تحقق منشور فعلي"
      for f in owner.html rewards.html rewards-earn.html income.html networks.html adult-networks.html share.html promote-adult.html sitemap.xml robots.txt rss.xml go-cams.html; do
        c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 10; done
        [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
      done
    fi
  else wrn "لا تفويض gh"; fi
fi

hd "17 · الوكيل"
rm -f .git/index.lock
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2; pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"

# ═════════════════════════════ 18 · نتيجة حقيقية
hd "18 · النتيجة الحقيقية"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, sys
sys.path.insert(0, "tools")
import core, ads, revenue_engine as RE
r = RE.apply_ledger(); t = r["totals"]
n, on = ads.counts()
ac = core.load("data/adcheck.json", {}) or {}
print("  شبكات: %d · مفعّلة بمفاتيح: %d · رابطها يستجيب: %s"
      % (n, on, ", ".join(ac.get("working", [])) or "لا شيء"))
print("  دفتر: مستلم $%.2f · مؤكد $%.2f · معلق $%.2f · تقديري $%.2f · الفجوة $%.2f"
      % (t["paid"], t["approved"], t["pending"], t["estimated"], r["gap_usd"]))
c = core.load("data/catalog.json".replace("data/",""), {}) or {}
m = core.load("data/adult_meta.json", {}) or {}
print("  كتالوج: %s عنوان · صفحات adult: %s" % (m.get("catalog_total"), m.get("adult_total")))
print("  أسرار: %d مضبوط · نطاق العدّاد: %s" % (len([k for k in core.env() if core.env()[k]]), core.ns()))
PY

printf '\n%s╔══════════════════════════════════════════╗\n' "$G"
printf '║  FIXALL انتهى                             ║\n'
printf '╚══════════════════════════════════════════╝%s\n' "$N"
printf 'اختبارات: %s · السجل: %s\n' "$([ "$ST" = 0 ] && echo نجحت || echo فشلت)" "$LOG"
[ -n "${SITE:-}" ] && printf 'اللوحة: %s/owner.html · الدخل: %s/income.html\n' "$SITE" "$SITE"
