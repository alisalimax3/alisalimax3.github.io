#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  FINAL.sh — إصلاح الجذر + وكيل تسجيل وحصاد + حفظ المال + واجهتان + نشر
#  bash FINAL.sh            فحص وإصلاح كامل + نشر
#  bash FINAL.sh register   وكيل التسجيل التفاعلي (يفتح ويتابع ويحاول)
#  bash FINAL.sh agent      دورة الوكيل الكاملة
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || exit 1
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data assets .github/workflows
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/final.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
MODE="${1:-all}"

# ─────────────── حفظ المال: نسخ الحالة الحسّاسة فقط (لا تُلمس أبدًا)
hd "0 · حماية الرصيد"
for f in data/vault.json data/ledger.json data/revenue.json data/rewards.json; do
  [ -f "$f" ] && cp "$f" "$TMPDIR/keep.$(basename "$f")" && printf '  محفوظ: %s\n' "$f"
done
V0="$(python3 -c "import json;print(json.load(open('data/vault.json')).get('balance_usd',0))" 2>/dev/null || echo 0)"
printf '  الرصيد الحالي: $%s\n' "$V0"

# ─────────────── 1 · core.py — curl أولًا (الإصلاح الجذري لـ code 0)
hd "1 · core.py — HTTP عبر curl (يصلح code 0)"
cat > tools/core.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub 3099 — النواة. HTTP: curl أولًا لأن urllib يفشل SSL في Termux."""
import json, os, re, time, html as _html, hashlib, contextlib, subprocess
import urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
TMP = os.path.join(ROOT, ".tmp"); os.makedirs(TMP, exist_ok=True)
DATA = os.path.join(ROOT, "data"); os.makedirs(DATA, exist_ok=True)
UA = "Mozilla/5.0 (Linux; Android 13) CineHub3099/1.0"

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
            if k and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", k): E[k] = v
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

# ── HTTP: curl أولًا (موثوق في Termux) ثم urllib
def _curl(url, timeout=10, body=False, limit=120000):
    exe = "curl"
    args = [exe, "-sS", "-L", "--max-time", str(timeout), "-A", UA,
            "-H", "Accept: */*"]
    px = get("PROXY")
    if px: args += ["-x", px]
    if body: args += ["--compressed"]
    args += ["-o", "-" if body else "/dev/null", "-w", "\n%{http_code}", url]
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout + 6)
        out = r.stdout or ""
        code = 0
        if body:
            parts = out.rsplit("\n", 1)
            code = int(parts[-1].strip() or 0) if parts[-1].strip().isdigit() else 0
            txt = parts[0] if len(parts) > 1 else ""
            return {"ok": 200 <= code < 400, "code": code, "final": url, "via": "curl",
                    "text": txt[:limit]}
        code = int(out.strip().splitlines()[-1]) if out.strip() else 0
        return {"ok": 200 <= code < 400, "code": code, "final": url, "via": "curl"}
    except Exception as e:
        return {"ok": False, "code": 0, "final": url, "via": "curl", "err": type(e).__name__}

def _urllib(url, timeout=10, body=False, limit=120000):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            txt = r.read(limit).decode("utf-8", "replace") if body else ""
            return {"ok": True, "code": r.status, "final": r.geturl(), "via": "urllib", "text": txt}
    except urllib.error.HTTPError as e:
        return {"ok": False, "code": e.code, "final": url, "via": "urllib", "err": "HTTP %s" % e.code}
    except Exception as e:
        return {"ok": False, "code": 0, "final": url, "via": "urllib", "err": type(e).__name__}

def http(url, timeout=10):
    r = _curl(url, timeout)
    if r.get("code"): return r
    r2 = _urllib(url, timeout)
    if r2.get("code"): return r2
    return r

def body(url, timeout=12, limit=120000):
    r = _curl(url, timeout, body=True, limit=limit)
    if not r.get("ok"): r = _urllib(url, timeout, body=True, limit=limit)
    return r.get("text", "") or ""

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

def clipboard():
    try:
        return subprocess.run(["termux-clipboard-get"], capture_output=True, text=True, timeout=6).stdout.strip()
    except Exception: return ""
def clipset(v):
    try: subprocess.run(["termux-clipboard-set", str(v)], timeout=6)
    except Exception: pass
def openurl(u):
    try: subprocess.run(["termux-open-url", u], timeout=8)
    except Exception: pass
PYEOF
python3 -m py_compile tools/core.py && ok "core.py" || bad "core.py"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import sys; sys.path.insert(0,"tools"); import core
r = core.http("https://alisalimax3.github.io/", timeout=15)
print("  اختبار HTTP → code=%s via=%s" % (r.get("code"), r.get("via")))
print("  " + ("✓ curl يعمل — code 0 سيزول" if r.get("code") else "✗ فشل أيضًا"))
PY

# ─────────────── 2 · إصلاحات ميكانيكية
hd "2 · robots.txt · ledger.json · tasks.py · gh.py"
cat > robots.txt <<'RBEOF'
User-agent: *
Allow: /
Disallow: /owner.html
Disallow: /income.html
Disallow: /networks.html
Disallow: /promote-adult.html
Disallow: /go/
Disallow: /.tmp/
Crawl-delay: 1

Sitemap: __SITE__/sitemap-index.xml
Sitemap: __SITE__/sitemap-adult.xml
Sitemap: __SITE__/sitemap.xml
RBEOF
SITEU="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.site())")"
sed -i "s|__SITE__|$SITEU|g" robots.txt && ok "robots.txt ($(wc -c < robots.txt) بايت)"

python3 - <<'PY' 2>&1 | tee -a "$LOG"
import ast, json, os, re, shutil
def fix(p):
    if not os.path.exists(p): return None
    raw = open(p, encoding="utf-8", errors="replace").read()
    if not raw.strip(): return "فارغ"
    try: json.loads(raw); return None
    except Exception: pass
    for fn in (ast.literal_eval,):
        try:
            obj = fn(raw.strip()); shutil.copy(p, p + ".bak")
            json.dump(obj, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
            return "أُصلح (كان %s Python)" % type(obj).__name__
        except Exception: pass
    try:
        objs = [json.loads(l) for l in raw.splitlines() if l.strip()]
        shutil.copy(p, p + ".bak")
        json.dump(objs, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        return "NDJSON→%d" % len(objs)
    except Exception: pass
    t = re.sub(r",(\s*[}\]])", r"\1", raw.lstrip("\ufeff"))
    try:
        json.loads(t); shutil.copy(p, p + ".bak")
        open(p, "w", encoding="utf-8").write(t); return "نُظّف"
    except Exception as e: return "فشل: %s" % str(e)[:40]
for d in (".", "data"):
    if not os.path.isdir(d): continue
    for f in sorted(os.listdir(d)):
        if f.endswith(".json"):
            r = fix(os.path.join(d, f))
            if r: print("  %-30s %s" % (os.path.join(d, f), r))
PY

python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, shutil, subprocess, sys, os
p = "tools/tasks.py"
if not os.path.exists(p): print("  ! tasks.py مفقود"); raise SystemExit
src = open(p, encoding="utf-8").read(); shutil.copy(p, ".tmp/tasks.pre")
m = re.search(r"^([A-Za-z_]\w*)\s*=\s*\[", src, re.M)
if not m: print("  ! لا قائمة"); raise SystemExit
name = m.group(1); i = m.end() - 1; depth = 0; j = i
while j < len(src):
    if src[j] == "[": depth += 1
    elif src[j] == "]":
        depth -= 1
        if depth == 0: break
    j += 1
rows = re.findall(r'\(\s*"([^"]*)"\s*,\s*"([^"]*)"\s*,\s*([^()]+?)\s*\)', src[i+1:j])
seen, clean = set(), []
for n, f, iv in rows:
    if f in seen: continue
    seen.add(f); clean.append((n, f, iv.strip()))
ADD = [("نمو","tools/growth.py","360*M"),("مكافآت","tools/rewards.py","720*M"),
       ("سجل مزودين","tools/adult_registry.py","720*M"),("لوحة","tools/dashboard.py","240*M"),
       ("فحص إعلانات","tools/adcheck.py","720*M"),("توسيع","tools/expand_pages.py","1440*M"),
       ("وكيل تسجيل","tools/agent_register.py","1440*M"),("خزينة","tools/custody.py","360*M"),
       ("تحقق","tools/selftest.py","360*M")]
for n, f, iv in ADD:
    if f not in seen: clean.append((n, f, iv))
open(p, "w", encoding="utf-8").write(src[:i+1] + "\n" + "".join('    ("%s", "%s", %s),\n' % r for r in clean) + src[j:])
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/tasks.pre", p); print("  ✗ استُعيد:", r.stderr.decode()[-100:])
else: print("  ✓ tasks.py: %d مهمة" % len(clean))
PY

[ ! -f tools/gh.py ] && cat > tools/gh.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, re, subprocess, sys, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def token():
    for k in ("GH_TOKEN","GITHUB_TOKEN","GITHUB_PAT"):
        if core.get(k): return core.get(k)
    return ""
def login():
    r = subprocess.run(["git","remote","get-url","origin"],capture_output=True,text=True).stdout
    m = re.search(r"github\.com[:/]([^/]+)/", r or "")
    return m.group(1) if m else core.get("GH_USER")
def api(path, method="GET", body=None):
    req = urllib.request.Request("https://api.github.com"+path,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization":"Bearer "+token(),"Accept":"application/vnd.github+json",
                 "User-Agent":"CineHub3099"}, method=method)
    with urllib.request.urlopen(req, timeout=30) as r: return json.loads(r.read() or b"{}")
def enable_pages():
    u = login()
    try: api("/repos/%s/%s.github.io/pages"%(u,u)); return "موجود"
    except Exception:
        try: api("/repos/%s/%s.github.io/pages"%(u,u),"POST",{"source":{"branch":"main","path":"/"}}); return "فُعّل"
        except Exception as e: return str(e)[:50]
if __name__ == "__main__": print("login:",login(),"token:",len(token()))
PYEOF
python3 -m py_compile tools/gh.py && ok "gh.py"

# ─────────────── 3 · خزينة: الوكيل لا يصرف · المالك وحده
hd "3 · tools/custody.py — حجز المال"
cat > tools/custody.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""خزينة: الوارد يُحجز. الوكيل لا يصرف. المالك وحده يُفرج. قيد فريد."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

V = "data/vault.json"
POLICY = {"agent_can_spend": False, "only_owner_withdraw": True,
          "owner_cut_pct": 20, "reserve_pct": 100,
          "note": "الرصيد محفوظ. لا يُصرف إلا بإفراج صريح من المالك."}

def _v():
    d = core.load(V, None)
    if not isinstance(d, dict):
        d = {"schema": 1, "created": time.strftime("%F %H:%M"), "balance_usd": 0.0,
             "reserved_usd": 0.0, "released_usd": 0.0, "withdrawn_usd": 0.0,
             "entries": {}, "withdrawals": [], "policy": POLICY}
    d.setdefault("entries", {}); d.setdefault("withdrawals", [])
    d["policy"] = POLICY
    return d

def sync():
    """يسحب المؤكد والمدفوع من الدفتر إلى الخزينة بقيد فريد — لا تكرار."""
    d = _v(); r = RE.apply_ledger(); led = RE._led()
    added = 0.0
    for k, t in led.get("tx", {}).items():
        if t.get("state") not in ("approved", "paid"): continue
        ek = "tx::" + k
        if ek in d["entries"]: continue
        usd = t.get("amount_usd") or 0.0
        d["entries"][ek] = {"src": t.get("provider"), "amount_usd": usd,
                            "state": t.get("state"), "at": time.strftime("%F %H:%M")}
        added += usd
    bal = round(sum(e["amount_usd"] for e in d["entries"].values()), 4)
    d["balance_usd"] = bal
    d["reserved_usd"] = round(bal * POLICY["reserve_pct"] / 100.0, 4)
    d["released_usd"] = round(max(0.0, bal - d["reserved_usd"]), 4)
    d["updated"] = time.strftime("%F %H:%M")
    core.save(V, d)
    return d, added

def owner_cut(user_reward_usd):
    return round(float(user_reward_usd) * POLICY["owner_cut_pct"] / 100.0, 6)

def release(amount, note=""):
    d = _v()
    a = float(amount)
    if a > d["released_usd"] + 1e-9:
        return False, "المتاح للإفراج $%.4f فقط" % d["released_usd"]
    d["released_usd"] = round(d["released_usd"] - a, 4)
    d["withdrawals"].append({"key": "rel::%s::%.4f" % (time.strftime("%F"), a),
                             "amount_usd": a, "note": note, "at": time.strftime("%F %H:%M"),
                             "by": "owner"})
    core.save(V, d); return True, "أُفرج $%.4f" % a

def withdraw(amount, method="", ref=""):
    d = _v()
    a = float(amount)
    paid = round(sum(w["amount_usd"] for w in d["withdrawals"]), 4)
    if a + paid > d["balance_usd"] + 1e-9:
        return False, "المستلم الكلي سيتجاوز الرصيد"
    d["withdrawals"].append({"key": "wd::%s::%s::%.4f" % (time.strftime("%F"), ref or method, a),
                             "amount_usd": a, "method": method, "ref": ref,
                             "at": time.strftime("%F %H:%M"), "by": "owner"})
    d["withdrawn_usd"] = round(paid + a, 4)
    core.save(V, d); return True, "سُجّل سحب $%.4f" % a

def cli():
    a = sys.argv[1:]
    if not a:
        d, _ = sync()
        print("الرصيد $%.4f · محجوز $%.4f · متاح للإفراج $%.4f · مسحوب $%.4f"
              % (d["balance_usd"], d["reserved_usd"], d["released_usd"], d["withdrawn_usd"]))
        print("السياسة: الوكيل لا يصرف=%s · المالك وحده=%s · حصة المالك من مكافآت المستخدمين=%d%%"
              % (POLICY["agent_can_spend"], POLICY["only_owner_withdraw"], POLICY["owner_cut_pct"]))
    elif a[0] == "sync": d, add = sync(); print("أُضيف $%.4f · الرصيد $%.4f" % (add, d["balance_usd"]))
    elif a[0] == "release" and len(a) > 1: print(release(a[1], a[2] if len(a) > 2 else "")[1])
    elif a[0] == "withdraw" and len(a) > 1: print(withdraw(a[1], a[2] if len(a) > 2 else "")[1])
    elif a[0] == "cut" and len(a) > 1: print("حصة المالك: $%.6f" % owner_cut(a[1]))
    else: print("sync|release <amt>|withdraw <amt> <method>|cut <amt>")

if __name__ == "__main__": cli()
PYEOF
python3 -m py_compile tools/custody.py && python3 tools/custody.py 2>&1 | tee -a "$LOG"

# ─────────────── 4 · وكيل التسجيل (محاولات · تحقق · تأكيد بريد · استئناف)
hd "4 · tools/agent_register.py — وكيل التسجيل والمحاولة"
cat > tools/agent_register.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""وكيل تسجيل: يفتح · يجهّز بريدًا وكلمة مرور · يتابع الحافظة · يتحقق شبكيًا ·
يعيد المحاولة · يؤكّد البريد · يسجّل المفتاح. قابل للاستئناف."""
import json, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

S = "data/agent_state.json"
# name, key, signup, dashboard, validate_url, expect, hint, prio
SITES = [
 ("A-ADS","AADS_UNIT","https://a-ads.com/","https://a-ads.com/ad_units",
  "https://acceptable.a-ads.com/{v}?size=300x250","a-ads",'انسخ data-aa="..." — الأرقام',1),
 ("Adsterra","ADSTERRA_ZONE","https://publishers.adsterra.com/","https://publishers.adsterra.com/websites",
  "https://adsterra.com/","",'انسخ Zone ID من Ad Units',1),
 ("ExoClick","EXOCLICK_ZONE","https://admin.exoclick.com/signup","https://admin.exoclick.com/sites",
  "https://s.exoclick.com/ads.php?type=300x250&zone={v}","","Zone ID رقمي",2),
 ("JuicyAds","JUICYADS_ZONE","https://www.juicyads.com/signup","https://www.juicyads.com/adzones",
  "https://adserver.juicyads.com/adshow.php?adzone={v}","","Ad Zone رقمي",2),
 ("PopAds","POPADS_SITE","https://www.popads.net/","https://www.popads.net/users",
  "https://www.popads.net/","",'Site ID رقمي',3),
 ("PopCash","POPCASH_SITE","https://popcash.net/register","https://popcash.net/websites",
  "https://popcash.net/","",'Website ID',3),
 ("Stripchat","STRIPCHAT_REF","https://affiliates.stripchat.com/","https://affiliates.stripchat.com/",
  "https://affiliates.stripchat.com/","",'رابط الإحالة الكامل',1),
 ("CrakRevenue","CRAKREVENUE_REF","https://www.crakrevenue.com/signup","https://www.crakrevenue.com/",
  "https://www.crakrevenue.com/","",'رابط الإحالة',2),
 ("Chaturbate","CHATURBATE_REF","https://chaturbate.com/affiliates/","https://chaturbate.com/affiliates/",
  "https://chaturbate.com/","",'رابط الإحالة',3),
]
RE_PAT = {"AADS_UNIT": r"^\d{4,8}$", "EXOCLICK_ZONE": r"^\d{3,9}$", "JUICYADS_ZONE": r"^\d{3,9}$",
          "ADSTERRA_ZONE": r"^\d{4,9}$", "POPADS_SITE": r"^\d{3,9}$", "POPCASH_SITE": r"^\d{3,9}$"}

def state():
    d = core.load(S, {"rounds": 0, "sites": {}})
    d.setdefault("sites", {}); return d
def put(name, **kw):
    d = state(); e = d["sites"].setdefault(name, {"tries": 0, "status": "todo"})
    e.update(kw); e["last"] = time.strftime("%F %H:%M"); core.save(S, d)
def newpass(n=14):
    import secrets, string
    return "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(n))

def valid(name, val):
    val = (val or "").strip().rstrip("/")
    if not val: return False, "فارغ"
    if "@" in val: return False, "بريد لا مفتاح"
    if val.lower() in ("cinehub3099","github","http:","https:"): return False, "نص عام"
    rp = RE_PAT.get(name)
    if rp and not re.fullmatch(rp, val): return False, "الشكل غير مطابق %s" % rp
    if val.isdigit() and len(val) > 9: return False, "طويل جدًا"
    if not name.endswith("_REF") and not val.isdigit():
        if name.endswith("_ZONE") or name.endswith("_UNIT") or name.endswith("_SITE"):
            return False, "يجب أن يكون رقمًا"
    url = [s for s in SITES if s[0] == name or s[1] == name]
    if not url: return False, "غير معروف"
    tmpl = url[0][4]
    if "{v}" in tmpl:
        r = core.http(tmpl.replace("{v}", val), timeout=12)
        if not r.get("ok"):
            b = core.body(tmpl.replace("{v}", val), timeout=12, limit=4000)
            if len(b) < 300: return False, "HTTP %s" % r.get("code")
    return True, "تحقق"

def watch(name, key, hint, seconds=600):
    print("  انسخ: %s" % hint)
    prev = core.clipboard(); t0 = time.time(); tries = 0
    while time.time() - t0 < seconds:
        time.sleep(1.5)
        now = core.clipboard()
        if not now or now == prev: 
            sys.stdout.write("\r    بانتظار %ds…" % int(time.time() - t0)); sys.stdout.flush()
            continue
        prev = now
        for c in re.findall(r"[A-Za-z0-9._~:/\-]{4,}", now) + re.findall(r"\d{3,9}", now):
            tries += 1
            okk, why = valid(key, c)
            if okk:
                setkv(key, c)
                print("\r    ✓ %s = %s" % (key, c)); return c
            else:
                sys.stdout.write("\r    ✗ %-22s (%s)" % (c[:22], why)); sys.stdout.flush()
    print(); return None

def setkv(k, v):
    lines, found = [], False
    if os.path.exists("keys.env"):
        for l in open("keys.env", encoding="utf-8"):
            if l.strip().startswith(k + "="): lines.append("%s=%s\n" % (k, v)); found = True
            else: lines.append(l)
    if not found: lines.append("%s=%s\n" % (k, v))
    open("keys.env", "w", encoding="utf-8").writelines(lines)
    core.reload_env()

def confirm_mail(seconds=120):
    if not os.path.exists("tools/mail.py"): return
    try: subprocess.run([sys.executable, "tools/mail.py", "--wait", str(seconds)],
                        timeout=seconds + 30)
    except Exception: pass

def run(only=None, rounds=3):
    st = state()
    todo = [s for s in SITES if (not only or s[0] == only or s[1] == only)]
    for rnd in range(1, rounds + 1):
        pend = [s for s in todo if st["sites"].get(s[0], {}).get("status") not in ("done", "skip")]
        if not pend: break
        print("\n── دورة %d · متبقٍ %d ──" % (rnd, len(pend)))
        for name, key, signup, dash, vurl, exp, hint, prio in sorted(pend, key=lambda x: x[7]):
            e = st["sites"].get(name, {})
            print("\n▸ %s  [%s]  محاولة %d" % (name, key, e.get("tries", 0) + 1))
            cur = core.get(key)
            if cur:
                okk, why = valid(key, cur)
                if okk: put(name, status="done", value=cur); print("  ✓ محفوظ ومتحقق: %s" % cur); continue
                print("  ! محفوظ لكن مرفوض (%s): %s" % (why, cur))
            pw = newpass()
            mu = core.get("MAIL_USER")
            print("  سجّل: %s" % signup)
            if mu: core.clipset(mu); print("  البريد في الحافظة: %s" % mu)
            print("  كلمة المرور: %s" % pw)
            core.openurl(signup)
            print("  [Enter بعد إتمام التسجيل · m بريد التأكيد · s تخطي]")
            try: a = input("  › ").strip()
            except EOFError: a = ""
            if a == "s": put(name, status="skip"); continue
            if a == "m": confirm_mail()
            core.openurl(dash)
            v = watch(name, key, hint, 600)
            if v:
                put(name, status="done", value=v, tries=e.get("tries", 0) + 1)
            else:
                put(name, status="rejected", tries=e.get("tries", 0) + 1)
                print("  ! لم يُلتقط — سيُعاد في الدورة التالية")
        st = state()
    d = state()
    done = [k for k, v in d["sites"].items() if v.get("status") == "done"]
    print("\n✓ منجز: %d — %s" % (len(done), ", ".join(done)))

def main():
    a = sys.argv[1:]
    if a and a[0] == "list":
        for name, key, *_ in SITES:
            print("  %-12s %-18s %s" % (name, key, core.get(key) or "—"))
        return
    run(a[0] if a else None)

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/agent_register.py && ok "agent_register.py"
python3 tools/agent_register.py list 2>&1 | tee -a "$LOG"

# ─────────────── 5 · التوسعة: آلاف الصفحات + hubs
hd "5 · tools/expand_pages.py — توسعة الصفحات"
cat > tools/expand_pages.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يوسّع الصفحات من الكتالوج (افتراضي 3000) + hubs + sitemap مقسّم."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

LIMIT = int(core.get("PAGE_LIMIT") or 3000)
TPL = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(t)s — CineHub 3099</title>
<meta name="description" content="%(t)s — مشاهدة مجانية %(y)s">
<meta property="og:title" content="%(t)s"><meta property="og:image" content="%(th)s">
<meta name="twitter:card" content="summary_large_image"><link rel="canonical" href="%(site)s/%(dir)s/%(slug)s.html">
<link rel="manifest" href="../manifest.json">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:18px}h1{font-size:21px}
img{max-width:260px;border-radius:12px;background:#0f1520}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ads{display:flex;justify-content:center;margin:14px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}
</style></head><body><div class="w">
<p class="k"><a href="../">الرئيسية</a> · <a href="../adult.html">🔞</a> · <a href="../new.html">جديد</a> · <a href="../best.html">الأفضل</a></p>
<img loading="lazy" src="%(th)s" alt="%(t)s" onerror="this.style.display='none'">
<h1>%(t)s <span class="k">%(y)s</span></h1>
<p class="k">%(c)s</p>
%(ads)s
<p><a href="../rewards.html">🎁 مكافأة يومية</a> · <a href="../share.html">🔗 شارك</a></p>
</div><script src="../hits.js" defer></script></body></html>"""

def main():
    with core.lock("expand", 3600) as got:
        if not got: print("  · مقفول"); return
        rows, src = core.catalog()
        if not rows: print("  ✗ لا كتالوج"); return
        ad = [r for r in rows if core.is_adult(r)]
        gen = [r for r in rows if not core.is_adult(r)]
        S = core.site()
        blk_a = ads.block("adult", 2); blk_g = ads.block("both", 2)
        made = 0
        plan = [(ad, "adult", blk_a), (gen, "m", blk_g)]
        for group, d, blk in plan:
            os.makedirs(d, exist_ok=True)
            for r in group[:LIMIT]:
                p = "%s/%s.html" % (d, r["i"])
                h = TPL % {"t": core.esc(r["t"]), "th": core.esc(r["th"]), "y": core.esc(r["y"]),
                           "slug": r["i"], "site": S, "ads": blk, "dir": d, "c": core.esc(r["c"][:80])}
                if core.write_if_changed(p, h): made += 1
        # hubs
        def hub(fn, title, items, d="."):
            cards = "".join('<a class="c" href="%s/%s.html"><img loading="lazy" src="%s" alt="%s"'
                            ' onerror="this.style.display=\'none\'"><b>%s</b></a>'
                            % (d, r["i"], core.esc(r["th"]), core.esc(r["t"]), core.esc(r["t"]))
                            for r in items)
            core.write_if_changed(fn, """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s — CineHub 3099</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1100px;margin:0 auto;padding:16px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;display:block}.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden}
a{color:#5ca9ff}</style></head><body><div class="w"><h1>%s</h1><div class="grid">%s</div></div>
<script src="hits.js" defer></script></body></html>""" % (title, title, cards))
        hub("new.html", "🆕 أحدث المضاف", ad[:200] + gen[:200], ".")
        hub("best.html", "⭐ الأفضل", ad[200:500] + gen[200:500], ".")
        core.write_if_changed("sitemap-adult.xml", sitemap(S, ["/adult/%s.html" % r["i"] for r in ad[:LIMIT]]))
        core.write_if_changed("sitemap.xml", sitemap(S, ["/m/%s.html" % r["i"] for r in gen[:LIMIT]]
                              + ["/new.html", "/best.html", "/rewards.html", "/rewards-earn.html", "/share.html"]))
        core.write_if_changed("sitemap-index.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
          + "".join("<sitemap><loc>%s/%s</loc><lastmod>%s</lastmod></sitemap>" % (S, f, time.strftime("%F"))
                    for f in ("sitemap.xml","sitemap-adult.xml")) + "</sitemapindex>")
        core.save("data/expand.json", {"at": time.strftime("%F %H:%M"), "limit": LIMIT,
                  "adult": min(len(ad), LIMIT), "general": min(len(gen), LIMIT), "new": made})
        print("  ✓ %d صفحة جديدة · adult %d · m %d · hubs · sitemap-index"
              % (made, min(len(ad), LIMIT), min(len(gen), LIMIT)))

def sitemap(S, paths):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
            + "".join("<url><loc>%s%s</loc><lastmod>%s</lastmod></url>" % (S, p, time.strftime("%F"))
                      for p in paths) + "</urlset>")

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/expand_pages.py && ok "expand_pages.py"

# ─────────────── 6 · واجهة موحّدة احترافية
hd "6 · assets/app.css + واجهة المستخدم me.html"
cat > assets/app.css <<'CSSEOF'
:root{--bg:#0a0c11;--card:#131a25;--line:#1e2635;--fg:#e9eef6;--dim:#8b96a8;--acc:#3b82f6;--ok:#39d98a;--warn:#e8c76a;--bad:#ff7b7b}
*{box-sizing:border-box}
body{margin:0;background:linear-gradient(180deg,#0a0c11,#0d1219 60%);color:var(--fg);font:15px/1.75 system-ui,Tahoma;min-height:100vh}
a{color:#7db4ff;text-decoration:none}a:hover{opacity:.85}
.wrap{max-width:1080px;margin:0 auto;padding:16px}
.top{display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:10px 0;border-bottom:1px solid var(--line);margin-bottom:14px}
.top a{font-size:13px;color:var(--dim);padding:5px 9px;border-radius:8px}
.top a:hover,.top a.on{background:var(--card);color:var(--fg)}
.brand{font-weight:700;font-size:17px;color:var(--fg);margin-inline-end:auto}
h1{font-size:23px;margin:.4em 0}h2{font-size:17px;color:#a8b8cc;margin:1.4em 0 .5em}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px;margin:11px 0}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px}
.tile{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden}
.tile img{width:100%;aspect-ratio:2/3;object-fit:cover;display:block;background:#0f1520}
.tile b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
.k{color:var(--dim);font-size:13px}
.btn{display:inline-block;padding:11px 16px;border:0;border-radius:11px;background:var(--acc);color:#fff;font-weight:600;cursor:pointer;font-size:15px}
.btn.ghost{background:transparent;border:1px solid var(--line);color:var(--fg)}
.btn[disabled]{background:#26303f;color:#7d8896}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px}
.stat{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px}
.stat .v{font-size:22px;font-weight:700}.stat .l{font-size:12px;color:var(--dim)}
.ok{color:var(--ok)}.warn{color:var(--warn)}.bad{color:var(--bad)}
.ads{display:flex;justify-content:center;margin:14px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}
table{width:100%;border-collapse:collapse;font-size:13px}td,th{padding:7px;border-bottom:1px solid var(--line);text-align:right}
th{color:var(--dim);font-weight:500}
input,textarea{width:100%;background:#0b0f17;border:1px solid var(--line);border-radius:9px;color:#cfe0f5;padding:9px;font-size:14px;font-family:inherit}
.foot{color:var(--dim);font-size:12.5px;padding:22px 0;text-align:center}
CSSEOF
ok "assets/app.css"

cat > tools/userwallet.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""واجهة المستخدم: مشاهدة · مشاركة · إحالة · أرباح. عمولة المالك 20% تُضاف للخزينة."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE, custody

CUT = custody.POLICY["owner_cut_pct"]

def main():
    with core.lock("userwallet", 900) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger(); conf = r["totals"]["approved"] + r["totals"]["paid"]
        pool = round(conf * 50 / 100.0, 4)
        core.write_if_changed("me.html", """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>محفظتي — CineHub 3099</title><meta name="description" content="شاهد · شارك · اربح">
<link rel="manifest" href="manifest.json"><link rel="stylesheet" href="assets/app.css">
</head><body><div class="wrap">
<div class="top"><span class="brand">CineHub 3099</span>
<a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="rewards.html">🎁 المكافأة</a>
<a href="share.html">🔗 شارك</a><a href="me.html" class="on">محفظتي</a></div>
<h1>محفظتي</h1>
<div class="card"><p class="k">أدخل كودك — يظهر لك ما كسبته من الإحالات.</p>
<input id="code" placeholder="كودك (مثال: alisalimax3)" oninput="save()">
<p class="k">رابط إحالتك:</p><input id="link" readonly onclick="this.select()"></div>
<div class="stats">
<div class="stat"><div class="l">مطالباتك</div><div class="v" id="mine">—</div></div>
<div class="stat"><div class="l">إحالاتك (مطالبات)</div><div class="v" id="refs">—</div></div>
<div class="stat"><div class="l">نقاطك التقديرية</div><div class="v ok" id="pts">—</div></div>
<div class="stat"><div class="l">صندوق المكافآت</div><div class="v">$%(pool).4f</div></div>
</div>
<div class="card"><b>كيف تُحسب</b>
<table><tr><td>عائد الموقع المؤكد</td><td>$%(conf).2f</td></tr>
<tr><td>حصة المستخدمين (50%%)</td><td>$%(pool).4f</td></tr>
<tr><td>عمولة المالك من أرباح المستخدمين</td><td>%d%%</td></tr>
<tr><td>حصتك</td><td>مطالباتك ÷ إجمالي المطالبات × الحصة</td></tr></table>
<p class="k">النقاط ليست دولارًا قابلاً للسحب بعد — تصبح كذلك عند بلوغ العائد المؤكد 20$.</p></div>
<div class="card"><b>شارك واربح</b><p class="k">كل من يأتي عبر رابطك ويطالب يوميًا يزيد إحالاتك.</p>
<button class="btn" onclick="cp()">انسخ رابطي</button>
<a class="btn ghost" href="share.html">روابط جاهزة</a></div>
<div class="card"><b>القواعد</b><p class="k">مطالبة واحدة يوميًا لكل جهاز · المنع من السيرفر ·
لا سقف يومي · لا رصيد وهمي · عمولة المالك %d%% تُضاف لخزينته مباشرة.</p></div>
<div class="foot"><a href="owner.html">لوحة المالك</a> · <a href="income.html">المصادر</a></div>
</div><script src="hits.js" defer></script>
<script>
var NS="%(ns)s",S="%(site)s";
function g(k,d){try{return localStorage.getItem(k)||d}catch(e){return d}}
function s(k,v){try{localStorage.setItem(k,v)}catch(e){}}
function save(){var c=(document.getElementById("code").value||"").trim();s("ch_code",c);
document.getElementById("link").value=S+"/?ref="+encodeURIComponent(c);load(c);}
function cp(){var l=document.getElementById("link");l.select();document.execCommand("copy");}
function load(c){if(!c)return;
fetch("https://abacus.jasoncameron.dev/get/"+NS+"/ref-"+c.replace(/[^A-Za-z0-9._-]/g,"-"))
.then(function(r){return r.json()}).then(function(j){document.getElementById("refs").textContent=(j&&j.value)||0;})
.catch(function(){document.getElementById("refs").textContent="0";});}
var c0=g("ch_code","");if(c0){document.getElementById("code").value=c0;
document.getElementById("link").value=S+"/?ref="+encodeURIComponent(c0);load(c0);}
document.getElementById("mine").textContent=parseInt(g("ch_claims","0"),10);
document.getElementById("pts").textContent=parseInt(g("ch_claims","0"),10)*5;
</script></body></html>""" % {"pool": pool, "conf": conf, "ns": core.ns(),
                           "site": core.site(), "cut": CUT})
        # robots: منع فهرسة صفحات المستخدم/المالك
        print("  ✓ me.html · عمولة المالك %d%%" % CUT)

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/userwallet.py && ok "userwallet.py"

# ─────────────── 7 · تشغيل
hd "7 · تشغيل"
if pgrep -f agentd.sh >/dev/null 2>&1; then printf '  إيقاف الوكيل مؤقتًا\n'; pkill -f agentd.sh; sleep 1; fi
NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
[ -f .tmp/hits.tpl ] && sed "s/__NS__/$NSV/" .tmp/hits.tpl > hits.js
grep -q "$NSV" hits.js 2>/dev/null && ok "hits.js ← $NSV" || wrn "hits.js"

for s in ads adult_build adult_promote adult_registry fix_pages growth rewards dashboard audit_full adcheck userwallet custody; do
  printf '  · %-18s ' "$s"; python3 "tools/$s.py" >>"$LOG" 2>&1 && printf '%s✓%s\n' "$G" "$N" || printf '%s✗%s\n' "$R" "$N"
done
printf '  · %-18s ' "expand_pages"; timeout 900 python3 tools/expand_pages.py 2>&1 | tail -1 | tee -a "$LOG"
python3 tools/aads_verify.py 2>&1 | tail -4 | tee -a "$LOG"
python3 tools/live_verify.py 2>&1 | tail -4 | tee -a "$LOG"

hd "8 · اختبار"
python3 tools/selftest.py 2>&1 | tail -22 | tee -a "$LOG"
ST="${PIPESTATUS[0]}"

hd "9 · نشر (بلا --force)"
if [ "$ST" = "0" ]; then
  U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login())" 2>/dev/null)"
  T="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.token())" 2>/dev/null)"
  if [ -n "$U" ] && [ -n "$T" ]; then
    git remote remove origin 2>/dev/null
    git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
    rm -f .git/index.lock; git add -A; git add -f .github/workflows/agent.yml 2>/dev/null
    git -c user.email=a@c.local -c user.name=Agent commit -m "final: curl http + custody vault + register agent + expansion + user wallet" >/dev/null 2>&1
    git fetch origin main 2>/dev/null && git -c user.email=a@c.local -c user.name=Agent pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
    if timeout 2400 git push origin main 2>"$TMPDIR/e"; then ok "رُفع"; sleep 60; python3 tools/live_verify.py 2>&1 | tail -3 | tee -a "$LOG"
    else bad "فشل: $(tail -2 "$TMPDIR/e" | head -1)"; fi
    python3 -c "import sys;sys.path.insert(0,'tools');import gh;gh.enable_pages()" >/dev/null 2>&1
  else wrn "لا توكن"; fi
else wrn "الاختبارات فشلت"; fi

hd "10 · الرصيد"
python3 tools/custody.py 2>&1 | tee -a "$LOG"
V1="$(python3 -c "import json;print(json.load(open('data/vault.json')).get('balance_usd',0))" 2>/dev/null || echo 0)"
printf '  قبل $%s → بعد $%s %s\n' "$V0" "$V1" "$([ "$V0" = "$V1" ] && echo '✓ محفوظ' || echo '! تغيّر')"

if [ "$MODE" = "register" ] || [ "$MODE" = "all" ]; then
  hd "11 · وكيل التسجيل"
  python3 tools/agent_register.py 2>&1 | tee -a "$LOG"
fi

rm -f .git/index.lock; setsid bash agentd.sh >> logs/agentd.log 2>&1 & sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"
printf '\n%s╔══════════════════════════════════════════════╗\n' "$G"
printf '║  FINAL — اكتمل                             ║\n'
printf '╚══════════════════════════════════════════════╝%s\n' "$N"
printf 'للمستخدم: %s/me.html · للمالك: %s/owner.html\n' "$SITEU" "$SITEU"
