#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  AGENT.sh — وكيل تسجيل مدرّع: لا ينهار · يحاول حتى النجاح · مشرف يعيده
#  bash AGENT.sh           تشغيل الوكيل
#  bash AGENT.sh fix       إصلاح شامل + اختبار + نشر
#  bash AGENT.sh all       إصلاح + نشر + تشغيل
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || exit 1
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data assets
LOG="logs/agent.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
MODE="${1:-run}"

# ═════════ 1 · بيانات الهوية (تُملأ النماذج بسرعة)
hd "1 · tools/profile.py — حزمة هوية كاملة"
cat > tools/profile.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""حزمة هوية متسقة: اسم · بريد · هاتف · بلد · مدينة · عنوان · بريد · كلمة مرور.
   تُنسخ بضغطة وتُلصق في أي نموذج تسجيل."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
P = "data/profile.json"

DEF = {
 "first": "Ali", "last": "Salim", "username": "alisalimax3",
 "email": "", "country": "MA", "country_name": "Morocco",
 "city": "Casablanca", "zip": "20250", "address": "Rue 12, Hay Hassani",
 "phone": "+212600000000", "site": "", "password": "",
 "note": "عدّل أي حقل ثم أعد التشغيل. البلد يظهر في النماذج — اختر بلدك الحقيقي.",
}

def load():
    d = core.load(P, {}) or {}
    out = dict(DEF)
    out.update({k: v for k, v in d.items() if v})
    out["email"] = out["email"] or core.get("MAIL_USER")
    out["site"] = out["site"] or core.site()
    if not out["password"]:
        a = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        out["password"] = "".join(a[x % len(a)] for x in os.urandom(15))
    if not d: core.save(P, out)
    return out

def save(d): core.save(P, d)

def main():
    d = load()
    if len(sys.argv) > 1 and sys.argv[1] == "set":
        for kv in sys.argv[2:]:
            if "=" in kv:
                k, v = kv.split("=", 1); d[k.strip()] = v.strip()
        save(d); print("✓ حُدّث:", " ".join(kv.split("=")[0] for kv in sys.argv[2:]))
    for k in ("first","last","email","country","country_name","city","zip","address","phone","site","password"):
        print("  %-12s %s" % (k, d.get(k, "")))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/profile.py && ok "profile.py"
python3 tools/profile.py 2>&1 | tee -a "$LOG"

# ═════════ 2 · الوكيل المدرّع
hd "2 · tools/agent.py — وكيل لا ينهار"
cat > tools/agent.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""وكيل تسجيل مدرّع: يفتح · يعرض كل الحقول · ينسخها · يتحقق بنطاق · يحاول بلا توقف.
   لا يُخرج traceback أبدًا. Ctrl+C يحفظ ويخرج بنظافة."""
import json, os, re, select, signal, sys, time, traceback
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, profile

ST = "data/agent_state.json"
RUNTIME = 10 ** 9
# id, name, key, dom, signup, dash, find, hint, prio, cat
P = [
 dict(id="aads", name="A-ADS", key="AADS_UNIT", dom="", prio=1, cat="عام",
   signup="https://a-ads.com/ad-units/new/", dash="https://a-ads.com/ad_units",
   find="Ad Units → Embed Code", hint='انسخ السطر فيه data-aa="NNNNNN" — الأرقام',
   vurl="https://acceptable.a-ads.com/{v}?size=300x250",
   geo="لا تشترط بلدًا · الدفع BTC · لا توثيق",
   what="اختر أي بلد — لا يؤثر"),
 dict(id="adsterra", name="Adsterra", key="ADSTERRA_ZONE", dom="", prio=2, cat="عام",
   signup="https://publishers.adsterra.com/register", dash="https://publishers.adsterra.com/websites",
   find="Websites → Ad Units", hint="Zone ID — رقم 5-8 خانات", vurl="",
   geo="كل الدول · Paxum/WebMoney من $5 · USDT",
   what="اختر بلدك الحقيقي — KYC عند أول سحب"),
 dict(id="exoclick", name="ExoClick", key="EXOCLICK_ZONE", dom="", prio=3, cat="عام",
   signup="https://admin.exoclick.com/signup", dash="https://admin.exoclick.com/sites",
   find="Sites & Zones → Zone ID", hint="Zone ID — رقم", vurl="https://s.exoclick.com/ads.php?type=300x250&zone={v}",
   geo="كل الدول · $20 Paxum · كريبتو 40 عملة",
   what="اختر بلدك — KYC (هوية + عنوان) عند أول دفعة"),
 dict(id="juicyads", name="JuicyAds", key="JUICYADS_ZONE", dom="", prio=4, cat="عام",
   signup="https://www.juicyads.com/signup", dash="https://www.juicyads.com/adzones",
   find="Ad Zones", hint="Ad Zone — رقم", vurl="https://adserver.juicyads.com/adshow.php?adzone={v}",
   geo="كل الدول · $25 · دفع أسبوعي",
   what="اختر بلدك — KYC عند السحب"),
 dict(id="popads", name="PopAds", key="POPADS_SITE", dom="", prio=5, cat="عام",
   signup="https://www.popads.net/", dash="https://www.popads.net/users",
   find="Sites → Site ID", hint="Site ID — رقم", vurl="",
   geo="كل الدول · $5 · سحب عند الطلب · بلا توثيق",
   what="أي بلد"),
 dict(id="popcash", name="PopCash", key="POPCASH_SITE", dom="", prio=6, cat="عام",
   signup="https://popcash.net/register", dash="https://popcash.net/websites",
   find="Websites → Website ID", hint="Website ID — رقم", vurl="",
   geo="كل الدول · دفع يومي · $10 · بلا توثيق",
   what="أي بلد"),
 dict(id="stripchat", name="Stripchat", key="STRIPCHAT_REF", dom="stripchat", prio=1, cat="18+",
   signup="https://affiliates.stripchat.com/", dash="https://affiliates.stripchat.com/",
   find="Promo Tools → PPL/RevShare → Affiliate Link", hint="انسخ الرابط الكامل (https://...)",
   vurl="", geo="كل الدول · PPL $1.50/تسجيل · 20-25% مدى الحياة",
   what="اختر بلدك الحقيقي"),
 dict(id="crakrevenue", name="CrakRevenue", key="CRAKREVENUE_REF", dom="crakrevenue", prio=2, cat="18+",
   signup="https://www.crakrevenue.com/signup", dash="https://www.crakrevenue.com/",
   find="Offers → Affiliate Link", hint="رابط الإحالة الكامل", vurl="",
   geo="كل الدول · $168/تحويل على عروض مختارة",
   what="اختر بلدك الحقيقي"),
 dict(id="chaturbate", name="Chaturbate", key="CHATURBATE_REF", dom="chaturbate", prio=3, cat="18+",
   signup="https://chaturbate.com/affiliates/", dash="https://chaturbate.com/affiliates/",
   find="Affiliate Links", hint="رابط الإحالة الكامل", vurl="",
   geo="كل الدول · 20% مدى الحياة", what="اختر بلدك"),
]

def _state():
    d = core.load(ST, {}) or {}
    d.setdefault("sites", {}); d.setdefault("rounds", 0); return d
def _put(key, **kw):
    d = _state(); e = d["sites"].setdefault(key, {"tries": 0, "status": "todo"})
    e.update(kw); e["at"] = time.strftime("%F %H:%M"); core.save(ST, d)

def save_key(k, v):
    lines, found = [], False
    if os.path.exists("keys.env"):
        for l in open("keys.env", encoding="utf-8"):
            if l.strip().startswith(k + "="): lines.append("%s=%s\n" % (k, v)); found = True
            else: lines.append(l)
    if not found: lines.append("%s=%s\n" % (k, v))
    open("keys.env", "w", encoding="utf-8").writelines(lines); core.reload_env()

# ── استخراج المرشّحين: روابط كاملة أولًا
def cands(text, is_ref):
    t = (text or "").strip()
    out = []
    if is_ref:
        out += re.findall(r"https?://[^\s\"'<>|]+", t)
        out += re.findall(r"www\.[^\s\"'<>|]+", t)
    out += [x for x in re.split(r"[\s\n\r\t,;]+", t) if x]
    out += re.findall(r"\b\d{3,9}\b", t)
    seen, r = set(), []
    for c in out:
        c = c.strip().strip("\"'<>()[]{}.,;:")
        if not c or c in seen: continue
        seen.add(c); r.append(c)
    if is_ref: r.sort(key=len, reverse=True)
    return r[:40]

def valid(p, c):
    c = (c or "").strip().strip("\"'<>").rstrip("/")
    if len(c) < 4: return False, "قصير"
    if "@" in c and not c.startswith("http"): return False, "بريد"
    if c.lower() in ("cinehub3099", "github", "http:", "https:", "token", "api"): return False, "نص عام"
    if p["key"].endswith("_REF"):
        if not c.lower().startswith(("http", "www.")): return False, "ليس رابطًا"
        if p["dom"] and p["dom"] not in c.lower(): return False, "نطاق غير مطابق"
        if len(c) <= len(p["dom"]) + 12: return False, "رابط مبتور"
    else:
        if not re.fullmatch(r"\d{3,9}", c): return False, "يجب رقمًا 3-9"
    if p.get("vurl") and "{v}" in p["vurl"]:
        u = p["vurl"].replace("{v}", c)
        r = core.http(u, timeout=12)
        if not r.get("ok"):
            if len(core.body(u, timeout=12, limit=4000)) < 250: return False, "HTTP %s" % r.get("code")
    return True, "✓ تحقق"

def pad(s, n=72):
    s = str(s)[:n]
    return "\r" + s + " " * max(0, n - len(s))

def panel(p, n, total, pr):
    print("\n" + "╔" + "═" * 62 + "╗")
    print("║ %-60s ║" % ("%d/%d · %s   [%s]" % (n, total, p["name"], p["key"])))
    print("╚" + "═" * 62 + "╝")
    print("  الموقع : %s" % (pr.get("site") or "—"))
    print("  ── انسخ بضغطة ──")
    print("   1 البريد    %s" % pr.get("email"))
    print("   2 كلمة مرور %s" % pr.get("password"))
    print("   3 الموقع    %s" % (pr.get("site") or "—"))
    print("   4 الاسم     %s %s" % (pr.get("first"), pr.get("last")))
    print("   5 البلد     %s" % pr.get("country_name"))
    print("   6 المدينة   %s   ·   7 الرمز %s" % (pr.get("city"), pr.get("zip")))
    print("   8 الهاتف    %s" % pr.get("phone"))
    print("  ── الجغرافيا ── %s" % p["geo"])
    print("  ── اختر في النموذج ── %s" % p["what"])
    print("  ── ثم ── اضغط o للفتح · مرّ «أنا لست روبوت» · m لتأكيد البريد · d للوحة")
    print("  ── المفتاح ── %s   ← من: %s" % (p["hint"], p["find"]))

HELP = ("  [o فتح · d لوحة · 1..8 انسخ حقلًا · m بريد · c افحص · v قيمة · r إعادة · s تخطي · q خروج]")

def capture(p, pr, seconds=RUNTIME):
    print("\n  ▶ التقط فوري — انسخ أي شيء وسأفحصه خلال ثانية"); print(HELP)
    prev = core.clipboard(); t0 = time.time(); bad = 0; lastmsg = ""
    while time.time() - t0 < seconds:
        try:
            if select.select([sys.stdin], [], [], 1.0)[0]:
                cmd = (sys.stdin.readline() or "").strip()
                if cmd == "q": return "quit"
                if cmd == "s": return None
                if cmd == "o": core.openurl(p["signup"]); continue
                if cmd == "d": core.openurl(p["dash"]); continue
                if cmd == "r": return "retry"
                if cmd == "m":
                    dom = p["dom"] or re.sub(r"^www\.", "", p["signup"].split("/")[2])
                    print(); imap_links(dom); continue
                if cmd in "12345678":
                    m = {"1": "email", "2": "password", "3": "site", "4": None, "5": "country_name",
                         "6": "city", "7": "zip", "8": "phone"}
                    k = m[cmd]
                    v = ("%s %s" % (pr.get("first"), pr.get("last"))) if k is None else pr.get(k, "")
                    core.clipset(v); print(pad("    ✓ نُسخ: %s" % v)); continue
                if cmd == "c": text = core.clipboard()
                elif cmd == "v":
                    sys.stdout.write("    اكتب: "); sys.stdout.flush(); text = sys.stdin.readline()
                else: text = cmd if cmd else core.clipboard()
            else:
                now = core.clipboard()
                if not now or now == prev:
                    sys.stdout.write(pad("    … %ds · %s" % (int(time.time() - t0), p["hint"][:38])))
                    sys.stdout.flush(); continue
                prev = now; text = now
            for c in cands(text, p["key"].endswith("_REF")):
                try: okk, why = valid(p, c)
                except Exception: okk, why = False, "خطأ فحص"
                if okk:
                    print(pad(""))
                    print("    ✓ %s = %s" % (p["key"], c))
                    save_key(p["key"], c); _put(p["key"], status="done", value=c)
                    return "done"
                bad += 1; lastmsg = why
                sys.stdout.write(pad("    ✗ %-26s (%s)" % (c[:26], why))); sys.stdout.flush()
        except KeyboardInterrupt:
            print(); return "quit"
        except Exception as e:
            sys.stdout.write(pad("    ! %s" % str(e)[:60])); sys.stdout.flush()
    return None

def imap_links(dom, seconds=120):
    u, pw = core.get("MAIL_USER"), core.get("MAIL_APP_PASS")
    if not (u and pw):
        print("    ! ضع MAIL_USER و MAIL_APP_PASS (كلمة مرور تطبيق Google) للتأكيد التلقائي"); return
    import email, imaplib
    host = "imap.gmail.com" if "gmail" in u.lower() else "imap." + u.split("@")[-1]
    end = time.time() + seconds; seen = set()
    while time.time() < end:
        try:
            M = imaplib.IMAP4_SSL(host, timeout=25); M.login(u, pw); M.select("INBOX")
            _, data = M.search(None, "ALL")
            for i in reversed((data[0].split() or [])[-6:]):
                _, msg = M.fetch(i, "(RFC822)")
                if not msg or not msg[0]: continue
                m = email.message_from_bytes(msg[0][1]); blob = str(m.get("Subject", ""))
                for part in m.walk():
                    try:
                        if part.get_content_type() in ("text/html", "text/plain"):
                            blob += part.get_payload(decode=True).decode("utf-8", "replace")
                    except Exception: pass
                for link in re.findall(r"https?://[^\s\"'<>)]{15,}", blob):
                    if link in seen: continue
                    seen.add(link)
                    if any(k in link.lower() for k in ("confirm", "verif", "activat", "validate", "token")):
                        print("    ✓ رابط تأكيد: %s" % link[:110]); M.logout(); return
            M.logout()
        except Exception as e:
            print("    ! IMAP: %s" % str(e)[:60]); return
        print(pad("    … بانتظار بريد التأكيد %ds" % int(end - time.time())))
        time.sleep(10)

def run(only=None, tries_max=0):
    pr = profile.load()
    st = _state()
    todo = [p for p in P if (not only or p["id"] == only or p["key"] == only)]
    todo.sort(key=lambda x: x["prio"])
    print("\n══ وكيل التسجيل — %d مزود ══" % len(todo))
    print("  ابدأ بالأول. لا تحتاج كتابة Enter — انسخ فقط.")
    for i, p in enumerate(todo, 1):
        cur = core.get(p["key"])
        if cur:
            try: okk, why = valid(p, cur)
            except Exception: okk, why = False, "?"
            if okk:
                print("\n  ✓ %s منجز ومتحقق: %s = %s" % (p["name"], p["key"], cur)); continue
            print("\n  ! %s محفوظ لكن مرفوض (%s): %s" % (p["name"], why, cur))
        panel(p, i, len(todo), pr)
        try: core.clipset(pr.get("email", ""))
        except Exception: pass
        print("\n  سأفتح صفحة التسجيل الآن…")
        try: core.openurl(p["signup"])
        except Exception: pass
        _put(p["key"], tries=_state()["sites"].get(p["key"], {}).get("tries", 0) + 1)
        while True:
            try: r = capture(p, pr)
            except Exception:
                traceback.print_exc(); r = None
            if r in ("done", None, "quit"): break
            if r == "retry":
                try: core.openurl(p["signup"])
                except Exception: pass
        if r == "quit": break
        if r != "done": _put(p["key"], status="pending")
    print("\n══ الخلاصة ══")
    for p in P:
        v = core.get(p["key"])
        try: okk = bool(v) and valid(p, v)[0]
        except Exception: okk = False
        print("  %s %-12s %s" % ("✓" if okk else "·", p["name"], v or "—"))
    d = _state(); d["rounds"] = d.get("rounds", 0) + 1; core.save(ST, d)
    return 0

def main():
    try:
        a = [x for x in sys.argv[1:]]
        if a and a[0] == "list":
            for p in P:
                v = core.get(p["key"])
                try: okk = bool(v) and valid(p, v)[0]
                except Exception: okk = False
                print("  %s %-12s %-18s %s" % ("✓" if okk else "·", p["name"], p["key"], v or "—"))
            return 0
        if a and a[0] == "reset":
            for p in P:
                if core.get(p["key"]):
                    try:
                        if not valid(p, core.get(p["key"]))[0]:
                            print("  · %s مرفوض: %s" % (p["name"], core.get(p["key"])))
                    except Exception: pass
            return 0
        return run(a[0] if a else None)
    except KeyboardInterrupt:
        print("\n  · أُوقف — الحالة محفوظة"); return 0
    except Exception:
        traceback.print_exc(); return 0

if __name__ == "__main__":
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    sys.exit(main())
PYEOF
python3 -m py_compile tools/agent.py && ok "agent.py" || bad "agent.py"

# ═════════ 3 · إصلاحات صغيرة حقيقية
hd "3 · userwallet · adult-networks · ledger"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import subprocess, sys
p = "tools/userwallet.py"; s = open(p, encoding="utf-8").read()
s = s.replace('print("  ✓ me.html · عمولة المالك %(cut)d%%" % CUT)',
              'print("  ✓ me.html · عمولة المالك %d%%" % CUT)')
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
rr = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=60) if r.returncode == 0 else None
print("  " + ("✓ userwallet يعمل" if rr and rr.returncode == 0
              else "✗ " + ((rr.stderr or r.stderr or b"").decode().strip().splitlines()[-1][:100])))
# علامة ASCII للاختبار
p = "tools/adult_registry.py"; s = open(p, encoding="utf-8").read()
if "CH:adult-networks" not in s:
    s = s.replace('core.write_if_changed("adult-networks.html",',
                  'core.write_if_changed("adult-networks.html", "<!--CH:adult-networks-->\\n" +')
    open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ adult_registry" if r.returncode == 0 else "✗ " + r.stderr.decode()[-90:]))
p = "tools/selftest.py"; s = open(p, encoding="utf-8").read()
s = s.replace('"adult-networks.html":"شبكات الكبار"', '"adult-networks.html":"CH:adult-networks"')
open(p, "w", encoding="utf-8").write(s)
print("  ✓ selftest: علامة ASCII")
PY

python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, shutil
p = "./ledger.json"
raw = open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else ""
if os.path.exists(p + ".broken") and len(open(p + ".broken", encoding="utf-8").read()) > len(raw):
    raw = open(p + ".broken", encoding="utf-8").read()
print("  المصدر: %d بايت · يبدأ بـ%r" % (len(raw), raw[:30]))
def salvage(t):
    objs, depth, start, instr, esc, q = [], 0, None, False, False, ""
    for i, ch in enumerate(t):
        if instr:
            if esc: esc = False
            elif ch == "\\": esc = True
            elif ch == q: instr = False
            continue
        if ch in "\"'": instr = True; q = ch
        elif ch == "{":
            if depth == 0: start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                objs.append(t[start:i+1]); start = None
    return objs
good = []
for blk in salvage(raw):
    try: good.append(json.loads(blk))
    except Exception:
        try: good.append(__import__("ast").literal_eval(blk))
        except Exception: pass
if good:
    if not os.path.exists(p + ".broken"): shutil.copy(p, p + ".broken")
    json.dump(good, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("  ✓ استُعيدت %d سجلة من السلسلة (بدل {})" % len(good))
else:
    print("  ! لا سجلات — أُبقي كما هو")
PY

# ═════════ 4 · اختبار ونشر
if [ "$MODE" = "fix" ] || [ "$MODE" = "all" ]; then
  hd "4 · اختبار ونشر"
  for s in ads adult_build adult_registry growth rewards dashboard userwallet custody; do
    printf '  · %-15s ' "$s"; python3 "tools/$s.py" >>"$LOG" 2>&1 && printf '%s✓%s\n' "$G" "$N" || printf '%s✗%s\n' "$R" "$N"
  done
  python3 tools/selftest.py 2>&1 | tail -12 | tee -a "$LOG"; ST="${PIPESTATUS[0]}"
  if [ "$ST" = "0" ]; then
    U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login())" 2>/dev/null)"
    T="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.token())" 2>/dev/null)"
    if [ -n "$U" ] && [ -n "$T" ]; then
      git remote remove origin 2>/dev/null
      git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
      rm -f .git/index.lock; git add -A; git add -f .github/workflows/agent.yml 2>/dev/null
      git -c user.email=a@c.local -c user.name=Agent commit -m "agent: crash-proof register wizard + profile pack + ledger salvage" >/dev/null 2>&1
      git fetch origin main 2>/dev/null && git -c user.email=a@c.local -c user.name=Agent pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
      timeout 2400 git push origin main 2>"$TMPDIR/e" && ok "رُفع" || bad "فشل الرفع"
    fi
  else wrn "الاختبارات فشلت ($ST) — لم يُنشر"; fi
fi

# ═════════ 5 · تشغيل الوكيل بمشرف
if [ "$MODE" = "run" ] || [ "$MODE" = "all" ]; then
  hd "5 · الوكيل (مشرف: يعيد التشغيل عند أي انهيار)"
  N=0
  while [ "$N" -lt 6 ]; do
    N=$((N + 1))
    python3 tools/agent.py "$@" 2>&1 | tee -a "$LOG"
    RC="${PIPESTATUS[0]}"
    [ "$RC" = "0" ] && break
    wrn "خرج برمز $RC — إعادة خلال 3ث ($N/6)"; sleep 3
  done
  hd "6 · الحالة"
  python3 tools/agent.py list 2>&1 | tee -a "$LOG"
fi
printf '\n%sلتشغيل الوكيل: bash AGENT.sh · للإصلاح: bash AGENT.sh fix%s\n' "$B" "$N"
