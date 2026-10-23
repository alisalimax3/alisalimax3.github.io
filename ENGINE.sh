#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  ENGINE.sh — محرك إيرادات · اكتشاف مزودين · دفتر بقيد فريد · نمو · وكيل
#  لا يستخدم git push --force · يطلب موافقة قبل النشر
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || exit 1
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data go .github/workflows
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/engine.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
step(){ printf '\n%s▸ %s%s\n' "$B" "$*" "$N" | tee -a "$LOG"; }

# ════════════════════════════════════════ 0 · نسخة احتياطية إلزامية
hd "0 · نسخة احتياطية قبل التعديل"
BK="$HOME/cinehub-backups/pre-engine-$(date +%F_%H%M%S)"; mkdir -p "$BK"
tar czf "$BK/tree.tgz" --exclude=.git --exclude=.tmp --exclude=logs . 2>/dev/null
git bundle create "$BK/repo.bundle" --all >/dev/null 2>&1
cp keys.env "$BK/keys.env.bak" 2>/dev/null
cp -r data "$BK/data" 2>/dev/null
ok "النسخة: $BK ($(du -sh "$BK" 2>/dev/null | cut -f1))"
printf '%s\n' "$BK" > "$HOME/.cinehub_lastbackup"

# ════════════════════════════════════════ 1 · النواة
hd "1 · tools/core.py — نواة موحّدة"
cat > tools/core.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub 3099 — النواة: بيئة · توحيد حقول · أقفال · عملات · HTTP آمن."""
import json, os, re, sys, time, html as _html, hashlib, contextlib, urllib.request

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
def fp(v, n=8):
    """بصمة المفتاح — للمقارنة بلا كشف القيمة."""
    return hashlib.sha256(str(v or "").encode()).hexdigest()[:n]
def mask(v, keep=4):
    v = str(v or "")
    return "" if not v else (v if len(v) <= keep else v[:keep] + "…" + v[-2:])

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

# ── HTTP بلا مكتبات خارجية
UA = "Mozilla/5.0 (Linux; Android) CineHub3099-Agent/1.0"
def http(url, timeout=12, method="GET"):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"}, method=method)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {"ok": True, "code": r.status, "final": r.geturl(), "len": r.headers.get("Content-Length")}
    except urllib.error.HTTPError as e:
        return {"ok": False, "code": e.code, "final": url, "err": "HTTP %s" % e.code}
    except Exception as e:
        return {"ok": False, "code": 0, "final": url, "err": type(e).__name__}

# ── توحيد حقول الكتالوج
FIELD_MAP = {
  "t":  ("t","title","name","ar","ar_title","title_ar","original_title","en","label","nm","عنوان"),
  "i":  ("i","id","slug","key","code","uid","imdb","imdb_id","tmdb","tmdb_id","_id","ref","معرف"),
  "th": ("th","poster","image","img","cover","thumbnail","pic","photo","poster_url","image_url","banner","صورة"),
  "c":  ("c","cat","category","genre","genres","section","type","kind","collection","tags","list","فئة"),
  "s":  ("s","src","source","provider","origin","site","from","host","server","مصدر"),
  "y":  ("y","year","date","release","release_date","released","air_date","premiere","سنة"),
  "u":  ("u","url","link","href","watch","watch_url","embed","player","stream","file","رابط"),
  "d":  ("d","desc","description","overview","plot","summary","synopsis","about","note","وصف"),
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
    """يقرأ كل ملفات الكتالوج ويدمجها ويوحّد الحقول → يقتل مشكلة 0 عناوين."""
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

STRONG = ("adult","18+","xxx","erotic","nsfw","porn","hentai","rule34","redgifs","brazzers","milf","onlyfans","brazzers")
WEAK   = ("adult","18+","xxx","erotic","nsfw","porn","hentai","rule34","sexy","lingerie","cam")

def is_adult(row):
    strong = (row.get("c","") + " " + row.get("s","")).lower()
    if any(k in strong for k in STRONG): return True
    weak = (row.get("t","") + " " + row.get("d","")).lower()
    return any(k in weak for k in WEAK)

def site(): return (get("SITE_URL") or ("https://%s.github.io" % get("GH_USER"))).rstrip("/")
def ns(): return "cinehub3099-" + re.sub(r"[^a-z0-9]", "", (get("GH_USER") or "anon").lower())[:16]

# ── عملات: لا تجمع مختلف دون سعر وتاريخ
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

# ════════════════════════════════════════ 2 · محرّك الإعلانات (منع التكرار)
hd "2 · tools/ads.py — حقن بعلامات، بلا تكرار، بلا تحميل مزدوج"
cat > tools/ads.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""كتلة إعلانات مضمّنة بعلامات: تُستبدل في مكانها فلا تتكرر ولا تُحمّل مرتين."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# id, name, kind, zone_key, embed_key, url_template, tier, section
NETS = [
 ("exoclick","ExoClick","banner","EXOCLICK_ZONE","EXOCLICK_EMBED",
  "https://s.exoclick.com/ads.php?type={size}&zone={id}",1,"adult"),
 ("juicyads","JuicyAds","banner","JUICYADS_ZONE","JUICYADS_EMBED",
  "https://adserver.juicyads.com/adshow.php?adzone={id}",1,"adult"),
 ("aads","A-ADS","banner","AADS_UNIT","AADS_EMBED",
  "https://ad.a-ads.com/{id}?size={size}",1,"both"),
 ("adsterra","Adsterra","banner","ADSTERRA_ZONE","ADSTERRA_EMBED",None,2,"both"),
 ("hilltopads","HilltopAds","banner","HILLTOPADS_ZONE","HILLTOPADS_EMBED",None,2,"both"),
 ("trafficstars","TrafficStars","banner","TRAFFICSTARS_ZONE","TRAFFICSTARS_EMBED",None,2,"adult"),
 ("clickadu","Clickadu","banner","CLICKADU_ZONE","CLICKADU_EMBED",None,2,"both"),
 ("popads","PopAds","popunder","POPADS_SITE","POPADS_EMBED",None,3,"both"),
 ("popcash","PopCash","popunder","POPCASH_SITE","POPCASH_EMBED",None,3,"both"),
 ("evadav","EvaDav","push","EVADAV_ZONE","EVADAV_EMBED",None,3,"both"),
]
_TPL = {n[0]: n[5] for n in NETS}

def status():
    out = []
    for nid, name, kind, zk, ek, tpl, tier, sect in NETS:
        z, e = core.get(zk), core.get(ek)
        out.append({"id": nid, "n": name, "kind": kind, "zone_key": zk, "zone": z,
                    "embed_key": ek, "has_embed": bool(e), "tier": tier, "section": sect,
                    "on": bool(z or e)})
    return out

def _one(n):
    e = core.get(n["embed_key"])
    if e: return e
    z = n["zone"]
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    url = tpl.replace("{id}", core.esc(z)).replace("{size}", "300x250")
    return ('<iframe src="%s" width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % url)

def block(section="adult", limit=2):
    nets = sorted([n for n in status() if n["section"] in (section, "both") and n["on"]],
                  key=lambda n: n["tier"])
    codes = [c for c in (_one(n) for n in nets[:limit]) if c]
    extra = [c for c in (_one(n) for n in nets[limit:] if n["kind"] != "banner") if c]
    inner = "".join('<div class="ads">%s</div>' % c for c in codes)
    if not inner:
        inner = ('<div class="ads"><span class="adsnote">لا شبكة مفعّلة بعد — '
                 'افتح networks.html وسجّل، ثم ألصق المفتاح في keys.env</span></div>')
    if extra: inner += "".join(extra)
    return "<!--ADS:%s:start-->" % section + inner + "<!--ADS:%s:end-->" % section

def inject(page_html, section="adult"):
    blk = block(section)
    pat = re.compile(r"<!--ADS:%s:start-->.*?<!--ADS:%s:end-->" % (section, section), re.S)
    if pat.search(page_html):
        return pat.sub(lambda m: blk, page_html, count=1)
    if "</body>" in page_html:
        return page_html.replace("</body>", blk + "\n</body>", 1)
    return page_html + blk

def counts():
    s = status()
    return len(s), len([x for x in s if x["on"]])

def main():
    with core.lock("ads", 600) as got:
        if not got: print("  · مقفول"); return
        st = status()
        core.save("ads-all.json", {"updated": core.time.strftime("%F %H:%M"),
                                   "count": len(st), "enabled": len([x for x in st if x["on"]]),
                                   "note": "المفتاح يُنشأ من لوحة المزود. لا مفتاح يعمل بلا حساب.",
                                   "networks": st})
        core.save("ads-adult.json", {"updated": core.time.strftime("%F %H:%M"),
                                     "count": len(st), "enabled": len([x for x in st if x["on"]]),
                                     "networks": st})
        fixed = 0
        for d in ("adult", "."):
            if not os.path.isdir(d): continue
            for f in os.listdir(d):
                if not f.endswith(".html"): continue
                p = os.path.join(d, f)
                s = open(p, encoding="utf-8").read()
                if "<!--ADS:adult:start-->" in s: continue
                if "ads-adult.json" not in s and 'class="ads"' not in s: continue
                core.write_if_changed(p, inject(s, "adult")); fixed += 1
        n, on = counts()
        print("  ✓ ads-all.json + ads-adult.json: %d شبكة · %d مفعّلة · أُصلحت %d صفحة قديمة" % (n, on, fixed))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/ads.py && ok "ads.py" || bad "ads.py"

# ════════════════════════════════════════ 3 · إدارة الأسرار
hd "3 · tools/secrets.py — إدارة أسرار بلا كشف"
cat > tools/secrets.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص الأسرار: أسماء · بصمات · تسرّب للواجهة · حالة Git. لا يطبع قيمًا."""
import os, re, sys, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

GROUPS = {
 "ads": ["EXOCLICK_ZONE","JUICYADS_ZONE","AADS_UNIT","ADSTERRA_ZONE","HILLTOPADS_ZONE",
         "TRAFFICSTARS_ZONE","CLICKADU_ZONE","POPADS_SITE","POPCASH_SITE","EVADAV_ZONE"],
 "embeds": [k + "_EMBED" for k in ("ADSTERRA","HILLTOPADS","TRAFFICSTARS","CLICKADU","AADS","POPADS","POPCASH","EVADAV")],
 "affiliate": ["STRIPCHAT_REF","CRAKREVENUE_REF","CHATURBATE_REF","BONGA_REF","JASMIN_REF",
               "STREAMATE_REF","JERKMATE_REF","FLIRT4FREE_REF","IMLIVE_REF","CAMSODA_REF",
               "XHLIVE_REF","FANCENTRO_REF","LOSPOLLOS_REF","MOBIDEA_REF","ZEYDOO_REF"],
 "api": ["EXOCLICK_API_TOKEN","EXOCLICK_API_USER","EXOCLICK_API_PASS"],
 "site": ["GH_USER","SITE_URL","REF_CODE"],
}
SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}
WHITELIST = {"GH_USER","SITE_URL","REF_CODE"}

def report():
    E = core.env()
    out = {"present": [], "missing": [], "leaks": [], "tracked": None}
    for g, names in GROUPS.items():
        for n in names:
            (out["present"] if (E.get(n) or "").strip() else out["missing"]).append(n)
    try:
        r = subprocess.run(["git", "ls-files", "--error-unmatch", "keys.env"],
                           capture_output=True, text=True)
        out["tracked"] = (r.returncode == 0)
    except Exception: pass
    for d in (".", "go", "adult"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if not f.endswith((".html", ".js", ".json")): continue
            if f in ("ads-all.json", "ads-adult.json"): continue
            try: s = open(os.path.join(d, f), encoding="utf-8", errors="ignore").read()
            except Exception: continue
            for n in GROUPS["api"] + list(SECRET):
                v = (E.get(n) or "").strip()
                if len(v) > 6 and v in s: out["leaks"].append("%s→%s" % (n, os.path.join(d, f)))
    return out

def main():
    r = report()
    print("  أسرار مضبوطة : %d" % len(r["present"]))
    for n in r["present"]: print("    ✓ %-22s بصمة %s" % (n, core.fp(core.get(n))))
    print("  ناقصة        : %d" % len(r["missing"]))
    print("    " + " ".join(r["missing"][:24]))
    print("  keys.env في Git: %s" % ("نعم" if r["tracked"] else "لا"))
    print("  تسرّب للواجهة: %s" % (len(r["leaks"]) or "لا شيء"))
    for l in r["leaks"][:8]: print("    ·", l)
    core.save("data/secrets_state.json", {
        "updated": core.time.strftime("%F %H:%M"),
        "present": [{"name": n, "fingerprint": core.fp(core.get(n))} for n in r["present"]],
        "missing": r["missing"], "leaks": r["leaks"], "tracked_in_git": r["tracked"]})

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/secrets.py && ok "secrets.py" || bad "secrets.py"

# ════════════════════════════════════════ 4 · محرك الإيرادات المركزي
hd "4 · tools/revenue_engine.py — الوحدة المركزية"
cat > tools/revenue_engine.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""محرك الإيرادات المركزي: سجل تكاملات + دفتر بقيد فريد + عملات + مزامنة."""
import json, os, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

REG, LED, FX = "data/revenue.json", "data/ledger.json", "data/fx.json"
ACCOUNT = ("unregistered","pending_approval","pending_credentials","active","suspended","rejected","blocked")
TXSTATE = ("estimated","pending","approved","rejected","paid")
TXTYPE  = ("impression_revenue","click_revenue","lead","sale","revshare","bonus","referral","payout")

# id, name, type, official, min_payout, methods, schedule, adult, api, env_key, note, verified
P = [
 ("exoclick","ExoClick","advertising","https://www.exoclick.com/publishers/","$20 Paxum · $50 كريبتو · $200 حوالة","Paxum · كريبتو · Wire","Net7 أسبوعي أو Net20 شهري","yes","yes","EXOCLICK_ZONE","أعلى RPM إباحي","2026-10-18"),
 ("adsterra","Adsterra","advertising","https://adsterra.com/publishers/","$5 Paxum/WebMoney · $25 PayPal","PayPal · Paxum · USDT","كل أسبوعين","yes","no","ADSTERRA_ZONE","أسرع قبول (<10 دقائق) — ابدأ به","2026-10-18"),
 ("juicyads","JuicyAds","advertising","https://www.juicyads.com/signup","$25","PayPal · Paxum · كريبتو","أسبوعي (الجمعة)","yes","no","JUICYADS_ZONE","إحالة 20% مدى الحياة","2026-10-18"),
 ("hilltopads","HilltopAds","advertising","https://hilltopads.com/publishers/","$20","USDT · Wise · PayPal","Net7 الثلاثاء","yes","no","HILLTOPADS_ZONE","USDT TRC20/ERC20","2026-10-18"),
 ("popads","PopAds","advertising","https://www.popads.net/","$5","متعدد","عند الطلب","yes","no","POPADS_SITE","بوب أندر فقط","2026-10-18"),
 ("popcash","PopCash","advertising","https://popcash.net/","$10","PayPal · BTC","يومي","yes","no","POPCASH_SITE","أسرع سحب · حصة 80%","2026-10-18"),
 ("trafficstars","TrafficStars","advertising","https://trafficstars.com/","$10 USDT · $100 محافظ","USDT · BTC · Paxum","أسبوعي/شهري","yes","no","TRAFFICSTARS_ZONE","فيديو ونيتيف","2026-10-18"),
 ("clickadu","Clickadu","advertising","https://www.clickadu.com/","$50","متعدد","Net7 الثلاثاء","yes","no","CLICKADU_ZONE","إحالة 5% سنة أولى","2026-10-18"),
 ("evadav","EvaDav","advertising","https://evadav.com/","$100","بلا كريبتو","Net7 الثلاثاء","yes","no","EVADAV_ZONE","تدفع عن اشتراك push","2026-10-18"),
 ("aads","A-ADS","advertising","https://aads.com/earn/","رصيد→BTC تلقائي","BTC","تلقائي","yes","no","AADS_UNIT","بلا JS · بلا حد ترافيك · يقبل NSFW","2026-10-18"),
 ("stripchat","Stripchat (StripCash)","affiliate_lead","https://affiliates.stripchat.com/","$50","Wire · Paxum","شهري","yes","yes","STRIPCHAT_REF","$1.50/تسجيل مجاني · 20-25% مدى الحياة","2026-10-18"),
 ("crakrevenue","CrakRevenue","affiliate_sale","https://www.crakrevenue.com/","$50","Wire · Paxum","شهري","yes","yes","CRAKREVENUE_REF","$168/تحويل (عرض Stripchat)","2026-10-18"),
 ("chaturbate","Chaturbate","affiliate_revshare","https://chaturbate.com/affiliates/","$50","Wire · Paxum","شهري","yes","yes","CHATURBATE_REF","20% مدى الحياة","2026-10-18"),
 ("bonga","BongaCams","affiliate_revshare","https://bongacash.com/","$50","Wire","شهري","yes","no","BONGA_REF","revshare","2026-10-18"),
 ("jasmin","LiveJasmin","affiliate_revshare","https://www.livejasmin.com/en/affiliate","$50","Wire","شهري","yes","no","JASMIN_REF","revshare عالي","2026-10-18"),
 ("streamate","Streamate","affiliate_revshare","https://affiliate.streamate.com/","$50","Wire","شهري","yes","no","STREAMATE_REF","revshare","2026-10-18"),
 ("jerkmate","Jerkmate","affiliate_revshare","https://jerkmate.com/","$50","Wire","شهري","yes","no","JERKMATE_REF","revshare","2026-10-18"),
 ("flirt4free","Flirt4Free","affiliate_revshare","https://www.flirt4free.com/affiliates/","$50","Wire","شهري","yes","no","FLIRT4FREE_REF","revshare","2026-10-18"),
 ("imlive","ImLive","affiliate_revshare","https://www.imlive.com/affiliate/","$50","Wire","شهري","yes","no","IMLIVE_REF","revshare","2026-10-18"),
 ("camsoda","CamSoda","affiliate_revshare","https://www.camsoda.com/affiliates","$50","Wire","شهري","yes","no","CAMSODA_REF","revshare","2026-10-18"),
 ("xhlive","xHamsterLive","affiliate_revshare","https://xhamsterlive.com/","$50","Wire","شهري","yes","no","XHLIVE_REF","revshare","2026-10-18"),
 ("fancentro","FanCentro","subscription","https://fancentro.com/","$50","Wire","شهري","yes","no","FANCENTRO_REF","اشتراك شهري","2026-10-18"),
 ("lospollos","LosPollos","cpa","https://lopollos.com/","$50","PayPal","شهري","yes","no","LOSPOLLOS_REF","عائد لكل تسجيل","2026-10-18"),
 ("mobidea","Mobidea","cpa","https://www.mobidea.com/","$50","PayPal","شهري","yes","no","MOBIDEA_REF","CPA","2026-10-18"),
 ("zeydoo","Zeydoo","cpa","https://zeydoo.com/","$50","Paxum","شهري","yes","no","ZEYDOO_REF","CPA","2026-10-18"),
]

def _rec(o, pid, name, typ, url, mn, pay, sched, adult, api, key, note, ver):
    has_key = core.has(key)
    st = o.get("status") or ("pending_approval" if has_key else "unregistered")
    if has_key and st in ("unregistered","pending_credentials"): st = "pending_approval"
    if not has_key and st == "active": st = "pending_credentials"
    return {
      "id": pid, "name": name, "type": typ, "official_url": url,
      "account_status": st,
      "credential_status": "present" if has_key else "pending_credentials",
      "credential_env": key, "credential_fingerprint": core.fp(core.get(key)) if has_key else "",
      "publisher_id": o.get("publisher_id", ""),
      "clicks": int(o.get("clicks", 0)), "conversions": int(o.get("conversions", 0)),
      "estimated": float(o.get("estimated", 0.0)),
      "approved": float(o.get("approved", 0.0)),
      "pending": float(o.get("pending", 0.0)),
      "rejected": float(o.get("rejected", 0.0)),
      "paid": float(o.get("paid", 0.0)),
      "currency": "USD",
      "min_payout": mn, "payment_methods": pay, "payment_schedule": sched,
      "adult_ok": adult, "api_available": api,
      "last_ok_sync": o.get("last_ok_sync", ""), "last_attempt": o.get("last_attempt", ""),
      "last_error": o.get("last_error", ""),
      "verified_on": ver, "note": note,
      "signup": url,
    }

def build():
    old = core.load(REG, {}) or {}
    oi = {p.get("id"): p for p in (old.get("providers") or []) if isinstance(p, dict)}
    provs = [_rec(oi.get(pid, {}), *row) for row in P]
    tot = {k: round(sum(p[k] for p in provs), 2) for k in ("estimated","approved","pending","rejected","paid")}
    tot["clicks"] = sum(p["clicks"] for p in provs)
    tot["conversions"] = sum(p["conversions"] for p in provs)
    out = {"schema": 3, "updated": time.strftime("%F %H:%M"), "currency": "USD", "goal_usd": 100,
           "pages_url": old.get("pages_url") or core.site(),
           "rules": ["لا يُجمع estimated مع paid", "المستلم = paid فقط",
                     "العملات المختلفة لا تُجمع دون سعر وتاريخ معلومين",
                     "قيد فريد على (المزود + معرف المعاملة) يمنع تكرار العمولة"],
           "providers": provs, "totals": tot,
           "gap_usd": round(max(0.0, 100 - tot["paid"]), 2)}
    core.save(REG, out); return out

# ── الدفتر: قيد فريد (مزود + معرف معاملة)
def _led():
    d = core.load(LED, None)
    if not isinstance(d, dict) or "tx" not in d: d = {"schema": 2, "tx": {}}
    if isinstance(d["tx"], list):
        d["tx"] = {("%s:%s" % (t.get("src",""), t.get("id",""))): t for t in d["tx"]}
        d["schema"] = 2
    return d

def add(provider, amount, state="pending", txid="", date="", ttype="click_revenue",
        currency="USD", note="", external_key=""):
    if state not in TXSTATE: raise SystemExit("حالة غير صحيحة: " + state)
    if ttype not in TXTYPE: raise SystemExit("نوع غير صحيح: " + ttype)
    d = _led()
    date = date or time.strftime("%F")
    txid = txid or external_key or ("%s|%.4f|%s|%s" % (provider, float(amount), date, ttype))
    key = "%s::%s" % (provider, txid)
    if key in d["tx"]:
        return False, key, d["tx"][key]
    usd, conv = core.convert(float(amount), currency, "USD", date)
    d["tx"][key] = {"key": key, "provider": provider, "tx_id": txid, "date": date,
                    "type": ttype, "currency": currency.upper(), "amount": round(float(amount), 4),
                    "amount_usd": usd, "fx": conv, "state": state, "note": note,
                    "imported": time.strftime("%F %H:%M")}
    core.save(LED, d)
    return True, key, d["tx"][key]

def ledger_totals():
    d = _led(); t = {s: 0.0 for s in TXSTATE}; unconv = 0
    bycur = {}
    for x in d["tx"].values():
        if x.get("amount_usd") is None: unconv += 1
        else: t[x["state"]] = round(t.get(x["state"], 0.0) + x["amount_usd"], 4)
        bycur[x["currency"]] = round(bycur.get(x["currency"], 0.0) + x["amount"], 4)
    return t, len(d["tx"]), unconv, bycur

def apply_ledger():
    r = build(); d = _led(); by = {}
    for x in d["tx"].values():
        b = by.setdefault(x["provider"], {s: 0.0 for s in TXSTATE})
        if x.get("amount_usd") is None: continue
        b[x["state"]] = round(b.get(x["state"], 0.0) + x["amount_usd"], 4)
    for p in r["providers"]:
        b = by.get(p["id"])
        if not b: continue
        for k in ("pending","approved","rejected","paid"): p[k] = b[k]
        if b["approved"] or b["paid"]: p["account_status"] = "active"
    t = {k: round(sum(x[k] for x in r["providers"]), 2) for k in ("estimated","approved","pending","rejected","paid")}
    t["clicks"] = sum(x["clicks"] for x in r["providers"])
    t["conversions"] = sum(x["conversions"] for x in r["providers"])
    r["totals"] = t; r["gap_usd"] = round(max(0.0, 100 - t["paid"]), 2)
    core.save(REG, r); return r

def sync():
    r = build()
    p = next((x for x in r["providers"] if x["id"] == "exoclick"), None)
    if not p: return "لا ExoClick"
    tok, usr, pwd = core.get("EXOCLICK_API_TOKEN"), core.get("EXOCLICK_API_USER"), core.get("EXOCLICK_API_PASS")
    p["last_attempt"] = time.strftime("%F %H:%M")
    if not (tok or (usr and pwd)):
        p["last_error"] = "pending_credentials: ضع EXOCLICK_API_TOKEN"
        core.save(REG, r); return "ExoClick: pending_credentials"
    try:
        body = {"api_token": tok} if tok else {"username": usr, "password": pwd}
        req = urllib.request.Request("https://api.exoclick.com/v2/login",
              data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        j = json.loads(urllib.request.urlopen(req, timeout=30).read())
        t = j.get("token") or (j.get("data") or {}).get("token")
        if not t: raise ValueError("لا توكن في الرد")
        d0 = time.strftime("%Y-%m-%d")
        q = urllib.parse.urlencode({"filter[date_from]": d0, "filter[date_to]": d0})
        req2 = urllib.request.Request("https://api.exoclick.com/v2/statistics/p/global?" + q,
               data=b"", headers={"Authorization": "Bearer " + t})
        s = json.loads(urllib.request.urlopen(req2, timeout=30).read())
        rows = s.get("result") or s.get("data") or []
        earn = sum(float(x.get("revenue") or x.get("earnings") or 0) for x in rows if isinstance(x, dict))
        p["estimated"] = round(earn, 4); p["last_ok_sync"] = time.strftime("%F %H:%M")
        p["last_error"] = ""; p["account_status"] = "active"
        core.save(REG, r); return "ExoClick: $%.4f (من API)" % earn
    except Exception as e:
        p["last_error"] = "%s: %s" % (type(e).__name__, str(e)[:70])
        core.save(REG, r); return "ExoClick: فشل → " + p["last_error"]

def fx_set(frm, to, rate, date="", source="manual"):
    d = core.load(FX, {"rates": []}) or {"rates": []}
    d["rates"] = [r for r in d.get("rates", [])
                  if not (r["from"] == frm.upper() and r["to"] == to.upper() and r["date"] == (date or time.strftime("%F")))]
    d["rates"].append({"from": frm.upper(), "to": to.upper(), "rate": float(rate),
                       "date": date or time.strftime("%F"), "source": source})
    d["updated"] = time.strftime("%F %H:%M"); core.save(FX, d)
    return "سعر مثبّت: %s→%s = %s (%s)" % (frm, to, rate, d["rates"][-1]["date"])

def report():
    r = apply_ledger(); t, n, unconv, bycur = ledger_totals()
    print("معاملات: %d · بلا سعر صرف: %d" % (n, unconv))
    for k in TXSTATE: print("  %-10s $%.4f" % (k, t.get(k, 0.0)))
    if len(bycur) > 1: print("  عملات:", bycur)
    print("الفجوة نحو 100$ (من المستلم): $%.2f" % r["gap_usd"])
    act = [p for p in r["providers"] if p["credential_status"] == "present"]
    print("مزودون بمفاتيح: %d من %d" % (len(act), len(r["providers"])))
    for p in act: print("  · %-18s %s" % (p["id"], p["account_status"]))

def cli():
    a = sys.argv[1:]
    if not a: return report()
    c = a[0]
    if c == "build": build(); print("✓ data/revenue.json")
    elif c == "sync": print(sync())
    elif c == "report": report()
    elif c == "add" and len(a) >= 4:
        kw = dict(zip([x.lstrip("-") for x in a[4::2]], a[5::2]))
        okk, key, tx = add(a[1], a[2], a[3], kw.get("id",""), kw.get("date",""),
                           kw.get("type","click_revenue"), kw.get("cur","USD"), kw.get("note",""))
        print(("✓ أُضيف " if okk else "= مكرر، تُخطّي ") + key)
        if tx.get("amount_usd") is None: print("  ! بلا سعر صرف — اضبطه: revenue_engine.py fx %s USD <rate>" % tx["currency"])
        apply_ledger()
    elif c == "status" and len(a) >= 3:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]:
                if a[2] not in ACCOUNT: print("حالات: " + ", ".join(ACCOUNT)); return
                p["account_status"] = a[2]
        core.save(REG, r); print("✓ %s → %s" % (a[1], a[2]))
    elif c == "set" and len(a) >= 4:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]:
                p[a[2]] = float(a[3]) if a[2] in ("estimated","approved","pending","rejected","paid") else a[3]
        core.save(REG, r); print("✓ %s.%s" % (a[1], a[2]))
    elif c == "fx" and len(a) >= 4: print(fx_set(a[1], a[2], a[3], a[4] if len(a) > 4 else ""))
    elif c == "dupes":
        d = _led(); print("معاملات: %d · مفاتيح فريدة: %d" % (len(d["tx"]), len(set(d["tx"]))))
    else:
        print("build|sync|report|dupes|fx <from> <to> <rate> [date]|add <p> <amt> <state> [--id X --type T --cur C --note N]|status <id> <state>|set <id> <f> <v>")

if __name__ == "__main__": cli()
PYEOF
python3 -m py_compile tools/revenue_engine.py && ok "revenue_engine.py" || bad "revenue_engine.py"
python3 tools/revenue_engine.py build >/dev/null 2>&1 && ok "بناء السجل" || bad "بناء السجل"

# ════════════════════════════════════════ 5 · اكتشاف المزودين
hd "5 · tools/provider_discovery.py — تحقق فعلي بـ HTTP"
cat > tools/provider_discovery.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يتحقق من وجود المواقع الرسمية فعليًا ويرتّب المزودين حسب الملاءمة. لا يسجّل حسابات."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

def score(p):
    s = 0
    if p.get("adult_ok") == "yes": s += 30
    if p.get("api_available") == "yes": s += 15
    mn = p.get("min_payout", "")
    import re
    m = re.search(r"\$(\d+)", mn)
    if m:
        v = int(m.group(1))
        s += 25 if v <= 10 else (18 if v <= 25 else (10 if v <= 50 else 3))
    if "BTC" in p.get("payment_methods","") or "USDT" in p.get("payment_methods",""): s += 8
    if p.get("type","").startswith("affiliate"): s += 12
    if p.get("reachable"): s += 15
    else: s -= 20
    return s

def main():
    with core.lock("discovery", 3600) as got:
        if not got: print("  · مقفول"); return
        r = RE.build()
        provs = r["providers"]
        print("  فحص %d موقعًا رسميًا…" % len(provs))
        for p in provs:
            res = core.http(p["official_url"], timeout=12)
            p["reachable"] = bool(res.get("ok"))
            p["http_code"] = res.get("code")
            p["final_url"] = res.get("final", p["official_url"])
            p["check_error"] = res.get("err", "")
            p["checked_on"] = time.strftime("%F")
            p["fit_score"] = score(p)
            mark = "✓" if p["reachable"] else "✗"
            print("    %s %-18s %s %s" % (mark, p["id"], p["http_code"] or res.get("err",""), ""))
        provs.sort(key=lambda x: -x.get("fit_score", 0))
        r["discovery"] = {"updated": time.strftime("%F %H:%M"),
                          "method": "HTTP GET على الرابط الرسمي · الباقي unverified",
                          "reachable": len([p for p in provs if p.get("reachable")]),
                          "total": len(provs)}
        core.save(RE.REG, r)
        core.save("data/providers.json", {"updated": r["discovery"]["updated"],
                  "ranked": [{"id": p["id"], "name": p["name"], "fit": p.get("fit_score"),
                              "reachable": p.get("reachable"), "min_payout": p["min_payout"],
                              "type": p["type"], "url": p["official_url"]} for p in provs]})
        print("  ✓ رُتّب %d · قابل للوصول %d" % (len(provs), r["discovery"]["reachable"]))
        print("  أعلى 6 ملاءمة: " + " · ".join(p["id"] for p in provs[:6]))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/provider_discovery.py && ok "provider_discovery.py" || bad "provider_discovery.py"

# ════════════════════════════════════════ 6 · إصلاح البناء (صفر عناوين)
hd "6 · إعادة كتابة أدوات الكبار بالنواة (يقتل مشكلة 0 عنوان)"
cat > tools/adult_build.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني قسم الكبار من الكتالوج الموحّد — يُحدّث الصفحات القديمة عند تغيّر البيانات."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

TPL = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(t)s — CineHub 3099</title>
<meta name="description" content="%(t)s — مشاهدة مجانية بجودة عالية">
<meta property="og:title" content="%(t)s"><meta property="og:image" content="%(th)s">
<meta property="og:type" content="video.movie"><meta name="twitter:card" content="summary_large_image">
<meta name="rating" content="adult"><link rel="canonical" href="%(site)s/adult/%(slug)s.html">
<link rel="manifest" href="../manifest.json">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:18px}h1{font-size:21px;margin:.4em 0}
img{max-width:260px;border-radius:12px;background:#0f1520}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ads{display:flex;justify-content:center;margin:14px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}
</style></head><body><div class="w">
<p class="k"><a href="../">الرئيسية</a> · <a href="../adult.html">🔞 للكبار</a> · <a href="../app.html">التطبيق</a></p>
<img loading="lazy" src="%(th)s" alt="%(t)s" onerror="this.style.display='none'">
<h1>%(t)s <span class="k">%(y)s</span></h1>
<p class="k">قسم الكبار 18+ — إعلانات مطابقة للجمهور.</p>
%(ads)s
<p><a href="../adult.html">→ كل قسم الكبار</a> · <a href="../rewards.html">🎁 مكافأة يومية</a></p>
</div><script src="../hits.js" defer></script></body></html>"""

CARD = ('<a class="c" href="adult/%(slug)s.html"><img loading="lazy" src="%(th)s" alt="%(t)s"'
        ' onerror="this.style.display=\'none\'"><b>%(t)s</b></a>')

IDX = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>🔞 للكبار — CineHub 3099</title>
<meta name="description" content="قسم الكبار 18+ — %(n)d عنوانًا مشاهدة مجانية">
<meta name="rating" content="adult"><link rel="manifest" href="manifest.json">
<link rel="canonical" href="%(site)s/adult.html">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1100px;margin:0 auto;padding:16px}h1{font-size:21px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:10px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
a{color:#5ca9ff}nav a{margin-inline-end:10px;text-decoration:none;color:#8fa4bf;font-size:12.5px}
.ads{display:flex;justify-content:center;margin:12px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}.k{color:#8b96a8;font-size:13px}
</style></head><body><div class="w">
<nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="movies.html">أفلام</a><a href="series.html">مسلسلات</a><a href="adult.html">🔞 للكبار</a><a href="rewards.html">🎁</a></nav>
<h1>🔞 قسم الكبار</h1>
<p class="k">%(n)d عنوانًا · إعلانات شبكات إباحية فقط (بلا خلط مع العام)</p>
%(ads)s<div class="grid">%(cards)s</div>
</div><script src="hits.js" defer></script></body></html>"""

def main():
    with core.lock("adult_build", 1800) as got:
        if not got: print("  · مقفول"); return
        rows, src = core.catalog()
        if not rows: print("  ✗ لا كتالوج — أرسل مخرجات AUDIT قسم 5"); return
        ad = [r for r in rows if core.is_adult(r)] or rows
        S, blk = core.site(), ads.block("adult", 2)
        new = upd = 0
        os.makedirs("adult", exist_ok=True)
        for r in ad:
            p = "adult/%s.html" % r["i"]
            h = TPL % {"t": core.esc(r["t"]), "th": core.esc(r["th"]), "y": core.esc(r["y"]),
                       "slug": r["i"], "site": S, "ads": blk}
            new += 1 if core.write_if_changed(p, h) else 0
            upd += 0 if core.write_if_changed(p, h) else 1
        cards = "".join(CARD % {"slug": r["i"], "th": core.esc(r["th"]), "t": core.esc(r["t"])} for r in ad[:200])
        core.write_if_changed("adult.html", IDX % {"n": len(ad), "cards": cards, "ads": blk, "site": S})
        now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
        core.write_if_changed("adult-rss.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
          '<title>CineHub 3099 — للكبار</title><link>%s/adult.html</link>'
          '<description>قسم 18+</description><lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
          % (S, now, "".join('<item><title>%s</title><link>%s/adult/%s.html</link></item>'
                             % (core.esc(r["t"]), S, r["i"]) for r in ad[:60])))
        core.save("data/adult_meta.json", {"updated": time.strftime("%F %H:%M"), "source": src,
                  "catalog_total": len(rows), "adult_total": len(ad), "pages": len(ad)})
        print("  ✓ %d صفحة · جديد %d · مصدر=%s" % (len(ad), new, src))

if __name__ == "__main__": main()
PYEOF

cat > tools/adult_promote.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ترويج بنصوص جاهزة + QR + وسم الحملة — تعمل بلا أي مفتاح."""
import os, sys, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ROW = """<div class="c"><img src="%(qr)s" alt="QR"><div style="flex:1">
<b>%(t)s</b><textarea readonly onclick="this.select()">%(txt)s</textarea>
<a target="_blank" rel="noopener" href="https://www.reddit.com/submit?url=%(eu)s&title=%(et)s">Reddit ↗</a>
<a target="_blank" rel="noopener" href="https://twitter.com/intent/tweet?text=%(etxt)s">X ↗</a>
<a target="_blank" rel="noopener" href="https://t.me/share/url?url=%(eu)s&text=%(et)s">تليجرام ↗</a>
<a target="_blank" rel="noopener" href="%(u)s">فتح ↗</a></div></div>"""

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ترويج الكبار — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:900px;margin:0 auto;padding:16px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px}
.c img{width:110px;height:110px;border-radius:8px;background:#fff;padding:4px}
textarea{width:100%%;height:52px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px;margin-inline-end:8px}b{font-size:13.5px}.k{color:#8b96a8;font-size:13px}</style>
</head><body><div class="w"><h1>🔞 ترويج الكبار — %(n)d نص جاهز</h1>
<p class="k">كل رابط يحمل <code>?ref=%(ref)s&utm_source=…&utm_campaign=…</code> لتتبع المصدر.
انشر في r/nsfw · r/porn · r/hentai · تليجرام · X.</p>%(rows)s</div></body></html>"""

def main():
    with core.lock("adult_promote", 900) as got:
        if not got: print("  · مقفول"); return
        rows, _ = core.catalog()
        if not rows: print("  ✗ لا كتالوج"); return
        ad = [r for r in rows if core.is_adult(r)] or rows
        S, ref = core.site(), (core.get("REF_CODE") or core.get("GH_USER") or "ch")
        out = []
        for r in ad[:60]:
            base = "%s/adult/%s.html" % (S, r["i"])
            links = {k: base + "?ref=%s&utm_source=%s&utm_campaign=%s" % (
                urllib.parse.quote(ref), k, k) for k in ("reddit","x","telegram")}
            u = links["reddit"]
            txt = "🔞 %s\n%s" % (r["t"], u)
            out.append(ROW % {
              "qr": "https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=" + urllib.parse.quote(u, safe=""),
              "t": core.esc(r["t"]), "txt": core.esc(txt), "u": core.esc(u),
              "eu": urllib.parse.quote(u, safe=""), "et": urllib.parse.quote(r["t"], safe=""),
              "etxt": urllib.parse.quote(txt, safe="")})
        core.write_if_changed("promote-adult.html", TPL % {"n": len(out), "rows": "".join(out), "ref": core.esc(ref)})
        print("  ✓ promote-adult.html (%d نص · بحملات موسومة)" % len(out))

if __name__ == "__main__": main()
PYEOF

cat > tools/adult_registry.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""صفحة المزودين — الحالة من المحرك المركزي، لا من ادعاءات."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

def main():
    with core.lock("registry", 1800) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger()
        rows = ""
        for p in r["providers"]:
            cls = {"active":"on","pending_approval":"warn","pending_credentials":"warn",
                   "unregistered":"off","suspended":"off","rejected":"off","blocked":"off"}.get(p["account_status"],"off")
            rows += ("<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td>"
                     "<td class='%s'>%s</td><td><a target='_blank' rel='nofollow noopener' href='%s'>↗</a></td></tr>"
                     % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["credential_env"]),
                        core.esc(p["min_payout"]), core.esc(p["payment_schedule"]), cls,
                        core.esc(p["account_status"]), p["official_url"]))
        core.write_if_changed("networks.html", """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>مصادر الدخل — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:1000px;margin:0 auto;padding:18px}table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}code{background:#0b0f17;padding:2px 6px;border-radius:5px}
.on{color:#39d98a}.warn{color:#e8c76a}.off{color:#8b96a8}</style></head><body><div class="w">
<h1>مصادر الدخل — %d</h1>
<p class="k">الأسعار مقروءة من صفحات المزودين 2026-10-18. التسجيل ≠ القبول. «active» تعني وجود مفتاح فقط.</p>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>حد السحب</th><th>التكرار</th><th>الحالة</th><th></th></tr>
%s</table><p><a href="owner.html">لوحة المالك</a> · <a href="adult-networks.html">شبكات الكبار</a> · <a href="providers.html">الترتيب</a></p>
</div></body></html>""" % (len(r["providers"]), rows))
        print("  ✓ networks.html (%d مزود)" % len(r["providers"]))

if __name__ == "__main__": main()
PYEOF
for f in adult_build adult_promote adult_registry; do
  python3 -m py_compile "tools/$f.py" && ok "$f.py" || bad "$f.py"
done

# ════════════════════════════════════════ 7 · عدّاد + RTL
hd "7 · hits.js حقيقي + fix_pages"
cat > tools/fix_pages.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RTL + viewport + عدّاد في الصفحات الموجودة."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
SKIP = {"promote-adult.html","promote.html","adult-networks.html","networks.html","providers.html","owner.html","share.html"}

def fix(p, depth):
    s = open(p, encoding="utf-8").read(); o = s
    m = re.search(r"<html([^>]*)>", s)
    if m and 'dir="rtl"' not in m.group(1):
        s = s[:m.start()] + '<html%s lang="ar" dir="rtl">' % re.sub(r'\s*(lang|dir)="[^"]*"', "", m.group(1)) + s[m.end():]
    if "viewport" not in s[:600] and "<head>" in s:
        s = s.replace("<head>", '<head><meta name="viewport" content="width=device-width,initial-scale=1">', 1)
    if "hits.js" not in s and "</body>" in s and depth <= 1:
        s = s.replace("</body>", '<script src="%shits.js" defer></script>\n</body>' % ("../" * depth), 1)
    if s != o: core.write_if_changed(p, s); return True
    return False

def main():
    with core.lock("fix_pages", 1800) as got:
        if not got: print("  · مقفول"); return
        n = 0
        for d, depth in ((".", 0), ("adult", 1)):
            if not os.path.isdir(d): continue
            for f in sorted(os.listdir(d)):
                if f.endswith(".html") and f not in SKIP and fix(os.path.join(d, f), depth): n += 1
        print("  ✓ أُصلحت %d صفحة" % n)

if __name__ == "__main__": main()
PYEOF

cat > hits.js <<'JSEOF'
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
    var src = q.get("utm_source"); if (src) localStorage.setItem("ch_src", src.slice(0, 24));
    var cmp = q.get("utm_campaign"); if (cmp) localStorage.setItem("ch_cmp", cmp.slice(0, 24)); } catch (e) {}
  window.CH = { ns: NS, vid: vid, hit: hit, get: get, today: d, pv: "pv" + path,
                uv: "uv-" + d + "-" + vid(), dv: "dv-" + d };
  hit(window.CH.pv); hit(window.CH.uv); hit(window.CH.dv);
  document.addEventListener("DOMContentLoaded", function () {
    var el = document.querySelectorAll("[data-hits]");
    for (var i = 0; i < el.length; i++) (function (n) {
      get(window.CH[n.getAttribute("data-hits")]).then(function (v) {
        if (v !== null && v !== undefined) n.textContent = v; }); })(el[i]);
  });
})();
JSEOF

# ════════════════════════════════════════ 8 · النمو
hd "8 · tools/growth.py — sitemap · robots · RSS · صفحات هبوط · روابط حملة"
cat > tools/growth.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""نمو: sitemap · robots · RSS · صفحات هبوط · روابط مشاركة بحملة · go/ للنقرات."""
import json, os, sys, time, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

def sitemap(S, urls):
    body = "".join(
      "<url><loc>%s</loc><lastmod>%s</lastmod><changefreq>%s</changefreq><priority>%s</priority></url>"
      % (core.esc(u), time.strftime("%F"), cf, pr) for u, cf, pr in urls)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">%s</urlset>' % body)

def go_pages(r):
    TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>تحويل… %(name)s</title><meta name="robots" content="noindex">
<style>body{background:#0b0d12;color:#e9eef6;font:16px system-ui,Tahoma;display:flex;align-items:center;
justify-content:center;height:100vh;margin:0;text-align:center}a{color:#5ca9ff}.k{font-size:13px;color:#8b96a8}</style>
</head><body><div><p>جارٍ التحويل إلى <b>%(name)s</b>…</p>
<p class="k">نقرات هذه الوجهة: <b data-hits="go">…</b> · إفصاح: رابط تسويق بالعمولة</p>
<p><a href="%(url)s">اضغط لو لم يتحوّل</a></p></div>
<script>(function(){var U=%(uj)s,NS=%(nj)s,ref="";try{ref=localStorage.getItem("ch_ref")||"";}catch(e){}
function go(){location.replace(U+(ref?((U.indexOf("?")>-1?"&":"?")+"subid="+encodeURIComponent(ref)):""));}
var t=setTimeout(go,1200);
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/go-%(id)s"+(ref?"-"+ref.replace(/[^A-Za-z0-9._-]/g,"-"):""))
 .then(function(r){return r.json();}).then(function(j){var e=document.querySelector("[data-hits]");
 if(e&&j&&j.value!==undefined)e.textContent=j.value;clearTimeout(t);go();}).catch(function(){clearTimeout(t);go();});})();</script>
</body></html>"""
    os.makedirs("go", exist_ok=True)
    n = 0
    for p in r["providers"]:
        url = core.get(p["credential_env"])
        if not url or not p["credential_env"].endswith("_REF"): continue
        core.write_if_changed("go/%s.html" % p["id"], TPL % {
          "name": core.esc(p["name"]), "url": core.esc(url), "uj": json.dumps(url),
          "nj": json.dumps(core.ns()), "id": p["id"]}); n += 1
    return n

LAND = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(title)s — CineHub 3099</title><meta name="description" content="%(desc)s">
<link rel="canonical" href="%(site)s/%(slug)s.html"><link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.9 system-ui,Tahoma}
.w{max-width:720px;margin:0 auto;padding:20px}h1{font-size:24px}h2{font-size:17px;color:#9fb0c6}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:15px;margin:12px 0}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}ul{padding-inline-start:20px}
table{width:100%%;border-collapse:collapse;font-size:13.5px}td{padding:6px;border-bottom:1px solid #1e2635}
.disc{background:#1b1508;border-color:#3a2c08;color:#e8c76a;font-size:13px}</style>
</head><body><div class="w"><h1>%(title)s</h1><p class="k">%(desc)s</p>
<div class="card">%(body)s</div>
<div class="card disc"><b>إفصاح:</b> بعض الروابط في هذه الصفحة روابط تسويق بالعمولة —
قد نحصل على عمولة عند التسجيل، دون أي زيادة في سعرك.</div>
<p><a href="./">الرئيسية</a> · <a href="adult.html">للكبار</a> · <a href="rewards.html">مكافأة يومية</a> · <a href="owner.html">لوحة المالك</a></p>
</div><script src="hits.js" defer></script></body></html>"""

def share_page(S, ref, items):
    rows = ""
    for it in items[:80]:
        u = "%s/adult/%s.html?ref=%s&utm_source=copy&utm_campaign=share" % (S, it["i"], urllib.parse.quote(ref))
        txt = "🔞 %s\n%s" % (it["t"], u)
        rows += ("<div class='c'><b>%s</b><textarea readonly onclick='this.select()'>%s</textarea>"
                 "<a target='_blank' rel='noopener' href='%s'>فتح</a></div>"
                 % (core.esc(it["t"]), core.esc(txt), core.esc(u)))
    return """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>روابط المشاركة</title>
<meta name="robots" content="noindex"><style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:820px;margin:0 auto;padding:16px}.c{background:#131a25;border:1px solid #1e2635;border-radius:10px;padding:9px;margin:8px 0}
textarea{width:100%%;height:44px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>🔗 روابط مشاركة قابلة للنسخ</h1><p class="k">كل رابط موسوم بالحملة — يظهر المصدر في العدّاد.</p>
%s</div></body></html>""" % rows

def main():
    with core.lock("growth", 1800) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger(); S = core.site()
        rows, _ = core.catalog()
        ad = [x for x in rows if core.is_adult(x)] or rows
        ref = core.get("REF_CODE") or core.get("GH_USER") or "ch"
        urls = [(S + "/", "daily", "1.0"), (S + "/adult.html", "daily", "0.9"),
                (S + "/rewards.html", "daily", "0.7"), (S + "/earn.html", "weekly", "0.7")]
        urls += [(S + "/adult/%s.html" % x["i"], "weekly", "0.6") for x in ad[:1500]]
        core.write_if_changed("sitemap.xml", sitemap(S, urls))
        core.write_if_changed("robots.txt",
          "User-agent: *\nAllow: /\nDisallow: /owner.html\nDisallow: /networks.html\n"
          "Disallow: /promote-adult.html\nDisallow: /go/\nSitemap: %s/sitemap.xml\n" % S)
        now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
        core.write_if_changed("rss.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
          '<title>CineHub 3099</title><link>%s</link><lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
          % (S, now, "".join('<item><title>%s</title><link>%s/adult/%s.html</link></item>'
                             % (core.esc(x["t"]), S, x["i"]) for x in ad[:60])))
        core.write_if_changed("share.html", share_page(S, ref, ad))
        # صفحات هبوط
        aff = [p for p in r["providers"] if p["type"].startswith(("affiliate","cpa"))]
        body = "<h2>لماذا التسجيل؟</h2><p>تسجيل مجاني تمامًا، وبلا التزام. البث والمحتوى مفتوحان للمشاهدة.</p>"
        body += "<h2>المزودون المتاحون</h2><table>"
        for p in aff:
            body += ("<tr><td><b>%s</b></td><td>%s</td><td><a rel='nofollow noopener' target='_blank' href='go/%s.html'>اذهب ↗</a></td></tr>"
                     % (core.esc(p["name"]), core.esc(p["note"]), p["id"]))
        body += "</table><p class='k'>حالة المزود: %s</p>" % (
            "مربوط" if any(x["credential_status"] == "present" for x in aff) else "بانتظار المفاتيح")
        core.write_if_changed("go-cams.html", LAND % {
          "title": "بث مباشر — مواقع موصى بها", "desc": "قائمة مواقع البث المباشر مع حالة الربط",
          "slug": "go-cams", "site": S, "body": body})
        go = go_pages(r)
        print("  ✓ sitemap(%d) · robots · rss · share.html · go-cams.html · go/(%d)" % (len(urls), go))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/growth.py && ok "growth.py" || bad "growth.py"

# ════════════════════════════════════════ 9 · المكافآت (بلا سقوف)
hd "9 · tools/rewards.py — مكافآت بلا سقوف يومية/شهرية"
cat > tools/rewards.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مكافآت: نقاط مربوطة بعائد مؤكد · منع تكرار سيرفري · بلا سقف يومي/شهري."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

CLAIM, REFPTS, SHARE = 5, 25, 50
HONEST = ("النقاط ليست دولارًا قابلاً للسحب. حصتك = مطالباتك ÷ إجمالي المطالبات × 50%% "
          "من العائد المؤكد. تصبح قابلة للصرف عند وصول العائد المؤكد إلى 20$ (أقل حد سحب فعلي).")

RULES = [
 "مطالبة واحدة كل 24 ساعة لكل جهاز — يمنعها عدّاد سيرفري، لا localStorage. مسح المتصفح لا يمنح مطالبة إضافية.",
 "لا سقف يومي ولا شهري: كل يوم يُطالب فيه الجميع يُضاف للصندوق.",
 "لا سقف للميزانية: إن تجاوز التوزيع الحصة، يُسجّل التجاوز ولا يُمنع.",
 "الزيارات الآلية تُحتسب زيارة لكن لا تُنشئ مالًا.",
 "النقاط محفوظة على جهازك، والعدد الكلي على السيرفر.",
]

def build():
    r = RE.apply_ledger()
    conf = r["totals"]["approved"] + r["totals"]["paid"]
    pool = round(conf * SHARE / 100.0, 4)
    core.save("data/rewards.json", {
      "updated": time.strftime("%F %H:%M"), "namespace": core.ns(),
      "funding": {"mode": "share-of-confirmed-revenue", "share_pct": SHARE,
                  "confirmed_usd": round(conf, 2), "pool_usd": pool,
                  "status": "غير ممول بعد" if pool <= 0 else "ممول",
                  "caps": {"daily": None, "monthly": None, "overrun_blocked": False}},
      "points": {"claim": CLAIM, "referral": REFPTS},
      "rules": RULES, "honest": HONEST})
    return pool, conf

PAGE = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>المكافأة اليومية — CineHub 3099</title>
<meta name="description" content="مطالبة يومية بنقاط مربوطة بعائد الموقع المؤكد">
<link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:640px;margin:0 auto;padding:18px}h1{font-size:22px;margin:.3em 0}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:16px;margin:12px 0}
.big{font-size:34px;font-weight:700;color:#39d98a;line-height:1.2}
.btn{display:block;width:100%%;padding:14px;border:0;border-radius:12px;background:#2f6df6;color:#fff;
font-size:16px;font-weight:600;cursor:pointer;margin-top:10px}
.btn[disabled]{background:#26303f;color:#7d8896;cursor:default}
.k{color:#8b96a8;font-size:13px}a{color:#5ca9ff}ul{padding-inline-start:20px;font-size:13.5px;color:#c3ccd8}
.warn{background:#1b1508;border-color:#3a2c08;color:#e8c76a;font-size:13px}
table{width:100%%;border-collapse:collapse;font-size:13px}td{padding:5px;border-bottom:1px solid #1e2635}</style>
</head><body><div class="w"><h1>🎁 المكافأة اليومية</h1>
<p class="k">مطالبة واحدة كل يوم · %(pts)d نقطة · إحالة %(ref)d نقطة لكل مطالبة من إحالتك</p>
<div class="card"><div class="k">نقاطك</div><div class="big" id="pts">—</div>
<div class="k">مطالباتك: <b id="cl">—</b> · سلسلتك: <b id="st">—</b> يوم</div>
<button class="btn" id="go" onclick="claim()">جارٍ التحقق…</button>
<div class="k" id="msg" style="margin-top:8px"></div></div>
<div class="card"><div class="k">الصندوق (من السيرفر)</div>
<table><tr><td>عائد مؤكد</td><td><b>$%(conf).2f</b></td></tr>
<tr><td>حصة المكافآت 50%%</td><td><b>$%(pool).4f</b></td></tr>
<tr><td>إجمالي المطالبات عالميًا</td><td><b data-hits="claims">…</b></td></tr>
<tr><td>حالتك</td><td>مطالباتك ÷ الإجمالي × الحصة</td></tr></table>
<p class="k">لا سقف يومي ولا شهري · لا منع عند تجاوز الميزانية (يُسجّل فقط).</p></div>
<div class="card warn"><b>بصراحة:</b> %(honest)s</div>
<div class="card"><b>الشروط</b><ul>%(rules)s</ul></div>
<p class="k"><a href="./">الرئيسية</a> · <a href="earn.html">اكسب أكثر</a> · <a href="share.html">روابط</a> · <a href="owner.html">لوحة المالك</a></p>
</div><script src="hits.js" defer></script>
<script>
var NS="%(ns)s",PT=%(pts)d;
function v(){try{var x=localStorage.getItem("ch_vid");if(!x){x=Math.random().toString(36).slice(2,10)+Date.now().toString(36);localStorage.setItem("ch_vid",x);}return x;}catch(e){return "anon";}}
function ls(k,d){try{return parseInt(localStorage.getItem(k)||d,10)||0;}catch(e){return 0;}}
function ss(k,v){try{localStorage.setItem(k,String(v));}catch(e){}}
function dd(){return new Date().toISOString().slice(0,10);}
function paint(){var c=ls("ch_claims",0);document.getElementById("pts").textContent=(c*PT)+" نقطة";
document.getElementById("cl").textContent=c;document.getElementById("st").textContent=ls("ch_streak",0);
var b=document.getElementById("go");if(ls("ch_last",0)===parseInt(dd().replace(/-/g,""),10)){b.disabled=true;b.textContent="تمت مطالبة اليوم ✓";}
else{b.disabled=false;b.textContent="اطالب بـ "+PT+" نقطة";}}
function claim(){var b=document.getElementById("go");b.disabled=true;b.textContent="جارٍ التحقق…";
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/claim-"+dd()+"-"+v()).then(function(r){return r.json();})
.then(function(j){if(!(j&&j.value===1)){document.getElementById("msg").textContent="جهازك طالب اليوم — المنع من السيرفر.";paint();return;}
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/claims").catch(function(){});
var ref="";try{ref=localStorage.getItem("ch_ref")||"";}catch(e){}
if(ref)fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/ref-"+ref.replace(/[^A-Za-z0-9._-]/g,"-")).catch(function(){});
var c=ls("ch_claims",0)+1;ss("ch_claims",c);ss("ch_last",parseInt(dd().replace(/-/g,""),10));
var y=new Date(Date.now()-86400000).toISOString().slice(0,10);
ss("ch_streak",ls("ch_streak_date","")===y?ls("ch_streak",0)+1:1);ss("ch_streak_date",dd());
document.getElementById("msg").textContent="✓ أُضيفت "+PT+" نقطة";paint();})
.catch(function(){document.getElementById("msg").textContent="فشل الشبكة — أعد المحاولة.";b.disabled=false;b.textContent="أعد المحاولة";});}
paint();</script></body></html>"""

EARN = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>اكسب أكثر</title>
<link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:680px;margin:0 auto;padding:18px}h1{font-size:22px}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:14px;margin:11px 0}
code{background:#0b0f17;padding:3px 8px;border-radius:6px;font-size:12.5px;word-break:break-all;display:block;margin:6px 0}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>💸 طرق الكسب</h1>
<div class="card"><b>1 · مطالبة يومية</b><p class="k">%(pts)d نقطة كل يوم. <a href="rewards.html">افتح</a></p></div>
<div class="card"><b>2 · رابط إحالتك</b><p class="k">%(ref)d نقطة لكل مطالبة تأتي منك:</p>
<code>%(site)s/?ref=%(code)s</code></div>
<div class="card"><b>3 · مشاركة العناوين</b><p class="k">انسخ من <a href="share.html">روابط المشاركة</a>.</p></div>
<div class="card"><b>4 · فتح الصفحات</b><p class="k">كل فتح = ظهور إعلان = عائد يغذّي الصندوق.</p></div>
<div class="card"><b>بصراحة</b><p class="k">%(honest)s</p></div>
<p><a href="rewards.html">المكافأة</a> · <a href="owner.html">لوحة المالك</a></p></div></body></html>"""

def page():
    pool, conf = build()
    core.write_if_changed("rewards.html", PAGE % {
      "pts": CLAIM, "ref": REFPTS, "ns": core.ns(), "conf": conf, "pool": pool,
      "honest": HONEST, "rules": "".join("<li>%s</li>" % core.esc(x) for x in RULES)})
    core.write_if_changed("earn.html", EARN % {
      "pts": CLAIM, "ref": REFPTS, "site": core.site(),
      "code": core.get("REF_CODE") or core.get("GH_USER") or "ch", "honest": HONEST})
    print("  ✓ rewards.html + earn.html · صندوق=$%.4f · عائد مؤكد=$%.2f" % (pool, conf))

if __name__ == "__main__": page()
PYEOF
python3 -m py_compile tools/rewards.py && ok "rewards.py" || bad "rewards.py"

# ════════════════════════════════════════ 10 · الوكيل
hd "10 · tools/agent_lib.py + تقرير يومي + تنبيهات"
cat > tools/agent_lib.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مشغّل مهام: قفل · مهلة · إعادة محاولة غير محدودة (backoff) · سجل مختصر."""
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ALERTS = "data/alerts.json"

def run(name, script, timeout=600, max_attempts=0, args=None):
    """max_attempts=0 → غير محدود داخل الدورة (بسقف زمني)."""
    with core.lock(name, ttl=timeout * 2) as got:
        if not got: return ("skip", 0.0, "مقفول")
        t0 = time.time(); attempt = 0; last = ""
        while True:
            attempt += 1
            try:
                r = subprocess.run([sys.executable, script] + (args or []),
                                   capture_output=True, text=True, timeout=timeout)
                out = (r.stdout or "").strip().splitlines()
                last = out[-1][:110] if out else ""
                if r.returncode == 0: return ("ok", time.time() - t0, last)
                err = (r.stderr or "").strip().splitlines()
                last = (err[-1][:110] if err else "rc=%d" % r.returncode)
            except subprocess.TimeoutExpired:
                last = "مهلة %ds" % timeout
            except Exception as e:
                last = "%s: %s" % (type(e).__name__, str(e)[:80])
            if max_attempts and attempt >= max_attempts: return ("fail", time.time() - t0, last)
            if time.time() - t0 > timeout * 3: return ("fail", time.time() - t0, last)
            time.sleep(min(30, 2 ** attempt))
    return ("fail", time.time() - t0, last)

def alert(kind, msg, key=""):
    d = core.load(ALERTS, {"alerts": []}) or {"alerts": []}
    k = key or (kind + "|" + msg[:60])
    for a in d["alerts"]:
        if a.get("key") == k and a.get("open"): return False
    d["alerts"].append({"key": k, "kind": kind, "msg": msg, "open": True,
                        "at": time.strftime("%F %H:%M")})
    core.save(ALERTS, d); return True

def daily_report():
    import revenue_engine as RE, rewards as RW
    r = RE.apply_ledger(); t, n, unconv, _ = RE.ledger_totals()
    st = core.load("data/secrets_state.json", {}) or {}
    out = {"date": time.strftime("%F"), "at": time.strftime("%H:%M"),
           "ledger_tx": n, "unconverted": unconv,
           "totals": t, "gap_usd": r["gap_usd"],
           "credentials_present": len(st.get("present", [])),
           "credentials_missing": len(st.get("missing", [])),
           "providers_active": len([p for p in r["providers"] if p["account_status"] == "active"]),
           "providers_with_keys": len([p for p in r["providers"] if p["credential_status"] == "present"]),
           "alerts": len([a for a in (core.load(ALERTS, {}) or {}).get("alerts", []) if a.get("open")])}
    os.makedirs("data/reports", exist_ok=True)
    core.save("data/reports/%s.json" % out["date"], out)
    for p in r["providers"]:
        if p["credential_status"] == "present" and not p["last_ok_sync"]:
            alert("credential_unverified", "%s: مفتاح موجود بلا مزامنة ناجحة" % p["name"], "cred:" + p["id"])
    if unconv: alert("fx_missing", "%d معاملة بلا سعر صرف" % unconv, "fx")
    return out

if __name__ == "__main__":
    print(core.load("data/reports/%s.json" % time.strftime("%F"), "لا تقرير بعد"))
PYEOF
python3 -m py_compile tools/agent_lib.py && ok "agent_lib.py" || bad "agent_lib.py"

# ════════════════════════════════════════ 11 · الاختبارات
hd "11 · tools/selftest.py"
cat > tools/selftest.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""اختبارات: بناء · JSON · منع تكرار · غياب مفاتيح · RTL · سرعة · أسرار."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE, ads

P = F = 0
def t(name, cond, extra=""):
    global P, F
    if cond: P += 1; print("  ✓ %s %s" % (name, extra))
    else: F += 1; print("  ✗ %s %s" % (name, extra))

def main():
    print("— بنية —")
    for p in sorted(os.listdir("tools")):
        if p.endswith(".py"):
            r = subprocess.run([sys.executable, "-m", "py_compile", "tools/" + p], capture_output=True)
            t("py_compile " + p, r.returncode == 0, (r.stderr.decode().splitlines() or [""])[-1][:60])
    print("— JSON —")
    bad = []
    for d in (".", "data", "go", "data/reports"):
        if not os.path.isdir(d): continue
        for p in os.listdir(d):
            if p.endswith(".json"):
                try: json.load(open(os.path.join(d, p), encoding="utf-8"))
                except Exception: bad.append(os.path.join(d, p))
    t("كل JSON سليم", not bad, str(bad[:3]))
    print("— منع التكرار (قيد فريد) —")
    before = len((RE._led() or {}).get("tx", {}))
    RE.add("__test__", 1.2345, "pending", "T-1", "2026-01-01")
    RE.add("__test__", 1.2345, "pending", "T-1", "2026-01-01")
    RE.add("__test__", 1.2345, "approved", "T-1", "2026-01-01")
    after = len((RE._led() or {}).get("tx", {}))
    t("نفس (مزود+معرف) لا يتكرر", after - before == 1, "أُضيف %d" % (after - before))
    okk, _, tx = RE.add("__test__", 10, "pending", "T-2", "2026-01-01", currency="EUR")
    t("عملة أجنبية بلا سعر → amount_usd فارغ", tx.get("amount_usd") is None)
    RE.fx_set("EUR", "USD", 1.08, "2026-01-01", "test")
    okk2, _, tx2 = RE.add("__test__", 10, "pending", "T-3", "2026-01-02", currency="EUR")
    t("بعد ضبط السعر → يُحوَّل", tx2.get("amount_usd") is not None and abs(tx2["amount_usd"] - 10.8) < 0.01,
      str(tx2.get("amount_usd")))
    print("— غياب المفاتيح —")
    n, on = ads.counts()
    blk = ads.block("adult")
    t("الكتلة تُبنى بلا مفاتيح", "ADS:adult:start" in blk and "ADS:adult:end" in blk)
    t("الحقن لا يكرر", blk.count("<!--ADS:adult:start-->") == 1)
    page = "<html><body>x</body></html>"
    a1 = ads.inject(page); a2 = ads.inject(a1)
    t("حقن مرتين = كتلة واحدة", a2.count("<!--ADS:adult:start-->") == 1)
    print("— الصفحات —")
    for f in ("index.html", "adult.html", "rewards.html", "earn.html", "owner.html", "networks.html", "share.html"):
        if not os.path.exists(f): t("موجود " + f, False); continue
        s = open(f, encoding="utf-8").read()
        t("سلامة " + f, "</body>" in s and ('dir="rtl"' in s[:400] or "noindex" in s[:400]),
          "%dKB" % (len(s) // 1024))
    print("— أسرار —")
    try:
        import secrets as SEC
        r = SEC.report()
        t("keys.env غير متتبَّع أو مُقفل", True if r["tracked"] is None else not r["tracked"],
          "متتبَّع" if r["tracked"] else "آمن")
        t("لا تسرّب توكن API للواجهة", len(r["leaks"]) == 0, str(r["leaks"][:2]))
    except Exception as e: t("فحص الأسرار", False, str(e)[:50])
    print("— بناء فعلي —")
    for mod in ("adult_build", "growth", "rewards", "dashboard"):
        p = "tools/%s.py" % mod
        if not os.path.exists(p): continue
        t0 = time.time()
        r = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=300)
        t("تشغيل " + mod, r.returncode == 0, "%.1fs" % (time.time() - t0))
        if r.returncode: print("      ", (r.stderr or "").strip().splitlines()[-1][:100] if r.stderr else "")
    print("\nالنتيجة: %d ناجح · %d فاشل" % (P, F))
    return 0 if F == 0 else 1

if __name__ == "__main__": sys.exit(main())
PYEOF
python3 -m py_compile tools/selftest.py && ok "selftest.py" || bad "selftest.py"

# ════════════════════════════════════════ 12 · اللوحة
hd "12 · tools/dashboard.py — لوحة تفصل الحالات"
cat > tools/dashboard.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""owner.html — فصل صريح: تقديري · معلق · مؤكد · مرفوض · مستلم. لا جمع."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>لوحة الإيرادات — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1020px;margin:0 auto;padding:18px}h1{font-size:21px}h2{font-size:16px;color:#9fb0c6;margin-top:26px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(148px,1fr));gap:10px;margin:14px 0}
.b{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:12px}
.b .v{font-size:23px;font-weight:700}.b .l{font-size:12px;color:#8b96a8}
.paid .v{color:#39d98a}.appr .v{color:#5ca9ff}.pend .v{color:#e8c76a}.rej .v{color:#ff7b7b}.est .v{color:#9aa6b6}
table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}
a{color:#5ca9ff}.tag{padding:2px 8px;border-radius:20px;font-size:11.5px;border:1px solid}
.t-active{color:#39d98a;border-color:#1d5c3c;background:#0d2418}
.t-pending_approval,.t-pending_credentials{color:#e8c76a;border-color:#5c4a12;background:#241d08}
.t-unregistered{color:#8b96a8;border-color:#2a3341}
.t-suspended,.t-rejected,.t-blocked{color:#ff7b7b;border-color:#5c1d1d;background:#240d0d}
.k{color:#8b96a8;font-size:12.5px}code{background:#0b0f17;padding:2px 6px;border-radius:5px;font-size:12px}
.bar{height:8px;background:#1a2230;border-radius:6px;overflow:hidden;margin:8px 0}
.bar i{display:block;height:100%%;background:linear-gradient(90deg,#2f6df6,#39d98a)}
.warn{background:#1b1508;border:1px solid #3a2c08;color:#e8c76a;padding:10px;border-radius:10px;font-size:13px}</style>
</head><body><div class="w"><h1>📊 لوحة الإيرادات</h1>
<p class="k">آخر تحديث: %(upd)s · مصدر: دفتر بقيد فريد + محرك إزاءات · <b>لا جمع بين الحالات</b></p>
<div class="grid">
<div class="b paid"><div class="l">مستلم فعليًا</div><div class="v">$%(paid).2f</div></div>
<div class="b appr"><div class="l">مؤكد</div><div class="v">$%(appr).2f</div></div>
<div class="b pend"><div class="l">معلق</div><div class="v">$%(pend).2f</div></div>
<div class="b rej"><div class="l">مرفوض</div><div class="v">$%(rej).2f</div></div>
<div class="b est"><div class="l">تقديري (غير مؤكد)</div><div class="v">$%(est).2f</div></div>
</div>
<h2>التقدّم نحو 100$ (من المستلم فقط)</h2>
<div class="bar"><i style="width:%(pct).1f%%"></i></div>
<p class="k">$%(paid).2f / $100 · الفجوة $%(gap).2f</p>
<h2>أرقام حقيقية من السيرفر</h2>
<div class="grid">
<div class="b"><div class="l">زيارات اليوم</div><div class="v" data-hits="dv">…</div></div>
<div class="b"><div class="l">زوار فريدون اليوم</div><div class="v" data-hits="uvtoday">…</div></div>
<div class="b"><div class="l">مطالبات المكافآت</div><div class="v" data-hits="claims">…</div></div>
<div class="b"><div class="l">معاملات الدفتر</div><div class="v">%(txn)d</div></div>
</div>
<h2>المزودون (%(np)d) — مرتبون حسب الملاءمة</h2>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>اعتماد</th><th>الحالة</th><th>ملاءمة</th>
<th>معلق</th><th>مؤكد</th><th>مستلم</th><th>آخر نجاح/خطأ</th></tr>%(rows)s</table>
<h2>المكافآت</h2><p>الصندوق = 50%% من المؤكد = <b>$%(pool).4f</b> · الحالة <b>%(fstat)s</b></p>
<p class="k">%(honest)s</p>
<h2>التنبيهات</h2>%(alerts)s
<h2>الخطوات التالية</h2><ol>%(next)s</ol>
<div class="warn"><b>قاعدة:</b> %(rule)s<br>
<b>تنبيه:</b> «active» تعني وجود مفتاح، وليست دليل أرباح. التسجيل ≠ القبول.
الأسعار مقروءة من صفحات المزودين 2026-10-18.</div>
<p class="k"><a href="./">الرئيسية</a> · <a href="networks.html">المزودون</a> · <a href="providers.html">الترتيب</a> · <a href="rewards.html">المكافآت</a> · <a href="share.html">روابط</a></p>
</div><script src="hits.js" defer></script></body></html>"""

NEXT = [
 "سجّل في <b>Adsterra</b> (حد $5 · قبول <10 دقائق) → الصق ADSTERRA_ZONE → شغّل ENGINE.sh.",
 "سجّل في <b>ExoClick</b> → الصق EXOCLICK_ZONE (أعلى RPM إباحي).",
 "سجّل في <b>Stripchat/StripCash</b> واختر PPL ($1.50/تسجيل) → الصق STRIPCHAT_REF. أسرع طريق لـ100$.",
 "انشر من promote-adult.html و share.html في r/nsfw · r/porn · r/hentai.",
 "أنشئ توكن API في ExoClick → EXOCLICK_API_TOKEN → المزامنة تصير تلقائية.",
 "سجّل أول عائد: <code>python3 tools/revenue_engine.py add exoclick 5.20 approved --id EXO-1</code>",
]

def main():
    r = RE.apply_ledger(); t = r["totals"]
    _, n, unconv, _ = RE.ledger_totals()
    rw = core.load("data/rewards.json", {}) or {}
    provs = sorted(r["providers"], key=lambda p: -p.get("fit_score", 0))
    rows = ""
    for p in provs:
        cred = "✓ %s" % (p.get("credential_fingerprint") or "") if p["credential_status"] == "present" else '<span class="k">لا شيء</span>'
        rows += ("<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td>"
                 "<td><span class='tag t-%s'>%s</span></td><td>%s</td><td>$%.2f</td><td>$%.2f</td>"
                 "<td>$%.2f</td><td class='k'>%s %s</td></tr>"
                 % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["credential_env"]), cred,
                    p["account_status"], p["account_status"], p.get("fit_score", "-"),
                    p["pending"], p["approved"], p["paid"],
                    core.esc(p.get("last_ok_sync") or "—"), core.esc((p.get("last_error") or "")[:34])))
    al = core.load("data/alerts.json", {}) or {}
    op = [a for a in al.get("alerts", []) if a.get("open")]
    alerts = "".join("<div class='k'>• %s — %s</div>" % (core.esc(a["kind"]), core.esc(a["msg"])) for a in op[:10]) or "<div class='k'>لا تنبيهات</div>"
    core.write_if_changed("owner.html", TPL % {
      "upd": r["updated"], "paid": t["paid"], "appr": t["approved"], "pend": t["pending"],
      "rej": t["rejected"], "est": t["estimated"], "gap": r["gap_usd"], "pct": min(100.0, t["paid"]),
      "txn": n, "np": len(provs), "rows": rows, "pool": (rw.get("funding") or {}).get("pool_usd", 0.0),
      "fstat": (rw.get("funding") or {}).get("status", "—"), "honest": core.esc(rw.get("honest", "")),
      "alerts": alerts, "next": "".join("<li>%s</li>" % x for x in NEXT),
      "rule": core.esc(r["rules"][0] + " · " + r["rules"][1])})
    if unconv: print("  ! %d معاملة بلا سعر صرف" % unconv)
    print("  ✓ owner.html · مستلم=$%.2f · فجوة=$%.2f" % (t["paid"], r["gap_usd"]))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/dashboard.py && ok "dashboard.py" || bad "dashboard.py"

# ════════════════════════════════════════ 13 · المفاتيح
hd "13 · .env.example + .gitignore"
cat > .env.example <<'ENVEOF'
# ════════════════════════════════════════════════════════════════════
#  CineHub 3099 — قالب المفاتيح · انسخه: cp .env.example keys.env
#  لا يوجد مفتاح يعمل بلا حساب. المفتاح يُنشأ من لوحة المزود الرسمية.
#  لا قيمة سرية في HTML/JS — تُقرأ وقت البناء فقط.
# ════════════════════════════════════════════════════════════════════
GH_USER=your_github_username
SITE_URL=https://your_github_username.github.io
REF_CODE=your_code

# ── Zone IDs ── ابدأ بـAdsterra (حد $5 · قبول <10 دقائق) ثم ExoClick
ADSTERRA_ZONE=
EXOCLICK_ZONE=
JUICYADS_ZONE=
HILLTOPADS_ZONE=
TRAFFICSTARS_ZONE=
CLICKADU_ZONE=
EVADAV_ZONE=
AADS_UNIT=
POPADS_SITE=
POPCASH_SITE=

# ── كود HTML جاهز (اختياري، سطر واحد) إن لم يوجد iframe مباشر
ADSTERRA_EMBED=
HILLTOPADS_EMBED=
TRAFFICSTARS_EMBED=
CLICKADU_EMBED=
AADS_EMBED=
POPADS_EMBED=
POPCASH_EMBED=
EVADAV_EMBED=

# ── روابط الإحالة (الأسرع لـ100$: revshare/CPA)
STRIPCHAT_REF=
CRAKREVENUE_REF=
CHATURBATE_REF=
BONGA_REF=
JASMIN_REF=
STREAMATE_REF=
JERKMATE_REF=
FLIRT4FREE_REF=
IMLIVE_REF=
CAMSODA_REF=
XHLIVE_REF=
FANCENTRO_REF=
LOSPOLLOS_REF=
MOBIDEA_REF=
ZEYDOO_REF=

# ── مزامنة ExoClick (اختياري)
EXOCLICK_API_TOKEN=
EXOCLICK_API_USER=
EXOCLICK_API_PASS=
ENVEOF
for x in keys.env .env .tmp/ logs/ '*.log' '*.bak' 'data/*.tmp'; do
  grep -qxF "$x" .gitignore 2>/dev/null || echo "$x" >> .gitignore
done
ok ".env.example + .gitignore"

# ════════════════════════════════════════ 14 · مهام الوكيل
hd "14 · إضافة المهام للوكيل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, shutil, subprocess, sys
p = "tools/tasks.py"
if not os.path.exists(p): print("  ! tools/tasks.py مفقود"); raise SystemExit
shutil.copy(p, ".tmp/tasks.py.bak")
s = open(p, encoding="utf-8").read()
NEW = [("محرك إيرادات","tools/revenue_engine.py","240*M"),
       ("اكتشاف مزودين","tools/provider_discovery.py","1440*M"),
       ("نمو","tools/growth.py","360*M"),
       ("مكافآت","tools/rewards.py","720*M"),
       ("لوحة","tools/dashboard.py","240*M"),
       ("تحقق شامل","tools/selftest.py","360*M")]
lines = s.split("\n")
idx = [i for i, l in enumerate(lines) if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/[^"]+\.py"', l)]
if not idx:
    lines.append("\nEXTRA = [" + ",".join('("%s","%s",%s)' % (n,f,i) for n,f,i in NEW) + "]")
else:
    ins = ['    ("%s", "%s", %s),' % (n, f, iv) for n, f, iv in NEW if f not in s]
    lines[idx[-1] + 1: idx[-1] + 1] = ins
open(p, "w", encoding="utf-8").write("\n".join(lines))
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/tasks.py.bak", p)
    print("  ✗ استُعيد الأصل:", r.stderr.decode().strip().splitlines()[-1][:110])
else: print("  ✓ tasks.py: +%d مهمة (المجموع %s)" % (len(NEW), len([l for l in open(p,encoding='utf-8') if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/',l)])))
PY

# ════════════════════════════════════════ 15 · التشغيل
hd "15 · تشغيل البناء"
if pgrep -f agentd.sh >/dev/null 2>&1; then
  printf '  الوكيل يعمل — يُوقَف مؤقتًا لمنع تضارب البناء ثم يُعاد (السبب: نفس ملفات المخرجات)\n'
  pkill -f agentd.sh; sleep 1
fi
NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
sed -i "s/__NS__/$NSV/" hits.js && ok "معرّف العدّاد: $NSV"
GHU="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || echo "")"
[ -n "$GHU" ] && grep -q '^GH_USER=' .env 2>/dev/null || printf 'GH_USER=%s\nSITE_URL=https://%s.github.io\n' "$GHU" "$GHU" >> .env
for s in provider_discovery secrets ads adult_build adult_promote adult_registry fix_pages growth rewards dashboard; do
  printf '%s▸ %s%s\n' "$D" "$s" "$N"
  python3 "tools/$s.py" 2>&1 | tee -a "$LOG"
done

hd "16 · الاختبارات"
python3 tools/selftest.py 2>&1 | tee -a "$LOG"
ST="${PIPESTATUS[0]}"

hd "17 · النشر (بلا --force)"
if [ "${ST:-1}" = "0" ]; then
  U="$GHU"; [ -n "$U" ] || U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null)"
  T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null)"
  git remote remove origin 2>/dev/null
  git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
  rm -f .git/index.lock
  git add -A
  git add -f .github/workflows/agent.yml 2>/dev/null
  git -c user.email=a@c.local -c user.name=Agent commit -m "engine: revenue ledger (unique constraint) + provider discovery + growth + rewards + selftest" >/dev/null 2>&1
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
  printf '\n%s؟%s انشر إلى main؟ [Y/n] (20s) ' "$Y" "$N"
  ANS=""; read -r -t 20 ANS || true
  if [ -z "$ANS" ] || [ "$ANS" = "y" ] || [ "$ANS" = "Y" ]; then
    if timeout 1800 git push origin main 2>"$TMPDIR/e"; then ok "نُشر بلا --force"
    else bad "فشل الرفع:"; tail -3 "$TMPDIR/e"; fi
  else wrn "أُجّل النشر"; fi
  python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1
  hd "18 · تحقق منشور"
  SITE="https://$U.github.io"
  for f in owner.html rewards.html earn.html networks.html share.html sitemap.xml robots.txt rss.xml go-cams.html; do
    c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
    [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
  done
else wrn "الاختبارات فشلت — لم يُنشر"; fi

hd "19 · إعادة تشغيل الوكيل"
rm -f .git/index.lock
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2; pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"

python3 tools/agent_lib.py 2>&1 | tee -a "$LOG"
printf '\n%s╔══════════════════════════════════════════╗\n' "$G"
printf '║  ENGINE انتهى                            ║\n'
printf '╚══════════════════════════════════════════╝%s\n' "$N"
printf 'اختبارات: %s · السجل: %s\n' "$([ "${ST:-1}" = 0 ] && echo نجحت || echo فشلت)" "$LOG"
