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
    import os as _o
    a = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(a[x % len(a)] for x in _o.urandom(n))

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
