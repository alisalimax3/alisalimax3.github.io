#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تسجيل تلقائي حقيقي: يفتح المتصفح، يعبّي، ينتظر كابتشا، يرسل، يؤكد، يحصد."""
from __future__ import annotations
import json, os, re, select, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, mailbox
from registry import by_id

REGS = core.DATA / "registrations.json"

KEYMAP = [
    (("confirm","retype","repeat","again"), "password"),
    (("email","e-mail","mail"), "email"),
    (("password","passwd","pass"), "password"),
    (("first","given","fname"), "first"),
    (("last","family","surname","lname"), "last"),
    (("username","nick","login","handle"), "username"),
    (("full","displayname","realname","name"), "fullname"),
    (("website","site","domain","url"), "site"),
    (("phone","mobile","tel","whatsapp"), "phone"),
    (("company","organization","org","business"), "company"),
    (("city","town"), "city"),
    (("zip","postal","postcode"), "zip"),
    (("address","street","addr"), "address"),
    (("telegram","skype"), "telegram"),
]

def _vals(p):
    return {"email":p.get("email",""), "password":p.get("password",""),
            "first":p.get("first",""), "last":p.get("last",""),
            "fullname":("%s %s" % (p.get("first",""), p.get("last",""))).strip(),
            "username":p.get("username",""), "site":p.get("site",""),
            "phone":p.get("phone",""), "company":p.get("company",""),
            "city":p.get("city",""), "zip":p.get("zip",""),
            "address":p.get("address",""), "telegram":p.get("telegram","")}

def _match(sig, t):
    if t == "email": return "email"
    if t == "password": return "password"
    if t == "tel": return "phone"
    for words, f in KEYMAP:
        for w in words:
            if w in sig: return f
    return ""

def fill(tab, profile):
    vals = _vals(profile); n = 0
    for f in (tab.ev("window.__ch.scan()") or []):
        if not f.get("vis"): continue
        t = f.get("type","")
        if t in ("hidden","submit","button","file","image","reset","search","checkbox","radio"): continue
        if (f.get("val") or "").strip(): continue
        fld = _match(f.get("sig",""), t)
        if not fld or not vals.get(fld): continue
        try:
            if tab.ev("window.__ch.put(%d, %s)" % (f["i"], json.dumps(str(vals[fld])))): n += 1
        except Exception: continue
    return n

def pick_country(tab, profile):
    want = [profile.get("country_name",""), profile.get("country","")]
    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("tag") != "select": continue
        s = f.get("sig","")
        if not any(k in s for k in ("country","nation","pays")): continue
        for cand in want:
            if not cand: continue
            try:
                r = tab.ev("window.__ch.putSel(%d, %s)" % (f["i"], json.dumps(cand)))
                if r: return r
            except Exception: pass
    return None

def tick(tab):
    n = 0
    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("type") != "checkbox" or not f.get("vis") or f.get("checked"): continue
        s = f.get("sig","")
        if any(k in s for k in ("term","agree","privacy","policy","accept","confirm","18","adult")):
            try:
                if tab.ev("window.__ch.check(%d)" % f["i"]): n += 1
            except Exception: pass
    return n

def wait_captcha(tab, timeout=300):
    end = time.time()+timeout; last = 0
    while time.time() < end:
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if st and st.endswith("-solved"):
            core.log("✓ تم حل الكابتشا — الوكيل يواصل", "ok"); return True
        if sys.stdin.isatty():
            try:
                r,_,_ = select.select([sys.stdin], [], [], 0.1)
                if r: sys.stdin.readline()
            except Exception: pass
        if time.time()-last > 6:
            core.log("⏳ بانتظارك: اضغط 'أنا لست روبوت' في المتصفح...", "warn"); last = time.time()
        time.sleep(0.7)
    core.log("انتهت مهلة الكابتشا — نتابع", "warn"); return False

def harvest(tab, net):
    blob = tab.text(20000)
    try:
        blob += "\n" + (tab.ev("Array.prototype.map.call(document.querySelectorAll('a[href]'),function(a){return a.href;}).join(String.fromCharCode(10))") or "")
    except Exception: pass
    key = ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], blob, re.I)
        if m: key = m.group(1)
    if not key:
        m = re.search(r"(https?://[^\s\"'<>]*" + re.escape(net["id"]) + r"[^\s\"'<>]*)", blob, re.I)
        if m: key = m.group(1)
    return key, blob

def record(net, status, key="", note=""):
    d = core.load(REGS, {})
    d[net["id"]] = {"name": net["name"], "status": status, "key": key, "note": note,
                    "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save(REGS, d)

def success(tab, net):
    try: u = (tab.url() or "").lower()
    except Exception: u = ""
    if u and not any(k in u for k in ("signup","register","sign-up","join","create")):
        return True
    t = tab.text(4000).lower()
    return any(k in t for k in ("verify your email","confirm your email","welcome","dashboard",
                                "check your inbox","account created","successfully"))

def register(net_id, show=False, dry=False):
    net = by_id(net_id)
    profile = core.load("data/profile.json")
    if not profile.get("password"):
        profile["password"] = core.genpass(); core.save("data/profile.json", profile)

    core.log("▶ %s — %s" % (net["name"], net["signup"]), "info")
    if dry:
        print("  حقول ستُعبأ: email/password/first/last/username/site/country")
        print("  تحقق: %s | كابتشا: %s | حد السحب: $%s" % (net["verify"], net["captcha"], net["payout_min"]))
        print("  نطاق التخزين: data/profiles/%s" % net_id)
        return True

    proxy = core.env("BROWSER_PROXY")
    live_x = cdp.x11_alive()
    headless = not (show and live_x)
    if show and not live_x:
        core.log("X غير شغّال — headless. للتفعيل: termux-x11 :0 -ac &", "warn")

    ch = cdp.Chrome(str(core.DATA / "profiles" / net_id), headless=headless, proxy=proxy)
    try:
        tab = ch.tab()
        import registry as _rg
        ok = False
        for url in _rg.candidates(net):
            core.log("محاولة: %s" % url, "info")
            if not tab.go(url, timeout=50):
                core.log("لم يُحمّل — بديل", "warn"); continue
            vis = [f for f in (tab.ev("window.__ch.scan()") or []) if f.get("vis")]
            if len(vis) >= 1:
                ok = True
                core.log("✓ %s | %d حقل مرئي" % ((tab.title() or "?")[:50], len(vis)), "ok")
                break
            core.log("صفحة بلا حقول — بديل", "warn")
        if not ok:
            core.log("كل الروابط فشلت لـ %s" % net["name"], "err")
            tab.dump(net_id + "_fail"); record(net, "nav_failed"); return False
        tab.ev("window.__ch && window.__ch.cookies()")

        for step in range(1, 4):
            f = fill(tab, profile); c = pick_country(tab, profile); b = tick(tab)
            core.log("خطوة %d: حقول=%d بلد=%s موافقات=%d" % (step, f, c or "-", b), "ok")
            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                core.log("كابتشا موجودة قبل الإرسال", "warn"); wait_captcha(tab, 300)
            btn = tab.ev("window.__ch.submitBtn()")
            if not btn: core.log("لا يوجد زر إرسال", "warn"); break
            core.log("إرسال: %s" % btn, "info")
            tab.ev("window.__ch.clickBtn()")
            tab.settle(30); time.sleep(2)
            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                wait_captcha(tab, 300)
                tab.ev("window.__ch.clickBtn()"); tab.settle(25); time.sleep(2)
            if success(tab, net): break

        tab.shot(str(core.LOGS / "shots" / ("%s_%s.png" % (net_id, time.strftime("%H%M%S")))))
        key, blob = harvest(tab, net)

        if net["verify"] == "email" and mailbox.configured():
            core.log("فحص بريد التحقق...", "info")
            if mailbox.confirm(net["id"]):
                record(net, "confirmed", key)
                tab.go(net["signup"]); time.sleep(2)

        if key:
            core.set_env(net["key_env"], key); core.clipset(key)
            core.log("✓ مفتاح %s = %s" % (net["key_env"], key), "ok")
            record(net, "registered", key)
        else:
            core.log("لم يُعثر على المفتاح تلقائياً — عيّنه: ./run.sh key %s <القيمة>" % net_id, "warn")
            record(net, "pending_key")

        core.log("✓ الجلسة محفوظة في data/profiles/%s" % net_id, "ok")
        return bool(key)
    except Exception as e:
        core.log("خطأ: %s" % e, "err"); record(net, "error", note=str(e)); return False
    finally:
        ch.close()

def batch(ids, show=False):
    ok = 0
    for i in ids:
        try:
            if register(i, show=show): ok += 1
        except Exception as e: core.log("%s: %s" % (i, e), "err")
    core.log("النتيجة: %d/%d" % (ok, len(ids)), "ok" if ok else "warn")
