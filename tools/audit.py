#!/usr/bin/env python3
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, mailbox, cdp
OK=[];BAD=[];WARN=[]
def h(t): print("\n%s%s══ %s ══%s" % (core.C['b'],core.C['info'],t,core.C['x']))
def g(m): OK.append(m); core.log(m,"ok")
def b(m): BAD.append(m); core.log(m,"err")
def w(m): WARN.append(m); core.log(m,"warn")
def ck(c,a,z): g(a) if c else b(z)
def main():
    print("\n╔══════════════════════════════════════════════╗\n║   🔬 CineHub — فحص شامل                       ║\n╚══════════════════════════════════════════════╝")
    h("1. الملفات")
    for f in ("core.py","cdp.py","inject.js","registry.py","autoreg.py","agent.py","ledger.py",
              "payout.py","mailbox.py","captcha.py","repo.py","addkey.py","watch.py","autoflow.py","verify_keys.py","audit.py","selftest.py"):
        p = core.BASE/"tools"/f
        if not p.exists(): b("مفقود: %s" % f); continue
        if f.endswith(".py"):
            r = subprocess.run([sys.executable,"-m","py_compile",str(p)],capture_output=True)
            ck(not r.returncode, "سليم: %s" % f, "مكسور: %s" % f)
        else: g("موجود: %s" % f)
    h("2. الاعتماديات")
    for m,p in {"websocket":"websocket-client","requests":"requests","bs4":"beautifulsoup4"}.items():
        ck(importlib.util.find_spec(m) is not None, "%s مثبّت" % p, "%s مفقود" % p)
    h("3. المتصفح")
    e = core.find_chromium()
    ck(bool(e), "chromium: %s" % core.chromium_version(), "chromium مفقود")
    h("4. الشاشة")
    if core.x11_alive(): g("X يعمل — وضع مرئي متاح")
    elif core.env("DISPLAY"): w("DISPLAY مضبوط لكن X ميت — headless")
    else: w("headless (طبيعي ويعمل)")
    h("5. السجل")
    s = registry.stats()
    g("مصادر: %d | بمفاتيح: %d | ناقص: %d" % (s["total"],s["with_key"],s["pending"]))
    h("6. الهوية والمفاتيح")
    pr = core.load("data/profile.json")
    for k in ("first","last","username","email","country","site"): ck(bool(pr.get(k)), "%s=%s"%(k,pr.get(k,"")), "ناقص: %s"%k)
    mp = (core.env("MAIL_APP_PASS") or "")
    ck(len(mp)==16, "MAIL_APP_PASS صحيح (16)", "MAIL_APP_PASS طوله %d (الصحيح 16)" % len(mp))
    h("7. البريد")
    okm,msg = mailbox.test(); ck(okm, msg, msg)
    h("8. المستودع")
    import repo
    g("remote: %s" % (repo.remote() or "غير مضبوط"))
    h("9. اختبار متصفح + تعبئة حقيقية")
    import selftest
    ok = selftest.browser_and_form()
    ck(ok, "المتصفح + التعبئة يعملان", "فشل اختبار المتصفح")
    h("الخلاصة")
    core.log("ناجح %d | تحذير %d | عطل %d" % (len(OK),len(WARN),len(BAD)), "err" if BAD else ("warn" if WARN else "ok"))
    if BAD:
        print("\nيجب إصلاح:"); [print("  %d. %s"%(i,m)) for i,m in enumerate(BAD,1)]
    if WARN:
        print("\nاختياري:"); [print("  %d. %s"%(i,m)) for i,m in enumerate(WARN,1)]
    return 0 if not BAD else 2
if __name__=="__main__": sys.exit(main())
