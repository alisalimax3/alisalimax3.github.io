#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""وكيل تسجيل قائد: يفتح · يعرض الحقول · يوجّه · يتحقق · يخزّن · يعيد."""
import base64, email, imaplib, json, os, re, select, secrets, string, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

STATE = "data/wizard_state.json"

# id, name, key, signup, dashboard, find, hint, validate, expect, region, kyc, prio
P = [
 dict(id="aads", name="A-ADS", key="AADS_UNIT", prio=1,
   signup="https://a-ads.com/ad-units/new/", dashboard="https://a-ads.com/ad_units",
   find="قائمة Ad Units → انسخ الكود الظاهر في Embed Code",
   hint='انسخ السطر الذي فيه data-aa="NNNNNN" — الأرقام فقط',
   validate="https://acceptable.a-ads.com/{v}?size=300x250", expect="a-ads",
   region="لا تشترط بلدًا · الدفع BTC تلقائي · لا حد ترافيك",
   kyc="لا توثيق هوية للتسجيل · الدفع لعنوان BTC"),
 dict(id="adsterra", name="Adsterra", key="ADSTERRA_ZONE", prio=2,
   signup="https://publishers.adsterra.com/register", dashboard="https://publishers.adsterra.com/websites",
   find="Websites → أضف موقعك → Ad Units → انسخ Zone ID",
   hint="Zone ID — رقم فقط (5-8 خانات)",
   validate="https://adsterra.com/", expect="",
   region="تقبل كل الدول · الدفع Paxum/WebMoney من $5 · USDT",
   kyc="لا توثيق للتسجيل · قد يُطلب عند أول سحب كبير"),
 dict(id="exoclick", name="ExoClick", key="EXOCLICK_ZONE", prio=3,
   signup="https://admin.exoclick.com/signup", dashboard="https://admin.exoclick.com/sites",
   find="Sites & Zones → أنشئ Zone → انسخ Zone ID",
   hint="Zone ID — رقم فقط",
   validate="https://s.exoclick.com/ads.php?type=300x250&zone={v}", expect="",
   region="تقبل كل الدول · الحد $20 Paxum · كريبتو $50",
   kyc="توثيق الهوية عند أول دفعة — جواز أو هوية + إثبات عنوان"),
 dict(id="juicyads", name="JuicyAds", key="JUICYADS_ZONE", prio=4,
   signup="https://www.juicyads.com/signup", dashboard="https://www.juicyads.com/adzones",
   find="Ad Zones → أنشئ Zone → انسخ الرقم",
   hint="Ad Zone — رقم فقط",
   validate="https://adserver.juicyads.com/adshow.php?adzone={v}", expect="",
   region="تقبل كل الدول · الحد $25 · دفع أسبوعي الجمعة",
   kyc="توثيق عند السحب"),
 dict(id="popads", name="PopAds", key="POPADS_SITE", prio=5,
   signup="https://www.popads.net/", dashboard="https://www.popads.net/users",
   find="Sites → أضف موقعك → انسخ Site ID",
   hint="Site ID — رقم",
   validate="https://www.popads.net/", expect="",
   region="تقبل كل الدول · الحد $5 · سحب عند الطلب",
   kyc="لا توثيق للتسجيل"),
 dict(id="popcash", name="PopCash", key="POPCASH_SITE", prio=6,
   signup="https://popcash.net/register", dashboard="https://popcash.net/websites",
   find="Websites → أضف موقعك → انسخ Website ID",
   hint="Website ID — رقم",
   validate="https://popcash.net/", expect="",
   region="تقبل كل الدول · دفع يومي · الحد $10",
   kyc="لا توثيق للتسجيل"),
 dict(id="stripchat", name="Stripchat (StripCash)", key="STRIPCHAT_REF", prio=1,
   signup="https://affiliates.stripchat.com/", dashboard="https://affiliates.stripchat.com/",
   find="Promo Tools → اختر نموذج PPL أو RevShare → انسخ رابط الإحالة كاملًا",
   hint="انسخ الرابط الكامل الذي يبدأ بـ https://",
   validate="", expect="",
   region="تقبل كل الدول · MENA يتحوّل جيدًا · PPL $1.50 لكل تسجيل مجاني",
   kyc="لا توثيق للتسجيل · التوثيق عند أول سحب"),
 dict(id="crakrevenue", name="CrakRevenue", key="CRAKREVENUE_REF", prio=2,
   signup="https://www.crakrevenue.com/signup", dashboard="https://www.crakrevenue.com/",
   find="Offers → اختر عرضًا → Affiliate Link → انسخ",
   hint="رابط الإحالة الكامل",
   validate="", expect="",
   region="تقبل كل الدول · الحد $50 · $168/تحويل على عروض مختارة",
   kyc="توثيق عند أول سحب"),
]

RE_NUM = re.compile(r"^\d{3,9}$")

def st():
    d = core.load(STATE, {"done": [], "tries": {}, "notes": {}})
    d.setdefault("done", []); d.setdefault("tries", {}); d.setdefault("notes", {})
    return d
def put(key, val):
    d = st(); d["done"] = sorted(set(d["done"] + [key])); core.save(STATE, d)
def bump(key):
    d = st(); d["tries"][key] = d["tries"].get(key, 0) + 1; core.save(STATE, d)

def save_key(k, v):
    lines, found = [], False
    if os.path.exists("keys.env"):
        for l in open("keys.env", encoding="utf-8"):
            if l.strip().startswith(k + "="): lines.append("%s=%s\n" % (k, v)); found = True
            else: lines.append(l)
    if not found: lines.append("%s=%s\n" % (k, v))
    open("keys.env", "w", encoding="utf-8").writelines(lines)
    core.reload_env()

def gen_pass(n=15):
    return "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(n))

def cands(text):
    out = []
    for t in re.findall(r"[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]{6,}", text or ""):
        out.append(t)
    for t in re.findall(r"\d{3,9}", text or ""):
        out.append(t)
    seen, r = set(), []
    for t in out:
        t = t.strip().strip('"\'<>')
        if t and t not in seen: seen.add(t); r.append(t)
    return r

def looks_like_ref(t):
    return t.startswith("http") and ("." in t)

def valid(p, t):
    t = (t or "").strip().strip('"\'<>').rstrip("/")
    if not t or len(t) < 3: return False, "قصير"
    if "@" in t: return False, "بريد"
    if t.lower() in ("cinehub3099", "github", "http:", "https:", "token", "api"): return False, "نص عام"
    if p["key"].endswith("_REF"):
        if not looks_like_ref(t): return False, "يجب أن يبدأ بـ http"
    else:
        if not RE_NUM.match(t): return False, "يجب أن يكون رقمًا 3-9 خانات"
    u = p["validate"].replace("{v}", t)
    if "{v}" in p["validate"] and p["validate"]:
        r = core.http(u, timeout=12)
        if not r.get("ok"):
            b = core.body(u, timeout=12, limit=5000)
            if len(b) < 250: return False, "HTTP %s" % r.get("code")
    return True, "✓ تحقق شبكي"

def panel(p, n, total, pw):
    mu = core.get("MAIL_USER") or "— (اضبط MAIL_USER في keys.env)"
    site = core.site()
    print("\n" + "╔" + "═" * 62 + "╗")
    print("║ %-60s ║" % ("%d/%d · %s  [%s]" % (n, total, p["name"], p["key"])))
    print("╚" + "═" * 62 + "╝")
    print("  البلد  : %s" % p["region"])
    print("  التوثيق: %s" % p["kyc"])
    print("  ── الحقول التي ستكتبها ──")
    print("   البريد   : %s" % mu)
    print("   كلمة المرور: %s" % pw)
    print("   الموقع    : %s" % (site or "—"))
    print("   الفئة    : %s" % ("محتوى 18+" if p["id"] not in ("aads","adsterra","popads","popcash") else "عام / مختلط"))
    print("  ── ما تفعله ──")
    print("   1) اضغط o لفتح صفحة التسجيل")
    print("   2) املأ الحقول (1=انسخ البريد · 2=انسخ كلمة المرور · 3=انسخ الموقع)")
    print("   3) اضغط «أنا لست روبوت» واجتز الصورة")
    print("   4) أكّد البريد (m) — أو انتظر وصوله")
    print("   5) اضغط d لفتح اللوحة، انسخ المفتاح: %s" % p["hint"])
    print("   6) انسخ — سألتقطه وأتحقق منه فورًا")

def keys_help():
    print("  [o فتح التسجيل · d اللوحة · 1 بريد · 2 كلمة مرور · 3 الموقع · c افحص الحافظة")
    print("   v تحقق من قيمة كتبتها · m افحص البريد · n التالي · b السابق · s تخطي · q خروج]")

def imap_links(domain, limit=6, seconds=90):
    u = core.get("MAIL_USER"); pw = core.get("MAIL_APP_PASS")
    if not (u and pw):
        print("    ! ضبط البريد للتأكيد التلقائي: MAIL_USER و MAIL_APP_PASS (كلمة مرور تطبيق Google)")
        return []
    host = "imap.gmail.com" if "gmail" in u.lower() else "imap." + u.split("@")[-1]
    end = time.time() + seconds
    seen = set()
    while time.time() < end:
        try:
            M = imaplib.IMAP4_SSL(host, timeout=25)
            M.login(u, pw); M.select("INBOX")
            typ, data = M.search(None, "ALL")
            ids = data[0].split()[-limit:]
            for i in reversed(ids):
                typ, msg = M.fetch(i, "(RFC822)")
                if typ != "OK" or not msg or not msg[0]: continue
                raw = msg[0][1]
                m = email.message_from_bytes(raw)
                subj = str(m.get("Subject", ""))
                body = ""
                if m.is_multipart():
                    for part in m.walk():
                        if part.get_content_type() == "text/html":
                            try: body = part.get_payload(decode=True).decode("utf-8", "replace")
                            except Exception: pass
                            if body: break
                    if not body:
                        for part in m.walk():
                            if part.get_content_type() == "text/plain":
                                try: body = part.get_payload(decode=True).decode("utf-8", "replace")
                                except Exception: pass
                                if body: break
                else:
                    try: body = m.get_payload(decode=True).decode("utf-8", "replace")
                    except Exception: body = str(m.get_payload())
                blob = subj + " " + body
                if domain and domain.lower() not in blob.lower() and "confirm" not in blob.lower() \
                   and "verif" not in blob.lower(): continue
                for link in re.findall(r"https?://[^\s\"'<>)]{15,}", blob):
                    if link in seen: continue
                    seen.add(link)
                    if any(k in link.lower() for k in ("confirm","verif","activat","token","auth","validate")):
                        print("    ✓ رابط تأكيد: %s" % link[:110])
                        return [link]
            M.logout()
        except Exception as e:
            print("    ! IMAP: %s" % str(e)[:60]); return []
        print("    … بانتظار بريد التأكيد %ds" % int(end - time.time()))
        time.sleep(12)
    return []

def capture(p, seconds=900):
    print("\n  ▶ جاهز لالتقاط المفتاح — انسخ من الصفحة، سألتقطه فورًا")
    keys_help()
    prev = core.clipboard(); t0 = time.time(); bad = 0
    while time.time() - t0 < seconds:
        if select.select([sys.stdin], [], [], 1.0)[0]:
            cmd = sys.stdin.readline().strip()
            if cmd == "q": return None
            if cmd == "s": return None
            if cmd == "o": core.openurl(p["signup"]); continue
            if cmd == "d": core.openurl(p["dashboard"]); continue
            if cmd == "1": core.clipset(core.get("MAIL_USER")); print("    ✓ البريد في الحافظة"); continue
            if cmd == "2": core.clipset(LASTPW); print("    ✓ كلمة المرور في الحافظة"); continue
            if cmd == "3": core.clipset(core.site()); print("    ✓ الموقع في الحافظة"); continue
            if cmd == "m":
                dom = re.sub(r"^www\.", "", p["signup"].split("/")[2])
                imap_links(dom, seconds=90); continue
            if cmd == "c": text = core.clipboard()
            elif cmd == "v":
                sys.stdout.write("    اكتب القيمة: "); sys.stdout.flush()
                text = sys.stdin.readline().strip()
            else:
                text = cmd if cmd else core.clipboard()
        else:
            now = core.clipboard()
            if not now or now == prev:
                sys.stdout.write("\r    … %ds · %s" % (int(time.time() - t0), p["hint"][:40]))
                sys.stdout.flush(); continue
            prev = now; text = now
        for c in cands(text):
            okk, why = valid(p, c)
            if okk:
                print("\r    ✓ %s = %s" % (p["key"], c))
                save_key(p["key"], c); put(p["key"])
                return c
            bad += 1
            sys.stdout.write("\r    ✗ %-26s (%s)" % (c[:26], why)); sys.stdout.flush()
    print("\n    ! انتهى الوقت — سيُعاد في المرة القادمة")
    return None

def one(p, n, total):
    cur = core.get(p["key"])
    if cur:
        okk, why = valid(p, cur)
        if okk:
            print("\n%s ✓ منجز ومتحقق: %s = %s" % (p["name"], p["key"], cur)); return "done"
        print("\n%s ! محفوظ لكن مرفوض (%s): %s" % (p["name"], why, cur))
    global LASTPW
    LASTPW = gen_pass()
    panel(p, n, total, LASTPW)
    core.clipset(core.get("MAIL_USER") or "")
    print("\n  سأفتح صفحة التسجيل الآن…")
    core.openurl(p["signup"])
    bump(p["key"])
    r = capture(p)
    return "done" if r else "pending"

LASTPW = ""

def main():
    a = sys.argv[1:]
    if a and a[0] == "list":
        for p in P:
            v = core.get(p["key"])
            okk = valid(p, v)[0] if v else False
            print("  %-11s %-18s %s" % (p["name"], p["key"], (("✓ " + v) if okk else (("! " + v) if v else "—"))))
        return
    only = a[0] if a else ""
    todo = [p for p in P if (not only or p["id"] == only or p["key"] == only)]
    todo.sort(key=lambda x: x["prio"])
    print("\n══ وكيل التسجيل — %d مزود ══" % len(todo))
    print("  الترتيب بالأولوية. الأسرع نفعًا: A-ADS (لا توثيق) ثم Adsterra ($5).")
    for i, p in enumerate(todo, 1):
        try:
            r = one(p, i, len(todo))
        except (KeyboardInterrupt, EOFError):
            print("\n  · أُوقف — الحالة محفوظة"); break
        print("  → %s" % ("تم" if r == "done" else "بانتظار"))
    print("\n══ الخلاصة ══")
    for p in P:
        v = core.get(p["key"])
        okk = valid(p, v)[0] if v else False
        print("  %s %-11s %s" % ("✓" if okk else "·", p["name"], v or "—"))
    print("\n  التالي: bash REGISTER.sh  (لإعادة المحاولة على المتبقي)")

if __name__ == "__main__": main()
