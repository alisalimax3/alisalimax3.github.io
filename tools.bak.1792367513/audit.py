#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل حقيقي — بلا منطق and/or الخاطئ"""
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, mailbox, cdp

OK, BAD, WARN = [], [], []
def h(t): print("\n%s%s══ %s ══%s" % (core.C['b'], core.C['info'], t, core.C['x']))
def good(m): OK.append(m); core.log(m, "ok")
def bad(m):  BAD.append(m); core.log(m, "err")
def warn(m): WARN.append(m); core.log(m, "warn")
def check(cond, okmsg, badmsg):
    if cond: good(okmsg)
    else: bad(badmsg)

def main():
    print("%s%s\n╔══════════════════════════════════════════════════════════╗"
          "\n║        🔬 CineHub — فحص شامل حقيقي v7                    ║"
          "\n╚══════════════════════════════════════════════════════════╝%s" % (core.C['b'], core.C['info'], core.C['x']))

    h("1. بنية المشروع")
    for d in ("tools","data","logs","assets","content"):
        check((core.BASE/d).is_dir(), "مجلد: %s" % d, "مفقود: %s" % d)
    for f in ("core.py","cdp.py","inject.js","registry.py","autoreg.py","agent.py",
              "ledger.py","payout.py","mailbox.py","doctor.py","audit.py"):
        p = core.BASE/"tools"/f
        if not p.exists(): bad("مفقود: tools/%s" % f); continue
        if f.endswith(".py"):
            r = subprocess.run([sys.executable,"-m","py_compile",str(p)], capture_output=True)
            check(not r.returncode, "سليم: tools/%s" % f, "مكسور: tools/%s" % f)
        else: good("موجود: tools/%s" % f)

    h("2. الاعتماديات")
    for mod, pkg in {"websocket":"websocket-client","requests":"requests","bs4":"beautifulsoup4","lxml":"lxml"}.items():
        check(importlib.util.find_spec(mod) is not None, "%s مثبّت" % pkg, "%s مفقود → pip install %s" % (pkg, pkg))

    h("3. المتصفح")
    exe = cdp.find_chromium()
    if not exe: bad("chromium غير مثبت → pkg install chromium")
    else: good("chromium: %s" % cdp.version())

    h("4. الشاشة")
    if cdp.x11_alive(): good("خادم X يعمل — الوضع المرئي متاح")
    elif cdp.x11():
        warn("DISPLAY=%s مضبوط لكن X لا يعمل" % core.env("DISPLAY"))
        print("    شغّل: termux-x11 :0 -ac &")
        print("    ثم:   am start --user 0 -n com.termux.x11/.MainActivity")
    else: warn("DISPLAY غير مضبوط — headless فقط (يعمل بلا مشاكل)")

    h("5. الهوية")
    pr = core.load("data/profile.json")
    for k in ("first","last","username","email","country","site"):
        check(bool(pr.get(k)), "%s = %s" % (k, pr.get(k,"")), "ناقص: %s" % k)
    check(bool(pr.get("password")), "كلمة المرور جاهزة", "لا كلمة مرور")

    h("6. المفاتيح")
    kv = {}
    if core.ENV_FILE.exists():
        for line in core.ENV_FILE.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k,v = line.split("=",1); kv[k.strip()] = v.strip()
    junk = [k for k,v in kv.items() if v in ("install_requirements","python3","pip")]
    check(not junk, "keys.env نظيف", "قيم مسرّبة: %s" % ", ".join(junk))
    mp = kv.get("MAIL_APP_PASS","")
    check(len(mp.replace(" ","")) == 16, "MAIL_APP_PASS بطول صحيح (16)", "MAIL_APP_PASS طوله %d — الصحيح 16 حرفاً" % len(mp.replace(" ","")))
    check(bool(kv.get("CAPTCHA_KEY")), "CAPTCHA_KEY موجود", "CAPTCHA_KEY فارغ (اختياري لكن يفيد)")
    good("مصادر بمفاتيح: %d/%d" % (len(registry.with_key()), len(registry.ALL)))

    h("7. البريد التلقائي")
    okm, msg = mailbox.test()
    if okm: good(msg)
    else:
        bad(msg)
        print("    → https://myaccount.google.com/apppasswords")
        print("    → ./run.sh setenv MAIL_APP_PASS <16 حرفاً بلا مسافات>")

    h("8. الروابط الأساسية")
    for url in ("https://monetag.com","https://publishers.adsterra.com/signup",
                "https://www.popads.net/users/register","https://freecash.com"):
        r = core.http(url, timeout=15, headers={"User-Agent": core.UA, "Accept":"text/html"})
        code = r.get("code") or 0
        check(r.get("ok") and code < 400, "%s → %s" % (url.split("//")[1][:34], code),
              "%s → %s" % (url.split("//")[1][:34], r.get("err") or code))

    h("9. اختبار متصفح حقيقي")
    try:
        ch = cdp.Chrome(str(core.DATA/"profiles"/"_audit"), headless=True, timeout=45)
        try:
            t = ch.tab()
            check(t.go("https://example.com", timeout=35),
                  "تصفح ناجح — %s" % (t.title() or "?"), "فشل التصفح")
            check(t.ev("typeof window.__ch!=='undefined'") is True, "المحقون __ch نشط", "المحقون __ch غائب")
        finally: ch.close()
    except Exception as e: bad("تعذّر التشغيل: %s" % e)

    h("10. الأرباح")
    b = ledger.balances()
    good("قيود: %d | الإجمالي: $%.2f" % (len(ledger._d()["entries"]), ledger.total()))
    for s,v in sorted(b.items(), key=lambda x:-x[1])[:10]: print("    %-16s $%.2f" % (s, v))

    h("الخلاصة")
    core.log("ناجح: %d | تحذير: %d | عطل: %d" % (len(OK), len(WARN), len(BAD)),
             "err" if BAD else ("warn" if WARN else "ok"))
    if BAD:
        print("\n%sيجب إصلاح:%s" % (core.C['err'], core.C['x']))
        for i,m in enumerate(BAD,1): print("  %d. %s" % (i,m))
    if WARN:
        print("\n%sاختياري:%s" % (core.C['warn'], core.C['x']))
        for i,m in enumerate(WARN,1): print("  %d. %s" % (i,m))
    if not BAD and not WARN: print("\n%sالنظام كامل وجاهز.%s" % (core.C['ok'], core.C['x']))
    return 0 if not BAD else 2

if __name__ == "__main__": sys.exit(main())
